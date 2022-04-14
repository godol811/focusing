

import AVFoundation
import CoreImage
import MetalKit
import SwiftUI

class CameraViewController: UIViewController {
    var faceDetector: FaceDetector?
    @AppStorage("cameraNotAuthorized") var cameraNotAuthorized: Bool = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    let session = AVCaptureSession()
    
    var isUsingMetal = false
    var metalDevice: MTLDevice?
    var metalCommandQueue: MTLCommandQueue?
    var metalView: MTKView?
    var ciContext: CIContext?
    
    var currentCIImage: CIImage? {
        didSet {
            metalView?.draw()
        }
    }
    
    let videoOutputQueue = DispatchQueue(
        label: "Video Output Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceDetector?.viewDelegate = self
        configureCaptureSession()
        
        session.startRunning()
    }
}

// MARK: - Setup video capture

extension CameraViewController {
    func configureCaptureSession() {
        
        
        if !cameraNotAuthorized{
            // Define the capture device we want to use
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                fatalError("No front video camera available")
            }
            
            do {
                let cameraInput = try AVCaptureDeviceInput(device: camera)
                self.session.addInput(cameraInput)
            } catch {
                fatalError(error.localizedDescription)
            }
            
        }
        
        
        
        
        
        // Connect the camera to the capture session input
        
        
        // Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(faceDetector, queue: videoOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Add the video output to the capture session
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        // Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = UIScreen.main.bounds
        
        if !isUsingMetal, let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
}

// MARK: Setup Metal

extension CameraViewController {
    func configureMetal() {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not instantiate required metal properties")
        }
        
        isUsingMetal = true
        metalCommandQueue = metalDevice.makeCommandQueue()
        
        metalView = MTKView()
        if let metalView = metalView {
            metalView.device = metalDevice
            metalView.isPaused = true
            metalView.enableSetNeedsDisplay = false
            metalView.delegate = self
            metalView.framebufferOnly = false
            metalView.frame = view.bounds
            metalView.layer.contentsGravity = .resizeAspect
            view.layer.insertSublayer(metalView.layer, at: 0)
        }
        
        ciContext = CIContext(mtlDevice: metalDevice)
    }
}

// MARK: - Metal view delegate methods

extension CameraViewController: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard
            let metalView = metalView,
            let metalCommandQueue = metalCommandQueue
        else {
            return
        }
        
        // Grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let ciImage = currentCIImage else {
            return
        }
        
        // Ensure drawable is free and not tied in the preivous drawing cycle
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        
        // Make sure the image is full width, and scaled in height appropriately
        let drawSize = metalView.drawableSize
        let scaleX = drawSize.width / ciImage.extent.width
        
        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleX))
        
        let originY = (newImage.extent.height - drawSize.height) / 2
        
        // Render into the metal texture
        ciContext?.render(
            newImage,
            to: currentDrawable.texture,
            commandBuffer: commandBuffer,
            bounds: CGRect(x: 0, y: originY, width: newImage.extent.width, height: newImage.extent.height),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        // Register drawwable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
}

// MARK: FaceDetectorDelegate methods

extension CameraViewController: FaceDetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        guard let previewLayer = previewLayer else {
            return CGRect.zero
        }
        
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
    
    func draw(image: CIImage) {
        currentCIImage = image
    }
}
