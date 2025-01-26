import SwiftUI

struct ProcessPhotoView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Full screen image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            // VStack {
            //     // Semi-transparent overlay at the top for better button visibility
            //     LinearGradient(
            //         colors: [
            //             .black.opacity(0.4),
            //             .clear
            //         ],
            //         startPoint: .top,
            //         endPoint: .bottom
            //     )
            //     .frame(height: 100)
            //     .ignoresSafeArea()
                
            //     Spacer()
            // }
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
    ProcessPhotoView(image: UIImage(systemName: "photo")!)
} 