//
//  ContentView.swift
//  IOS-CustomCamera
//
//  Created by Đoàn Văn Khoan on 21/9/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        CameraView()
    }
}

struct CameraView: View {
    
    
    @StateObject var camera = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                
                if camera.isTaken {
                    HStack {
                        Spacer()
                        
                        Button {
                            camera.reTakePic()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundStyle(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    .padding(.trailing, 10)
                    }
                }
                
                Spacer()
                
                HStack {
                    
                    if camera.isTaken {
                        Button {
                            if !camera.isSaved {
                                camera.savePic()
                            }
                        } label: {
                            Text(camera.isSaved ? "Saved" : "Save")
                                .foregroundStyle(.black)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .padding(.leading)
                        
                        Spacer()
                    } else {
                        Button {
                            camera.takePic()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        }
                    }
                }
                .frame(height: 75)
            }
        }
        .onAppear {
            camera.Check()
        }
    }
}

// Camera Model...
@MainActor
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    /// Since were going to read pic data...
    @Published var output = AVCapturePhotoOutput()
    
    /// Preview...
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    /// Pic data...
    @Published var isSaved = false
    @Published var picData = Data(count: 0)
    
    func Check() {
        /// First  checking camera  has has got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            /// Retusting for permission...
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func setUp() {
        do {
            /// Setting configs...
            self.session.beginConfiguration()
            
            /// Change for your own...
            guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Error: No camera available")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            /// Checking and adding to session...
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            /// Same for output...
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Take function...
    func takePic() {
        DispatchQueue.global(qos: .background).async {
            
            /// Need inherit AVCapturePhotoCaptureDelegate for set delegate
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    /// Retake function
    func reTakePic() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{
                    self.isTaken.toggle()
                    /// Clearing saved
                    self.isSaved = false
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if error != nil {
            return
        }
        
        print("pic taken...")
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        self.picData = imageData
    }
    
    func savePic() {
        let image = UIImage(data: self.picData)!
        
        /// Saving image...
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        print("save successfully")
    }
}

/// Settings view for preview
struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        /// Your own properties
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        /// Starting session
        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


#Preview {
    ContentView()
}
