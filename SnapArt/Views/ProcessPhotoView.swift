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
    
    var body: some View {
        ZStack {
            // Show either original or processed image full screen
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                
                // Test window
                VStack(spacing: 12) {
                    // Processing indicator
                    if isProcessing {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 120, height: 120)
                            
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    
                    // Error message if any
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Theme information
                    VStack(spacing: 8) {
                        Text(selectedTheme.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(selectedTheme.prompt)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                    )
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
                        .padding(.leading, 20)
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
                            .padding(.trailing, 20)
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
            await processImage()
        }
    }
    
    private func processImage() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            processedImage = try await AIService.generateArtFromImage(
                image,
                prompt: selectedTheme.prompt,
                controlStrength: 0.7
            )
        } catch let error as AIService.AIError {
            errorMessage = error.localizedDescription
            print("AI Service error: \(error.localizedDescription)")
        } catch {
            errorMessage = "Unexpected error occurred"
            print("Unexpected error: \(error)")
        }
        
        isProcessing = false
    }
    
    private func saveImageToAlbum(_ image: UIImage) {
        // Convert WebP to PNG/JPEG data
        guard let imageData = image.pngData(),
              let convertedImage = UIImage(data: imageData) else {
            showingSaveError = true
            saveErrorMessage = "Failed to convert image format"
            return
        }
        
        imageSaver = ImageSaver(
            onSuccess: {
                showingSaveSuccess = true
            },
            onError: { error in
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