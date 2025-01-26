import SwiftUI
import AVFoundation
import Photos

struct TakePhotoView: View {
    @StateObject private var viewModel = TakePhotoViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var navigateToProcess = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
            
            if let capturedImage = viewModel.capturedImage {
                // Review overlay
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                // Display captured image
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .cornerRadius(12)
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // Decision buttons
                        HStack(spacing: 50) {
                            Button(action: {
                                viewModel.capturedImage = nil // Reset and retake
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                navigateToProcess = true
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            } else {
                // Camera controls
                VStack {
                    Spacer()
                    
                    HStack(spacing: 50) {
                        // Photo library button
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        // Capture button
                        Button(action: viewModel.capturePhoto) {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                        
                        // Empty view for symmetry
                        Color.clear
                            .frame(width: 30, height: 30)
                    }
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.capturedImage)
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
        .navigationDestination(isPresented: $navigateToProcess) {
            if let image = viewModel.capturedImage {
                ProcessPhotoView(image: image)
            }
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
        
        override func layoutSubviews() {
            super.layoutSubviews()
            updateOrientation()
        }
        
        func updateOrientation() {
            if let connection = videoPreviewLayer.connection {
                let interfaceOrientation = window?.windowScene?.interfaceOrientation ?? .portrait
                let angle: Double
                
                // The camera's default orientation is landscape right (90 degrees)
                // So we need to adjust our angles accordingly
                switch interfaceOrientation {
                case .portrait:
                    angle = 90
                case .portraitUpsideDown:
                    angle = 270
                case .landscapeLeft:
                    angle = 180
                case .landscapeRight:
                    angle = 0
                default:
                    angle = 90
                }
                
                connection.videoRotationAngle = angle
            }
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.updateOrientation()
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
        uiView.updateOrientation()
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
    
    func saveToAlbum(_ image: UIImage) {
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
                    } else {
                        // Reset the captured image after successful save
                        self?.capturedImage = nil
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
            // No longer automatically saving to album
        }
    }
}

// Add this ImagePicker struct
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    TakePhotoView()
}