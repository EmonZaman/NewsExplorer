//
//  ImageCache.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import UIKit
import RxSwift

// MARK: - Image Cache Protocol

protocol ImageCacheProtocol {
    func getImage(for url: URL) -> UIImage?
    func setImage(_ image: UIImage, for url: URL)
    func removeImage(for url: URL)
    func clearCache()
}

// MARK: - Image Cache Implementation

final class ImageCache: ImageCacheProtocol {
    
    // MARK: - Singleton
    
    static let shared = ImageCache()
    
    // MARK: - Properties
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    private let ioQueue = DispatchQueue(label: "com.newsexplorer.imagecache.io", qos: .utility)
    
    // Cache configuration
    private let maxMemoryCost: Int = 100 * 1024 * 1024 // 100 MB
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200 MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Initialization
    
    private init() {
        // Setup memory cache
        memoryCache.totalCostLimit = maxMemoryCost
        
        // Setup disk cache directory
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        createDiskCacheDirectoryIfNeeded()
        
        // Clean up old cache files on initialization
        ioQueue.async { [weak self] in
            self?.cleanExpiredDiskCache()
        }
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - ImageCacheProtocol
    
    func getImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        
        // Only check memory cache (fast) - disk cache is checked async
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        return nil
    }
    
    func getImageAsync(for url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = cacheKey(for: url)
        
        // Check memory cache first (fast)
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache asynchronously
        ioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if let diskImage = self.loadImageFromDisk(for: key) {
                // Store in memory cache for faster access next time
                let cost = diskImage.jpegData(compressionQuality: 0.8)?.count ?? 0
                self.memoryCache.setObject(diskImage, forKey: key as NSString, cost: cost)
                DispatchQueue.main.async { completion(diskImage) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        
        // Downscale large images to reduce memory usage
        let maxSize: CGFloat = 400
        let scaledImage: UIImage
        if image.size.width > maxSize || image.size.height > maxSize {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            scaledImage = image
        }
        
        let cost = scaledImage.jpegData(compressionQuality: 0.7)?.count ?? 0
        
        // Store in memory cache
        memoryCache.setObject(scaledImage, forKey: key as NSString, cost: cost)
        
        // Store on disk asynchronously
        ioQueue.async { [weak self] in
            self?.saveImageToDisk(scaledImage, for: key)
        }
    }
    
    func removeImage(for url: URL) {
        let key = cacheKey(for: url)
        
        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk
        ioQueue.async { [weak self] in
            self?.removeImageFromDisk(for: key)
        }
    }
    
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        ioQueue.async { [weak self] in
            self?.clearDiskCache()
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for url: URL) -> String {
        return url.absoluteString.sha256Hash
    }
    
    private func diskCachePath(for key: String) -> URL {
        return diskCacheURL.appendingPathComponent(key)
    }
    
    private func createDiskCacheDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: diskCacheURL.path) else { return }
        
        do {
            try fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        } catch {
            print("[ImageCache] Failed to create disk cache directory: \(error)")
        }
    }
    
    private func loadImageFromDisk(for key: String) -> UIImage? {
        let path = diskCachePath(for: key)
        
        guard fileManager.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(_ image: UIImage, for key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let path = diskCachePath(for: key)
        
        do {
            try data.write(to: path)
        } catch {
            print("[ImageCache] Failed to save image to disk: \(error)")
        }
    }
    
    private func removeImageFromDisk(for key: String) {
        let path = diskCachePath(for: key)
        
        try? fileManager.removeItem(at: path)
    }
    
    private func clearDiskCache() {
        try? fileManager.removeItem(at: diskCacheURL)
        createDiskCacheDirectoryIfNeeded()
    }
    
    private func cleanExpiredDiskCache() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        let expirationDate = Date().addingTimeInterval(-maxCacheAge)
        
        for url in urls {
            guard let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }
            
            if modificationDate < expirationDate {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    
    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
    }
}

// MARK: - Image Loader

final class ImageLoader {
    
    // MARK: - Singleton
    
    static let shared = ImageLoader()
    
    // MARK: - Properties
    
    private let cache: ImageCacheProtocol
    private let session: URLSession
    private var activeTasks: [URL: URLSessionDataTask] = [:]
    private let taskQueue = DispatchQueue(label: "com.newsexplorer.imageloader.tasks")
    
    // MARK: - Initialization
    
    private init(cache: ImageCacheProtocol = ImageCache.shared) {
        self.cache = cache
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // Reduced timeout
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpMaximumConnectionsPerHost = 4 // Limit concurrent connections
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func loadImage(from url: URL) -> Observable<UIImage?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Check memory cache first (fast, synchronous)
            if let cachedImage = self.cache.getImage(for: url) {
                observer.onNext(cachedImage)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Check disk cache asynchronously, then download if needed
            if let imageCache = self.cache as? ImageCache {
                imageCache.getImageAsync(for: url) { [weak self] cachedImage in
                    if let cachedImage = cachedImage {
                        observer.onNext(cachedImage)
                        observer.onCompleted()
                        return
                    }
                    
                    // Not in cache, download
                    self?.downloadImage(from: url, observer: observer)
                }
            } else {
                // Fallback: download directly
                self.downloadImage(from: url, observer: observer)
            }
            
            return Disposables.create { [weak self] in
                self?.taskQueue.async {
                    self?.activeTasks[url]?.cancel()
                    self?.activeTasks.removeValue(forKey: url)
                }
            }
        }
    }
    
    private func downloadImage(from url: URL, observer: AnyObserver<UIImage?>) {
        let task = self.session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                DispatchQueue.main.async {
                    observer.onNext(nil)
                    observer.onCompleted()
                }
                return
            }
            
            self.taskQueue.async {
                self.activeTasks.removeValue(forKey: url)
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    observer.onNext(nil)
                    observer.onCompleted()
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    observer.onNext(nil)
                    observer.onCompleted()
                }
                return
            }
            
            // Cache the image
            self.cache.setImage(image, for: url)
            
            DispatchQueue.main.async {
                observer.onNext(image)
                observer.onCompleted()
            }
        }
        
        self.taskQueue.async {
            self.activeTasks[url] = task
        }
        
        task.resume()
    }
    
    func cancelLoad(for url: URL) {
        taskQueue.async { [weak self] in
            self?.activeTasks[url]?.cancel()
            self?.activeTasks.removeValue(forKey: url)
        }
    }
    
    func cancelAllLoads() {
        taskQueue.async { [weak self] in
            self?.activeTasks.values.forEach { $0.cancel() }
            self?.activeTasks.removeAll()
        }
    }
}

// MARK: - String Extension for Hashing

extension String {
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import CommonCrypto for SHA256
import CommonCrypto

