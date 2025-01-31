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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background as bottom layer
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                Image(uiImage: image)
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
        
        // do {
        //     Logger.log("Calling Stability AI API")
        //     processedImage = try await AIService.generateArtFromImage(
        //         image,
        //         prompt: selectedTheme.prompt,
        //         controlStrength: 0.7
        //     )
        //     Logger.log("Successfully received processed image")
        // } catch let error as AIService.AIError {
        //     Logger.log("AI Service error: \(error.localizedDescription)")
        //     errorMessage = error.localizedDescription
        // } catch {
        //     Logger.log("Unexpected error: \(error)")
        //     errorMessage = "Unexpected error occurred"
        // }
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 4_000_000_000) // 1 second delay
        
        if let testImage = UIImage(named: "temp_screen") {
            processedImage = testImage
            Logger.log("Successfully loaded test image")
            
            // Small delay to ensure animation setup
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 second delay
            isProcessing = false
        } else {
            Logger.log("Failed to load test image")
            errorMessage = "Failed to load test image"
            isProcessing = false
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