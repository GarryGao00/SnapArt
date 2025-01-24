import SwiftUI
import PhotosUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    @State private var showingAPIKey = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Display selected or generated image
                if let image = viewModel.currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                }
                
                // Style picker
                Picker("Style", selection: $viewModel.selectedStyle) {
                    ForEach(ArtStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.menu)
                
                // Buttons
                VStack(spacing: 16) {
                    PhotosPicker(selection: $viewModel.imageSelection,
                               matching: .images) {
                        Label("Select Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if viewModel.currentImage != nil {
                        Button(action: viewModel.generateArt) {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Label("Generate Art", systemImage: "wand.and.stars")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isGenerating)
                    }
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                // Add debug button at the bottom
                Button("Show API Key") {
                    showingAPIKey.toggle()
                }
                .font(.caption)
                .padding(.bottom)
                
                if showingAPIKey {
                    Text("API Key: \(APIKeys.stabilityKey)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Art Generation")
        }
    }
}

class TestViewModel: ObservableObject {
    @Published var imageSelection: PhotosPickerItem? {
        didSet { loadSelectedImage() }
    }
    @Published var currentImage: UIImage?
    @Published var selectedStyle: ArtStyle = .whimsicalWatercolor
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private func loadSelectedImage() {
        guard let imageSelection else { return }
        
        Task {
            do {
                guard let data = try await imageSelection.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load image"])
                }
                
                await MainActor.run {
                    self.currentImage = image
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    func generateArt() {
        guard let image = currentImage else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let generatedImage = try await AIService.generateArtFromImage(
                    image,
                    prompt: selectedStyle.prompt,
                    controlStrength: 0.7
                )
                currentImage = generatedImage
            } catch let error as AIService.AIError {
                errorMessage = error.localizedDescription
                print("Generation error: \(error.localizedDescription)")
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("Unexpected error: \(error)")
            }
            isGenerating = false
        }
    }
}

enum ArtStyle: String, CaseIterable, Identifiable {
    case cyberpunkNeon
    case vintageSepia
    case whimsicalWatercolor
    case boldPopArt
    case steampunkVictorian
    case minimalistFlat
    case baroquePainting
    case abstractCubist
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .cyberpunkNeon: return "Cyberpunk Neon"
        case .vintageSepia: return "Vintage Sepia"
        case .whimsicalWatercolor: return "Whimsical Watercolor"
        case .boldPopArt: return "Bold Pop Art"
        case .steampunkVictorian: return "Steampunk Victorian"
        case .minimalistFlat: return "Minimalist Flat"
        case .baroquePainting: return "Baroque Painting"
        case .abstractCubist: return "Abstract Cubist"
        }
    }
    
    var prompt: String {
        switch self {
        case .cyberpunkNeon:
            return "Transform this image into a dark cyberpunk aesthetic with vibrant neon lights, high-contrast shadows, and a futuristic cityscape vibe."
        case .vintageSepia:
            return "Reinterpret this image in a warm, vintage sepia tone, reminiscent of old photographs, with soft grain and faded edges."
        case .whimsicalWatercolor:
            return "Repaint this image in a whimsical watercolor style using pastel colors, gentle brush strokes, and soft, diffused outlines."
        case .boldPopArt:
            return "Apply a bold pop art style with flat, saturated colors, thick black outlines, and a graphic, comic-book aesthetic."
        case .steampunkVictorian:
            return "Reimagine this image with a steampunk Victorian flair, featuring mechanical gears, brass tones, and an ornate, old-world industrial atmosphere."
        case .minimalistFlat:
            return "Simplify this image into a minimalist flat art style, using clean shapes, flat colors, and a subdued color palette."
        case .baroquePainting:
            return "Render this image as a dramatic baroque-style painting, with rich, deep shadows, warm candlelit highlights, and ornate, classical detailing."
        case .abstractCubist:
            return "Transform this image in an abstract cubist style, reducing elements into geometric shapes, bold angles, and fragmented perspectives."
        }
    }
}

#Preview {
    TestView()
} 