import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var permissionHandler = CameraPermissionHandler()
    @State private var showingMainContent = false
    
    var body: some View {
        ZStack {
            // Initial Logo View
            VStack {
                Image("SnapArtLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(20)
                    .onTapGesture {
                        withAnimation {
                            showingMainContent = true
                            permissionHandler.checkPermission()
                        }
                    }
                
                Text("SnapArt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tap logo to start")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .opacity(showingMainContent ? 0 : 1)
            
            // Camera Permission Content
            if showingMainContent {
                Group {
                    switch permissionHandler.cameraPermissionStatus {
                    case .authorized:
                        Button(action: {
                            // Navigate to TakePhotoView
                        }) {
                            VStack(spacing: 20) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                Text("Take Photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                    case .notDetermined:
                        RequestCameraView(permissionHandler: permissionHandler)
                    case .denied, .restricted:
                        CameraAccessDeniedView()
                    @unknown default:
                        Text("Unknown camera permission status")
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// Camera permission handling view models
class CameraPermissionHandler: ObservableObject {
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    func checkPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }
}

// View for requesting camera access
struct RequestCameraView: View {
    @ObservedObject var permissionHandler: CameraPermissionHandler
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("SnapArt needs access to your camera to transform your photos into art.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Allow Camera Access") {
                permissionHandler.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
}

// View for when camera access is denied
struct CameraAccessDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 70))
                .foregroundColor(.red)
            
            Text("Camera Access Denied")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("SnapArt requires camera access to function. Please enable camera access in Settings to continue.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
}

#Preview {
    ContentView()
} 