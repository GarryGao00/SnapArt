//
//  ContentView.swift
//  SnapArt
//
//  Created by Garry Mackinaw on 1/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "camera.fill")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or generate from text:")
                        .font(.headline)
                    
                    TextField("Enter image description...", text: $viewModel.imagePrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: viewModel.generateFromText) {
                        Label("Generate from Text", systemImage: "text.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(viewModel.imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    if viewModel.isGenerating {
                        ProgressView("Generating...")
                            .padding()
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                VStack(spacing: 16) {
                    Button(action: viewModel.showImagePicker) {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: viewModel.showPhotoLibrary) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if viewModel.capturedImage != nil {
                        Button(action: viewModel.processImage) {
                            Label("Generate Art", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SnapArt")
            .sheet(isPresented: $viewModel.showingImagePicker) {
                ImagePicker(
                    sourceType: viewModel.imagePickerSourceType,
                    selectedImage: $viewModel.capturedImage
                )
            }
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @Published var imagePrompt = ""
    @Published var isGenerating = false
    @Published var generatedImage: UIImage?
    @Published var errorMessage: String?
    
    func showImagePicker() {
        imagePickerSourceType = .camera
        showingImagePicker = true
    }
    
    func showPhotoLibrary() {
        imagePickerSourceType = .photoLibrary
        showingImagePicker = true
    }
    
    func processImage() {
        // TODO: Implement image processing pipeline
        // 1. Send image to CV API for description
        // 2. Generate new image from description
    }
    
    @MainActor
    func generateFromText() {
        Task {
            isGenerating = true
            errorMessage = nil
            
            do {
                let image = try await AIService.generateImage(from: imagePrompt)
                generatedImage = image
                capturedImage = image  // Update the main image display
            } catch let error as AIService.AIError {
                switch error {
                case .imageGenerationFailed(let message):
                    errorMessage = "Generation failed: \(message)"
                default:
                    errorMessage = "An error occurred while generating the image"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isGenerating = false
        }
    }
}

#Preview {
    ContentView()
}
