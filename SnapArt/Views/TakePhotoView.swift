import SwiftUI
import AVFoundation
import Photos

struct TakePhotoView: View {
    @StateObject private var viewModel = TakePhotoViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera preview using the better implementation
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
            
            // Capture button
            VStack {
                Spacer()
                
                Button(action: viewModel.capturePhoto) {
                    Circle()
                        .stroke(Color.gray, lineWidth: 3)
                        .frame(width: 70, height: 70)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                        .padding(.bottom, 30)
                }
            }
            
            // Flash animation
            if viewModel.showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(viewModel.showFlash ? 0.9 : 0)
                    .animation(.linear(duration: 0.4), value: viewModel.showFlash)
            }
        }
        .navigationBarBackButtonHidden(true)  // Hide the default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the button a bit larger
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.checkPermissionsAndSetupSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

// Camera preview representation
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

class TakePhotoViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showFlash = false
    @Published var capturedImage: UIImage?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
    }
    
    func checkPermissionsAndSetupSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                        self?.startSession()
                    }
                }
            }
        case .denied, .restricted:
            showError = true
            errorMessage = "Camera access is denied. Please enable it in Settings."
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            showError = true
            errorMessage = "Unable to access camera"
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoInput)
        
        // Add photo output
        guard session.canAddOutput(photoOutput) else {
            showError = true
            errorMessage = "Unable to capture photos"
            session.commitConfiguration()
            return
        }
        
        session.addOutput(photoOutput)
        session.commitConfiguration()
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        withAnimation {
            showFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showFlash = false
        }
    }
    
    private func saveToAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self?.showError = true
                    self?.errorMessage = "Unable to save photo. Please check album permissions."
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if !success {
                        self?.showError = true
                        self?.errorMessage = error?.localizedDescription ?? "Unable to save photo"
                    }
                }
            }
        }
    }
}

extension TakePhotoViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        if let error = error {
            showError = true
            errorMessage = error.localizedDescription
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showError = true
            errorMessage = "Unable to process photo"
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.saveToAlbum(image)
        }
    }
}

#Preview {
    TakePhotoView()
}