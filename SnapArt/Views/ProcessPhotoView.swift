import SwiftUI

struct ProcessPhotoView: View {
    let image: UIImage
    let selectedTheme: ArtStyle
    @Environment(\.dismiss) private var dismiss
    @State private var processedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Full screen image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Test window
                VStack(spacing: 12) {
                    // Test image window
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 120, height: 120)
                        
                        if let processedImage {
                            Image(uiImage: processedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 100, height: 100)
                        }
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
        }
    }
}

#Preview {
    ProcessPhotoView(
        image: UIImage(systemName: "photo")!,
        selectedTheme: .whimsicalWatercolor
    )
} 