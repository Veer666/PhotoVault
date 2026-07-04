//
//  CloudinaryManager.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - Cloudinary Config
private enum CloudinaryConfig {
    static let cloudName = "ke9cpuk4"
    static let uploadPreset = "photo_vault_upload"
}

// MARK: - Task Delegate to Track Progress
private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    private let progressHandler: (@Sendable (Double) -> Void)?
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var responseData = Data()
    private let dataLock = NSLock()
    
    init(
        progressHandler: (@Sendable (Double) -> Void)?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progressHandler?(progress)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataLock.lock()
        responseData.append(data)
        dataLock.unlock()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(nil, task.response, error)
        } else {
            dataLock.lock()
            let finalData = responseData
            dataLock.unlock()
            completionHandler(finalData, task.response, nil)
        }
    }
}

// MARK: - Cloudinary Manager
public final class CloudinaryManager: @unchecked Sendable {
    public static let shared = CloudinaryManager()
    
    private let lock = NSLock()
    private var activeTasks: [String: URLSessionDataTask] = [:]
    
    private init() {}
    
    /// Register an active task for possible cancellation
    private func registerTask(_ task: URLSessionDataTask, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks[id] = task
    }
    
    /// Deregister an active task
    private func deregisterTask(for id: String) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks.removeValue(forKey: id)
    }
    
    /// Cancel an ongoing upload task
    public func cancelUpload(for id: String) {
        lock.lock()
        let task = activeTasks[id]
        lock.unlock()
        
        task?.cancel()
        deregisterTask(for: id)
    }
    
    /// Uploads photo/video data directly to Cloudinary using Unsigned Preset
    /// - Parameters:
    ///   - data: Compressed image or video data.
    ///   - userID: The ID of the authenticated user.
    ///   - photoID: The unique ID generated for this photo.
    ///   - mediaType: The type of media ("image" or "video")
    ///   - progressHandler: Closure to receive progress updates (0.0 to 1.0).
    /// - Returns: Secure URL string from Cloudinary.
    public func uploadPhoto(
        data: Data,
        userID: String,
        photoID: String,
        mediaType: String = "image",
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> String {

        let resourceType = mediaType == "video" ? "video" : "image"

        guard let uploadURL = URL(
            string: "https://api.cloudinary.com/v1_1/\(CloudinaryConfig.cloudName)/\(resourceType)/upload"
        ) else {
            throw NSError(
                domain: "CloudinaryManager",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid Cloudinary URL."
                ]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in

            let boundary = UUID().uuidString

            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )

            let fileExtension = mediaType == "video" ? "mp4" : "jpg"
            let fileName = "\(photoID).\(fileExtension)"
            let mimeType = mediaType == "video" ? "video/mp4" : "image/jpeg"

            // IMPORTANT:
            // Since your preset has "Disallow Public ID = true",
            // DO NOT send public_id.

            let params = [
                "upload_preset": CloudinaryConfig.uploadPreset,
                "folder": "photos/\(userID)"
            ]

            request.httpBody = createMultipartBody(
                data: data,
                fileName: fileName,
                mimeType: mimeType,
                boundary: boundary,
                params: params
            )

            let delegate = UploadProgressDelegate(
                progressHandler: progressHandler
            ) { [weak self] responseData, response, error in

                self?.deregisterTask(for: photoID)

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "CloudinaryManager",
                            code: -2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Invalid response."
                            ]
                        )
                    )
                    return
                }

                guard (200...299).contains(httpResponse.statusCode),
                      let responseData else {

                    let message = responseData.flatMap {
                        String(data: $0, encoding: .utf8)
                    } ?? "Unknown error"

                    continuation.resume(
                        throwing: NSError(
                            domain: "CloudinaryManager",
                            code: httpResponse.statusCode,
                            userInfo: [
                                NSLocalizedDescriptionKey: message
                            ]
                        )
                    )
                    return
                }

                do {

                    guard
                        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                        let secureURL = json["secure_url"] as? String
                    else {
                        throw NSError(
                            domain: "CloudinaryManager",
                            code: -3,
                            userInfo: [
                                NSLocalizedDescriptionKey: "secure_url not found."
                            ]
                        )
                    }

                    continuation.resume(returning: secureURL)

                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let session = URLSession(
                configuration: .default,
                delegate: delegate,
                delegateQueue: nil
            )

            let task = session.dataTask(with: request)

            self.registerTask(task, for: photoID)

            task.resume()
        }
    }
    
    /// Mock client-side deletion (Requires Admin API/secret which is server-only. Unused client-side).
    public func deletePhoto(url: String) async throws {
        // Unsigned delete by URL is not natively supported by Cloudinary purely client-side without API secret.
        // We log/keep this as a no-op placeholder method to satisfy compiler protocols without compromising keys.
        print("Mock: Photo deletion triggered client-side for url \(url). Deletion should normally be managed via server-side SDKs.")
    }
    
    /// Helper to compress a UIImage to JPEG data
    public func compressImage(_ image: UIImage, maxBytes: Int = 1_000_000) -> Data? {
        var quality: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: quality)
        
        while let currentData = data, currentData.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        
        return data
    }
    
    // MARK: - Multipart Helper
    private func createMultipartBody(
        data: Data,
        fileName: String,
        mimeType: String,
        boundary: String,
        params: [String: String]
    ) -> Data {
        var body = Data()
        
        // Text parameters
        for (key, value) in params {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // File parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        return body
    }
}


// MARK: - Data Extension Helper
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

