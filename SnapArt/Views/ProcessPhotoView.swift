import SwiftUI

// Add this class outside the ProcessPhotoView struct
class ImageSaver: NSObject {
    var onSuccess: () -> Void
    var onError: (Error) -> Void
    
    init(onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onError(error)
        } else {
            onSuccess()
        }
    }
}

struct ProcessPhotoView: View {
    let image: UIImage
    let selectedTheme: ArtStyle
    @Environment(\.dismiss) private var dismiss
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var imageSaver: ImageSaver?
    @State private var originalImageOpacity: Double = 1.0
    @State private var compressedImage: UIImage
    
    init(image: UIImage, selectedTheme: ArtStyle) {
        self.image = image
        self.selectedTheme = selectedTheme
        // Initialize compressed image
        _compressedImage = State(initialValue: ProcessPhotoView.compressImage(image, maxSizeInMB: 1.0))
    }
    
    // Make compressImage static so it can be used in init
    private static func compressImage(_ image: UIImage, maxSizeInMB: Double) -> UIImage {
        let maxPixels = 9_000_000 // Slightly under Stability AI's limit of 9,437,184 pixels
        let currentPixels = Int(image.size.width * image.size.height)
        
        // First check if we need to resize due to pixel count
        var workingImage = image
        if currentPixels > maxPixels {
            Logger.log("Image exceeds maximum pixel count. Current: \(currentPixels), Max: \(maxPixels)")
            let scale = sqrt(Double(maxPixels) / Double(currentPixels))
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                workingImage = resizedImage
            }
            UIGraphicsEndImageContext()
            Logger.log("Resized image to: \(newSize)")
        }
        
        // Then handle file size compression
        let maxSizeInBytes = Int(maxSizeInMB * 1024 * 1024)
        var compression: CGFloat = 1.0
        let step: CGFloat = 0.1
        
        // Get initial data with maximum quality
        guard var imageData = workingImage.jpegData(compressionQuality: compression) else {
            Logger.log("Failed to get image data, returning working image")
            return workingImage
        }
        
        Logger.log("Image size after pixel resize: \(Double(imageData.count) / 1024 / 1024)MB")
        
        // Check if already under max size
        if imageData.count <= maxSizeInBytes {
            Logger.log("Image already under size limit")
            return workingImage
        }
        
        // Compress until the image is under maxSizeInBytes
        while imageData.count > maxSizeInBytes && compression > step {
            compression -= step
            if let compressedData = workingImage.jpegData(compressionQuality: compression) {
                imageData = compressedData
            }
        }
        
        if let finalImage = UIImage(data: imageData) {
            Logger.log("Final compressed image size: \(Double(imageData.count) / 1024 / 1024)MB")
            let finalPixels = Int(finalImage.size.width * finalImage.size.height)
            Logger.log("Final pixel count: \(finalPixels)")
            return finalImage
        }
        
        Logger.log("Compression failed, returning working image")
        return workingImage
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background as bottom layer
                Color.black
                    .edgesIgnoringSafeArea(.all)

                Image(uiImage: compressedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(originalImageOpacity)
                
                if let processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(isProcessing ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isProcessing)
                }
                
                VStack {
                    Spacer()
                    
                    // Test window
                    VStack(spacing: 12) {

                        Spacer()
                        
                        // Processing indicator
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)  // Make the spinner a bit larger
                        }
                        
                        // Error message if any
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()
                        
                        // // Theme information
                        // VStack(spacing: 8) {
                        //     Text(selectedTheme.title)
                        //         .font(.headline)
                        //         .foregroundColor(.white)
                            
                        //     Text(selectedTheme.prompt)
                        //         .font(.caption)
                        //         .foregroundColor(.white.opacity(0.8))
                        //         .multilineTextAlignment(.center)
                        //         .padding(.horizontal)
                        // }
                        // .padding()
                        // .background(
                        //     RoundedRectangle(cornerRadius: 12)
                        //         .fill(Color.black.opacity(0.7))
                        // )
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .padding(.horizontal, 20)
                    }
                }
                
                if let processedImage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            saveImageToAlbum(processedImage)
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding(.horizontal, 20)
                                .offset(y: -5)  // Move up by 10 pixels
                        }
                    }
                }
            }
            .alert("Image Saved!", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The image has been saved to your photo library.")
            }
            .alert("Save Failed", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
            .task {
                // Wait 0.5 seconds before starting fade to black
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                withAnimation(.easeInOut(duration: 2.0)) {
                    originalImageOpacity = 0
                }
                
                await processImage()
                
                // Add this line to ensure processing state is updated
                isProcessing = false
            }
            .onAppear {
                Logger.log("Entered ProcessPhotoView")
            }
            .onDisappear {
                Logger.log("Exited ProcessPhotoView")
            }
        }
        .ignoresSafeArea()
    }
    
    private func processImage() async {
        Logger.log("Starting image processing")
        isProcessing = true
        errorMessage = nil
        
        do {
            Logger.log("Compressing image if needed")
            
            
            Logger.log("Calling Stability AI API")
            let processed = try await AIService.generateArtFromImage(
                compressedImage,
                prompt: selectedTheme.prompt,
                controlStrength: 0.7
            )
            Logger.log("Successfully received processed image")
            
            await MainActor.run {
                processedImage = processed
            }
        } catch let error as AIService.AIError {
            Logger.log("AI Service error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Logger.log("Unexpected error: \(error)")
            errorMessage = "Unexpected error occurred"
        }
    }
    
    private func saveImageToAlbum(_ image: UIImage) {
        Logger.log("Saving image to album")
        // Convert WebP to PNG/JPEG data
        guard let imageData = image.pngData(),
              let convertedImage = UIImage(data: imageData) else {
            showingSaveError = true
            saveErrorMessage = "Failed to convert image format"
            return
        }
        
        imageSaver = ImageSaver(
            onSuccess: {
                Logger.log("Successfully saved image to album")
                showingSaveSuccess = true
            },
            onError: { error in
                Logger.log("Failed to save image: \(error.localizedDescription)")
                showingSaveError = true
                saveErrorMessage = error.localizedDescription
            }
        )
        UIImageWriteToSavedPhotosAlbum(convertedImage, imageSaver, #selector(ImageSaver.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
}

#Preview {
    ProcessPhotoView(
        image: UIImage(systemName: "photo")!,
        selectedTheme: .whimsicalWatercolor
    )
} 