//
//  ImageUploadService.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/04/25.
//

import SwiftUI
import Combine
import UIKit
import FirebaseStorage
import PhotosUI

@MainActor
class ImageUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadError: String?
    @Published var uploadedImageURL: URL?
    @Published var selectedImage: UIImage?
    
    private let storage = Storage.storage()
    private let maxImageDimension: CGFloat = 2048
    private let jpegCompressionQuality: CGFloat = 0.8
    
    // MARK: - Public Methods
    
    /// Uploads an image to Firebase Storage and returns the download URL
    /// - Parameter image: The UIImage to upload
    /// - Returns: The download URL of the uploaded image, or nil if upload fails
    func uploadImage(_ image: UIImage) async -> URL? {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        selectedImage = image
        
        defer {
            isUploading = false
        }
        
        // Resize image if needed
        let resizedImage = resizeImage(image, maxDimension: maxImageDimension)
        
        // Convert to JPEG data (automatically converts HEIC and other formats)
        guard let imageData = resizedImage.jpegData(compressionQuality: jpegCompressionQuality) else {
            uploadError = "Failed to process image. Please try a different photo."
            return nil
        }
        
        // Generate filename with timestamp and UUID
        let filename = generateFilename()
        let storageRef = storage.reference().child("report-images/\(filename)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            // Upload the image data using async/await
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get the download URL
            let downloadURL = try await storageRef.downloadURL()
            
            uploadedImageURL = downloadURL
            uploadProgress = 1.0
            
            return downloadURL
            
        } catch let error as NSError {
            // Provide more specific error messages
            if error.domain == StorageErrorDomain {
                switch StorageErrorCode(rawValue: error.code) {
                case .unauthenticated:
                    uploadError = "Please sign in to upload images."
                case .unauthorized:
                    uploadError = "You don't have permission to upload images."
                case .quotaExceeded:
                    uploadError = "Storage quota exceeded. Please contact support."
                case .nonMatchingChecksum, .downloadSizeExceeded:
                    uploadError = "Upload failed. The image may be too large."
                default:
                    uploadError = "Upload failed: \(error.localizedDescription)"
                }
            } else {
                uploadError = "Failed to upload image: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// Clears the current uploaded image and resets state
    func clearImage() {
        selectedImage = nil
        uploadedImageURL = nil
        uploadProgress = 0.0
        uploadError = nil
    }
    
    // MARK: - Private Helpers
    
    /// Resizes an image to fit within the maximum dimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Perform the resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Generates a filename with timestamp and UUID
    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let uuid = UUID().uuidString.lowercased()
        return "lost-item-\(dateString)-\(uuid).jpg"
    }
}

// MARK: - Image Picker Coordinator

class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePickerWrapper
    
    init(parent: ImagePickerWrapper) {
        self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            parent.onImageSelected(image)
        }
        parent.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.dismiss()
    }
}

// MARK: - Image Picker Wrapper (for Camera)

struct ImagePickerWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeCoordinator() -> ImagePickerCoordinator {
        ImagePickerCoordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Photo Picker Wrapper (for Photo Library - iOS 14+)

struct PhotoPickerWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> PhotoPickerCoordinator {
        PhotoPickerCoordinator(parent: self)
    }
    
    class PhotoPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerWrapper
        
        init(parent: PhotoPickerWrapper) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
}

