//
//  CameraViewModel.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import AVFoundation
import Alamofire
import Combine
import Vision
import CoreML
import ARKit


class CameraModel: NSObject,ObservableObject,AVCapturePhotoCaptureDelegate,AVCaptureVideoDataOutputSampleBufferDelegate{
    
    // MARK: - PROPERTY
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    // since were going to read pic data....
    @Published var output = AVCapturePhotoOutput()
    
    
    @Published var videoDataOutput :  AVCaptureVideoDataOutput?
    @Published var videoDataOutputQueue: DispatchQueue?
    // preview....
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    // Pic Data...
    
    
    @Published var picData = Data(count: 0)
    
    @Published var detectedImage : UIImage?
    @Published var originalImage : UIImage?
    
    
    @AppStorage("stars") var stars: Int = 7
    
    
    //View 구성용 Bool
    
    @Published var isSaved = false
    @Published var isTimerStart = false
    @Published var isProgressing = false
    @Published var isDetected = false
    @Published var isTexting = false
    
    @Published var comparePoint: [Double] = []
    @Published var modifyPoint: [Int] = []
    
    @Published var detectedFacesCGRect : [CGRect] = []
    
    @Published var errorDetected = false
    
    @Published var checkCompleted = false
    
    @Published var detectedNumberOfFaces = 0
    
    @Published var cameraTimerIsZero = false
    
    @Published var captureDevice: AVCaptureDevice?
    @Published var captureDeviceResolution: CGSize?
    
    
    //MARK: - FaceLayer
    
    @Published var rootLayer: CALayer?
    @Published var detectionOverlayLayer: CALayer?
    @Published var detectedFaceRectangleShapeLayer: CAShapeLayer?
    @Published var detectedFaceLandmarksShapeLayer: CAShapeLayer?
    
    // Vision requests
    @Published var detectionRequests: [VNDetectFaceRectanglesRequest]?
    @Published var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    
    override init(){
        super.init()
        //        self.detectionRequests?.removeAll()
        //        self.trackingRequests?.removeAll()
        
    }
    
    
    
    
    //MARK: - PHOTO FUNC
    
    
    
    func Check(){
        
        // first checking camerahas got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // Setting Up Session
        case .notDetermined:
            // retusting for permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                
                if status{
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
    
    func setUp(){
        
        
        
        // setting up camera...
        
        do{
            
            self.session.startRunning()
            //            self.prepareVisionRequest()
            let captureSession = AVCaptureSession()
            
            let inputDevice  = try self.configureFrontCamera(for: session)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: session)
            self.prepareVisionRequest()
            
            self.session = captureSession
            
            
            
            //            self.session = setupAVCaptureSession()!
            // setting configs...
            //            self.session.beginConfiguration()
            // change for your own...
            
            //            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            //
            //
            //            let input = try AVCaptureDeviceInput(device: device!)
            //
            //            // checking and adding to session...
            //
            //            if self.session.canAddInput(input){
            //                self.session.addInput(input)
            //            }
            //
            //            // same for output....
            //
            //            if self.session.canAddOutput(self.output){
            //                self.session.addOutput(self.output)
            //            }
            //            self.session.commitConfiguration()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    // take and retake functions...
    
    func takePic(){
        
        
        //        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        DispatchQueue.global(qos: .background).async {
            
            //            self.session.stopRunning()
            
            DispatchQueue.main.async {
                
                withAnimation{self.isTaken.toggle()}
            }
        }
        
        
        
    }
    
    
    
    func reTake(){
        
        DispatchQueue.main.async {
            
            
            withAnimation{
                self.isTaken = false
                
                self.session.startRunning()
            }
            //clearing ...
            
            
        }
        self.isSaved = false
        self.isDetected = false
        self.checkCompleted = false
        
        self.picData = Data(count: 0)
        self.detectedFacesCGRect.removeAll()
        self.detectedNumberOfFaces = 0
        self.modifyPoint.removeAll()
        self.comparePoint.removeAll()
        
        self.detectedImage = originalImage
        
        
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if error != nil{
            return
        }
        
        
        print("pic taken...")
        
        guard let imageData = photo.fileDataRepresentation() else{return}
        
        self.picData = imageData
        
        guard let image = UIImage(data: self.picData) else{return}
        let rotatedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        
        detectedImage = rotatedImage
        
        
        //        isDetected = true
        DispatchQueue.main.async {
            self.launchDetection(image: rotatedImage)
            
        }
        
        
    }
    
    //    func savePic(){
    //
    //        guard let image = UIImage(data: self.picData) else{return}
    // saving Image...
    //        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    //        self.isSaved = true
    //        print("saved Successfully....")
    //    }
    
    // MARK: DETECTION FUNC
    
    lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        
        
        let faceLandmarksRequest = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] request, error in
            self?.handleDetection(request: request, errror: error)
        })
        return faceLandmarksRequest
        
        
        
    }()
    
    fileprivate func launchDetection(image: UIImage) {
        
        let orientation = image.coreOrientation()
        guard let coreImage = CIImage(image: image) else { return }
        
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(ciImage: coreImage, orientation: orientation)
            do {
                try handler.perform([self.faceDetectionRequest])
                
            } catch {
                print("Failed to perform detection .\n\(error.localizedDescription)")
            }
        }
    }
    
    fileprivate func handleDetection(request: VNRequest, errror: Error?) {
        
        DispatchQueue.main.async { [weak self] in
            guard let observations = request.results as? [VNFaceObservation] else {
                fatalError("unexpected result type!")
            }
            
            print("Detected \(observations.count) faces")
            self?.detectedNumberOfFaces = observations.count
            //            observations.forEach( { self?.addFaceRecognitionLayer($0) })
            let image = self!.detectedImage
            //            let rotatedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
            var uiImage = image
            for observe in observations{
                
                UIGraphicsBeginImageContextWithOptions(uiImage!.size, true, 0.0)
                let context = UIGraphicsGetCurrentContext()
                
                // draw the image
                uiImage!.draw(in: CGRect(x: 0, y: 0, width: uiImage!.size.width, height: uiImage!.size.height))
                
                // 윤곽선 그리기
                let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -uiImage!.size.height)
                let translate = CGAffineTransform.identity.scaledBy(x: uiImage!.size.width, y: uiImage!.size.height)
                let facebounds = observe.boundingBox.applying(translate).applying(transform)
                
                
                
                
                context?.saveGState()
                context?.setStrokeColor(UIColor(named: "tangerine")!.cgColor)
                context?.setLineWidth(5)
                context?.addRect(facebounds)
                
                context?.drawPath(using: .stroke)
                context?.restoreGState()
                
                // get the final image
                let results = UIGraphicsGetImageFromCurrentImageContext()
                
                // end drawing context
                UIGraphicsEndImageContext()
                
                
                uiImage = results!
                
                // MARK: - 사진의 RECT를 받아서 Array에 저장하고 이후 서버에서 받은 리소스를 이용해 위치에 글을 올려둘 것 (얼굴 인식하는 크기 순서대로 배열에 추가됨)
                
                
                self!.detectedFacesCGRect.append(CGRect(x: ((facebounds.origin.x * 2) + facebounds.width)/3 , y: facebounds.origin.y + facebounds.height, width: 500 , height: 500))
                
                debugPrint( "얼굴 값 순서\(facebounds)")
                
                
                
            }
            //display final image
            DispatchQueue.main.async {
                self?.detectedImage = uiImage
                self?.isDetected = true
                //                self?.isTaken = true
                //                self?.picData = Data(count:0)
            }
            
        }
    }
    
    // MARK: - CGRECT 받은 값 위에 수치 값 올리기
    
    func textToImage(drawText text: String, inImage image: UIImage, detectedFaceCGRect: CGRect) {
        
        
        
        var uiImage = image
        
        let textColor = UIColor.white
        let textFont = UIFont(name: "SUIT-ExtraBold", size: 200)!
        
        //            let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
        ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let rect = detectedFaceCGRect
        text.draw(in: rect, withAttributes: textFontAttributes)
        //        debugPrint("두번쓰니 한번쓰니",rect.integral)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        
        uiImage = newImage!
        
        
        
        self.detectedImage = uiImage
        
        
        
    }
    
    
    
    
    
    
    // MARK: - REQUEST IMAGE
    
    
    
    func requestImage(index : Int){
        //얼굴 인식 한 수가 2명 이 아닐경우 경고 문을 내고 다시 찍게 하기
        if self.detectedNumberOfFaces != 2{
            self.isTaken = false
            self.errorDetected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                withAnimation{
                    self.errorDetected.toggle()
                }
            }
            self.reTake()
            
            
            //얼굴 인식 2명일경우 실행하는 함수
        }else{
            
            
            self.isProgressing = true
            self.isTaken = false
            
            
            
            
            let imageUploadHeaders: HTTPHeaders = [
                "Content-Type": "multipart/form-data"]
            
            let imageData = detectedImage!.jpegData(compressionQuality: 0.1)!
            
            AF.upload(multipartFormData: { multipartFormData in
                
                multipartFormData.append(imageData, withName: "image",fileName: "uploadImage.jpg" ,mimeType: "image/jpg")
            }, to: "http://3.36.43.152:35200/get_scores", method: .post, headers: imageUploadHeaders)
            .responseDecodable(of: ResponseModel.self) { response in
                
                
                if response.value?.status == "error"{
                    debugPrint(response, "얼굴 인식 불가")
                    //실패 했을경우 다시 찍게 유도 + 데이터 초기화
                    
                    self.isProgressing = false
                    self.errorDetected = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                        withAnimation{
                            self.errorDetected.toggle()
                        }
                    }
                    
                    
                    
                    self.reTake()
                    
                }else if response.value?.status == "success"{
                    debugPrint(response, "얼굴 인식 성공")
                    //성공 됬을경우 별 하나 소진
                    self.stars -= 1
                    
                    self.isProgressing = false
                    
                    self.checkCompleted = true
                    
                    
                    for i in 0..<2{
                        
                        switch index{
                        case 0...1 :   self.comparePoint.append((response.value?.faces[i].scores.beauty)!)
                        case 2  :   self.comparePoint.append((response.value?.faces[i].scores.cute)!)
                        case 3  :   self.comparePoint.append((response.value?.faces[i].scores.money)!)
                        case 4  :   self.comparePoint.append((response.value?.faces[i].scores.trouble)!)
                        default:
                            break
                        }
                        
                        debugPrint(self.comparePoint[i], "포인트")
                    }
                    
                    self.modifyPoint.append(Int(self.comparePoint[0]  / (self.comparePoint[0] + self.comparePoint[1]) * 100))
                    self.modifyPoint.append(100 - Int(self.comparePoint[0]  / (self.comparePoint[0] + self.comparePoint[1]) * 100))
                    
                    self.calculatePoint()
                    
                    
                }
                
            }
        }
        
        
        
    }
    
    // MARK: - 얼굴간의 점수 계산하기
    
    func calculatePoint(){
        debugPrint(modifyPoint[0], "포인트")
        if self.modifyPoint[0] > self.modifyPoint[1]{
            self.textToImage(drawText: "\(self.modifyPoint[0])% \n   W", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[0])
            self.textToImage(drawText: "\(self.modifyPoint[1])% \n   L", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[1])
        }else{
            self.textToImage(drawText: "\(self.modifyPoint[1])% \n   W", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[1])
            self.textToImage(drawText: "\(self.modifyPoint[0])% \n   L", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[0])
        }
    }
    
    
    
    
    
    
}

// MARK: - 카메라 프리뷰

struct CameraPreview: UIViewRepresentable {
    
    @StateObject var camera : CameraModel
    
    func makeUIView(context: Context) ->  UIView {
        
        //        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 150))
        let view = UIView(frame: UIScreen.main.bounds)
        
        
        
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        view.backgroundColor = UIColor(Color.black)
        // Your Own Properties...
        camera.preview.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(camera.preview)
        
        
        camera.rootLayer = view.layer
        // starting session
//        camera.session.startRunning()
        
        return view
    }
    
    
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}


extension CameraModel{
    
    
    
    
    
    
    
    /// - Tag: DesignatePreviewLayer
    //    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
    //        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    //        self.preview = videoPreviewLayer
    //
    //        videoPreviewLayer.name = "CameraPreview"
    //        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
    //        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    //
    //        if let previewRootLayer = self.previewView?.layer {
    //            self.rootLayer = previewRootLayer
    //
    //            previewRootLayer.masksToBounds = true
    //            videoPreviewLayer.frame = previewRootLayer.bounds
    //            previewRootLayer.addSublayer(videoPreviewLayer)
    //        }
    //    }
    
    
    
    // MARK: Helper Methods for Error Presentation
    
    //    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
    //        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    //        self.present(alertController, animated: true)
    //    }
    
    //    fileprivate func presentError(_ error: NSError) {
    //        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    //    }
    //
    // MARK: Helper Methods for Handling Device Orientation & EXIF
    
    
    // MARK: Performing Vision Requests
    
    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {
        
        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                  let results = faceDetectionRequest.results else {
                return
            }
            DispatchQueue.main.async {
                // Add the observations to the tracking list
                for observation in results {
                    let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        })
        
        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
        
        self.setupVisionDrawingLayers()
    }
    
    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    
    
    // MARK: Drawing Vision Observations
    
    fileprivate func setupVisionDrawingLayers() {
        
        debugPrint("\(self.captureDeviceResolution)setupVisionDrawingLayers")
        
        let captureDeviceResolution = self.captureDeviceResolution
        
        let captureDeviceBounds = CGRect(x: 0,
                                         y: 0,
                                         width: captureDeviceResolution!.width,
                                         height: captureDeviceResolution!.height)
        
        let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                     y: captureDeviceBounds.midY)
        
        let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)
        
        
        
        let overlayLayer = CALayer()
        overlayLayer.name = "DetectionOverlay"
        overlayLayer.masksToBounds = true
        overlayLayer.anchorPoint = normalizedCenterPoint
        overlayLayer.bounds = captureDeviceBounds
        overlayLayer.position = CGPoint(x: rootLayer!.bounds.midX, y: rootLayer!.bounds.midY)
        
        let faceRectangleShapeLayer = CAShapeLayer()
        faceRectangleShapeLayer.name = "RectangleOutlineLayer"
        faceRectangleShapeLayer.bounds = captureDeviceBounds
        faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
        faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
        faceRectangleShapeLayer.fillColor = nil
        faceRectangleShapeLayer.cornerRadius = 18
        faceRectangleShapeLayer.strokeColor = UIColor.orange.cgColor
        faceRectangleShapeLayer.lineWidth = 5
        faceRectangleShapeLayer.shadowOpacity = 0.7
        faceRectangleShapeLayer.shadowRadius = 5
        
        let faceLandmarksShapeLayer = CAShapeLayer()
        //        faceLandmarksShapeLayer.name = "FaceLandmarksLayer"
        //        faceLandmarksShapeLayer.bounds = captureDeviceBounds
        //        faceLandmarksShapeLayer.anchorPoint = normalizedCenterPoint
        //        faceLandmarksShapeLayer.position = captureDeviceBoundsCenterPoint
        //        faceLandmarksShapeLayer.fillColor = nil
        //        faceLandmarksShapeLayer.strokeColor = UIColor.yellow.withAlphaComponent(0.7).cgColor
        //        faceLandmarksShapeLayer.lineWidth = 3
        //        faceLandmarksShapeLayer.shadowOpacity = 0.7
        //        faceLandmarksShapeLayer.shadowRadius = 5
        //
        overlayLayer.addSublayer(faceRectangleShapeLayer)
        //        faceRectangleShapeLayer.addSublayer(faceLandmarksShapeLayer)
        rootLayer!.addSublayer(overlayLayer)
        
        self.detectionOverlayLayer = overlayLayer
        self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
        self.detectedFaceLandmarksShapeLayer = faceLandmarksShapeLayer
        
        self.updateLayerGeometry()
    }
    
    fileprivate func updateLayerGeometry() {
        
        debugPrint("updateLayerGeometry")
        guard let overlayLayer = self.detectionOverlayLayer,
              let rootLayer = self.rootLayer,
              let previewLayer = self.preview
        else {
            return
        }
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        var rotation: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat
        
        // Rotate the layer into screen orientation.
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotation = 180
            scaleX = videoPreviewRect.width / captureDeviceResolution!.width
            scaleY = videoPreviewRect.height / captureDeviceResolution!.height
            
        case .landscapeLeft:
            rotation = 90
            scaleX = videoPreviewRect.height / captureDeviceResolution!.width
            scaleY = scaleX
            
        case .landscapeRight:
            rotation = -90
            scaleX = videoPreviewRect.height / captureDeviceResolution!.width
            scaleY = scaleX
            
        default:
            rotation = 0
            scaleX = videoPreviewRect.width / captureDeviceResolution!.width
            scaleY = videoPreviewRect.height / captureDeviceResolution!.height
        }
        
        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
            .scaledBy(x: scaleX, y: -scaleY)
        overlayLayer.setAffineTransform(affineTransform)
        
        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds
        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
    }
    
    fileprivate func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D, to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        //        debugPrint("addPoints")
        let pointCount = landmarkRegion.pointCount
        if pointCount > 1 {
            let points: [CGPoint] = landmarkRegion.normalizedPoints
            path.move(to: points[0], transform: affineTransform)
            path.addLines(between: points, transform: affineTransform)
            if closePath {
                path.addLine(to: points[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }
    
    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, for faceObservation: VNFaceObservation) {
        debugPrint("addIndicators")
        let displaySize = self.captureDeviceResolution!
        
        let faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
        faceRectanglePath.addRect(faceBounds)
//        self.captureDeviceResolution! = CGSize(width: 0, height: 0)
//        if let landmarks = faceObservation.landmarks {
//            // Landmarks are relative to -- and normalized within --- face bounds
//            let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
//                .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)
//
            // Treat eyebrows and lines as open-ended regions when drawing paths.
//            let openLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
//                landmarks.leftEyebrow,
//                landmarks.rightEyebrow,
//                landmarks.faceContour,
//                landmarks.noseCrest,
//                landmarks.medianLine
//            ]
//            for openLandmarkRegion in openLandmarkRegions where openLandmarkRegion != nil {
//                self.addPoints(in: openLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: false)
//            }
//
//            // Draw eyes, lips, and nose as closed regions.
//            let closedLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
//                landmarks.leftEye,
//                landmarks.rightEye,
//                landmarks.outerLips,
//                landmarks.innerLips,
//                landmarks.nose
//            ]
//            for closedLandmarkRegion in closedLandmarkRegions where closedLandmarkRegion != nil {
//                self.addPoints(in: closedLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: true)
//            }
//        }
    }
    
    /// - Tag: DrawPaths
    fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        debugPrint("drawFaceObservations")
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer,
              let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer
        else {
            return
        }
        
        CATransaction.begin()
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()
        
        let singleFace = faceObservations[0]
        self.addIndicators(to: faceRectanglePath, faceLandmarksPath: faceLandmarksPath, for: singleFace)
        
        
        
        
        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath,
                               for: faceObservation)
        }
        
        faceRectangleShapeLayer.path = faceRectanglePath
        faceLandmarksShapeLayer.path = faceLandmarksPath
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
        
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }
        
        //MARK: - 사진 캡쳐하기
        if cameraTimerIsZero{
            let ciContext = CIContext(options: nil)
            let cgImage = ciContext.createCGImage(CIImage(cvImageBuffer: pixelBuffer), from: CIImage(cvImageBuffer: pixelBuffer).extent)!
            
            let rotatedImage = UIImage(cgImage: cgImage, scale: 1, orientation: .leftMirrored)
            
            
            DispatchQueue.main.async {
                self.detectedImage = rotatedImage
                self.launchDetection(image: rotatedImage)
                
                self.cameraTimerIsZero = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.session.stopRunning()
            }
        }
        
        
        
        
        let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
        
        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceRectangleRequest: %@", error)
            }
            return
        }
        
        do {
            try self.sequenceRequestHandler.perform(requests,
                                                    on: pixelBuffer,
                                                    orientation: exifOrientation)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }
        
        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {
            
            guard let results = trackingRequest.results else {
                return
            }
            
            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }
            
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        DispatchQueue.main.async {
            self.trackingRequests = newTrackingRequests
            
        }
        
        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            return
        }
        
        // Perform face landmark tracking on detected faces.
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
        
        // Perform landmark detection on tracked faces.
        for trackingRequest in newTrackingRequests {
            
            let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
                
                if error != nil {
                    print("FaceLandmarks error: \(String(describing: error)).")
                }
                
                guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                      let results = landmarksRequest.results else {
                    return
                }
                
                // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
                DispatchQueue.main.async {
                    self.drawFaceObservations(results)
                }
            })
            
            guard let trackingResults = trackingRequest.results else {
                return
            }
            
            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]
            
            // Continue to track detected facial landmarks.
            faceLandmarkRequests.append(faceLandmarksRequest)
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                try imageRequestHandler.perform(faceLandmarkRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceLandmarkRequest: %@", error)
            }
        }
        
        
        
        
        
    }
    
    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.beimsupictures.focusing")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        
        
        
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    
    
    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        
        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format
            
            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }
        
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        
        return nil
    }
    
    
    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: CreateCaptureSession
    func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice  = try self.configureFrontCamera(for: session)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: session)
            self.prepareVisionRequest()
            
            return captureSession
        } catch  {
            debugPrint("사진 찍는데 에러겠지")
        }
        self.teardownAVCapture()
        
        
        return nil
    }
    // Removes infrastructure for AVCapture as part of cleanup.
    
    
    func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil
        
        if let previewLayer = self.preview {
            previewLayer.removeFromSuperlayer()
            self.preview = nil
        }
    }
    
    
}
