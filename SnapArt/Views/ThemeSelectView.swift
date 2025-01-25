import SwiftUI

struct ThemeSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: ArtStyle = .whimsicalWatercolor
    @State private var navigateToCamera = false
    
    let totalRows = 4
    let totalColumns = 2
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<totalRows, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(0..<totalColumns, id: \.self) { colIndex in
                        let buttonIndex = rowIndex * totalColumns + colIndex
                        if buttonIndex < ArtStyle.allCases.count {
                            let style = ArtStyle.allCases[buttonIndex]
                            ThemeButton(style: style) {
                                selectedTheme = style
                                navigateToCamera = true
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Select Theme")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToCamera) {
            TakePhotoView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

struct ThemeButton: View {
    let style: ArtStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(style.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                style.backgroundColor
                    .opacity(0.7)
            )
            .cornerRadius(8)
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
    
    var backgroundColor: Color {
        switch self {
        case .cyberpunkNeon:
            return Color.purple
        case .vintageSepia:
            return Color.brown
        case .whimsicalWatercolor:
            return Color.blue
        case .boldPopArt:
            return Color.red
        case .steampunkVictorian:
            return Color.orange
        case .minimalistFlat:
            return Color.gray
        case .baroquePainting:
            return Color.indigo
        case .abstractCubist:
            return Color.green
        }
    }
}

#Preview {
    ThemeSelectView()
} 