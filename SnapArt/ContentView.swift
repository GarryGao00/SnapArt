import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @StateObject private var permissionHandler = CameraPermissionHandler()
    @State private var showingMainContent = false
    @State private var navigateToThemeSelect = false
    @State private var showHint = false
    @State private var fadeOutContent = false
    @State private var showingSettings = false
    @State private var stabilityKey = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Add a clear full screen button to detect taps
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.05)) {
                            showHint = true
                        }
                    }
                
                // Initial Logo View
                VStack {
                    Spacer()
                    
                    Image("SnapArtLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                        .onTapGesture {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            Logger.log("Logo tapped, navigating to theme selection")
                            showHint = false
                            
                            // Immediately start fade out
                            withAnimation {
                                fadeOutContent = true
                            }
                            
                            // Navigate after fade completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showingMainContent = true
                                permissionHandler.checkPermission()
                                if permissionHandler.cameraPermissionStatus == .authorized {
                                    navigateToThemeSelect = true
                                }
                            }
                        }
                    
                    Text("SnapArt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tap logo to start")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .opacity(showHint ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showHint)
                    
                    Spacer()
                    
                    // // Debug view for API key
                    // let prefix = APIKeys.stabilityKey.prefix(5)
                    // Text("API Key (debug): \(String(prefix))...")
                    //     .font(.caption2)
                    //     .foregroundColor(.gray)
                    //     .padding(.bottom, 8)
                }
                .opacity(showingMainContent ? 0 : 1)
                
                // White overlay for fade out effect (moved before permission content)
                Color.white
                    .opacity(fadeOutContent ? 1 : 0)
                    .animation(.easeIn(duration: 0.5), value: fadeOutContent)
                    .ignoresSafeArea(.all, edges: .all)
                    .allowsHitTesting(false)  // Allow taps to pass through
                
                // Camera Permission Content
                if showingMainContent {
                    Group {
                        switch permissionHandler.cameraPermissionStatus {
                        case .authorized:
                            if permissionHandler.photoLibraryStatus == .authorized {
                                Color.clear
                            } else {
                                RequestCameraView(permissionHandler: permissionHandler)
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
            .navigationDestination(isPresented: $navigateToThemeSelect) {
                ThemeSelectView()
            }
            .onChange(of: permissionHandler.cameraPermissionStatus) { _, newValue in
                if newValue == .authorized && permissionHandler.photoLibraryStatus == .authorized {
                    navigateToThemeSelect = true
                }
            }
            .onChange(of: permissionHandler.photoLibraryStatus) { _, newValue in
                if newValue == .authorized && permissionHandler.cameraPermissionStatus == .authorized {
                    navigateToThemeSelect = true
                }
            }
            .onChange(of: navigateToThemeSelect) { oldValue, newValue in
                if newValue == false {
                    withAnimation {
                        showingMainContent = false
                        fadeOutContent = false
                        showHint = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                            .scaleEffect(0.8)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        let prefix = APIKeys.stabilityKey.prefix(7)
                        Text("Current API Key: \(String(prefix))... \nPaste your Stability AI Key Here. ")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        TextField("Format: sk-...", text: $stabilityKey, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .frame(height: 70)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                stabilityKey = ""  // Reset the input
                                showingSettings = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if !stabilityKey.isEmpty {
                                    APIKeys.setStabilityKey(stabilityKey)
                                }
                                stabilityKey = ""  // Reset the input
                                showingSettings = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            Logger.log("Entered ContentView")
            showHint = false
            fadeOutContent = false
        }
        .onDisappear {
            Logger.log("Exited ContentView")
        }
    }
}

// Camera permission handling view models
class CameraPermissionHandler: ObservableObject {
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    
    func checkPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPermission() {
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
        
        // Request photo library permission
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.photoLibraryStatus = status
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
            
            Text("Camera & Photo Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("SnapArt needs access to your camera to take photos and photo library to save your artistic creations.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Allow Access") {
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
