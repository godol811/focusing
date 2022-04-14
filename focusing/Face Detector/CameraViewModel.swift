

import Combine
import CoreGraphics
import UIKit
import Vision
import SwiftUI
import Alamofire
import AVFoundation

enum CameraViewModelAction {
  // View setup and configuration actions
  case windowSizeDetected(CGRect)

  // Face detection actions
  case noFaceDetected
  case faceObservationDetected(FaceGeometryModel)
  case faceQualityObservationDetected(FaceQualityModel)

  // Other
  case toggleDebugMode
  case toggleHideBackgroundMode
  case takePhoto
  case savePhoto(UIImage)
}

enum FaceDetectedState {
  case faceDetected
  case noFaceDetected
  case faceDetectionErrored
}

enum FaceBoundsState {
  case unknown
  case detectedFaceTooSmall
  case detectedFaceTooLarge
  case detectedFaceOffCentre
  case detectedFaceAppropriateSizeAndPosition
}

struct FaceGeometryModel {
  let boundingBox: CGRect
  let roll: NSNumber
  let pitch: NSNumber
  let yaw: NSNumber
}

struct FaceQualityModel {
  let quality: Float
}

final class CameraViewModel: ObservableObject {
    
    
    
    
    
    
    @AppStorage("cameraNotAuthorized") var cameraNotAuthorized: Bool = true
    
  // MARK: - Publishers
    @Published var debugModeEnabled: Bool
    @Published var hideBackgroundModeEnabled: Bool
    
    
    @Published var isTaken = false
    @Published var alert = false
    
    @Published var picData = Data(count: 0)
    
    @Published var detectedImage : UIImage?
    @Published var originalImage : UIImage?
    
    
//    @AppStorage(AppStorageKeys.stars) var stars: Int = 5
    //View 구성용 Bool
    
    @Published var isSaved = false
    @Published var isTimerStart = false
    @Published var isProgressing = false
    @Published var isDetected = false
    @Published var isTexting = false
    
    @Published var comparePoint: [Double] = []
    @Published var modifyPoint: [Int] = []
    
    @Published var detectedFacesCGRect : [CGRect] = []
    @Published var detectedFacesCGRectX : [Double] = []
    
    @Published var errorDetected = false
    
    @Published var checkCompleted = false
    
    @Published var detectedNumberOfFaces = 0
    
    @Published var timeRemaining = 3
    
    @Published var cameraTimerIsZero = false
    
    @Published var isZeroStarAlert = false

    @Published  var moveToShop = false
    
  
    @Published var audioFile :URL?
    
  // MARK: - Publishers of derived state
  @Published private(set) var hasDetectedValidFace: Bool
  @Published private(set) var isAcceptableRoll: Bool {
    didSet {
      calculateDetectedFaceValidity()
    }
  }
  @Published private(set) var isAcceptablePitch: Bool {
    didSet {
      calculateDetectedFaceValidity()
    }
  }
  @Published private(set) var isAcceptableYaw: Bool {
    didSet {
      calculateDetectedFaceValidity()
    }
  }
  @Published private(set) var isAcceptableBounds: FaceBoundsState {
    didSet {
      calculateDetectedFaceValidity()
    }
  }
  @Published private(set) var isAcceptableQuality: Bool {
    didSet {
      calculateDetectedFaceValidity()
    }
  }
  @Published private(set) var passportPhoto: UIImage?

  // MARK: - Publishers of Vision data directly
  @Published private(set) var faceDetectedState: FaceDetectedState
  @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> {
    didSet {
      processUpdatedFaceGeometry()
    }
  }

  @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> {
    didSet {
      processUpdatedFaceQuality()
    }
  }

  // MARK: - Public properties
  let shutterReleased = PassthroughSubject<Void, Never>()

  // MARK: - Private variables
  var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)

  init() {
    faceDetectedState = .noFaceDetected
    isAcceptableRoll = false
    isAcceptablePitch = false
    isAcceptableYaw = false
    isAcceptableBounds = .unknown
    isAcceptableQuality = false

    hasDetectedValidFace = false
    faceGeometryState = .faceNotFound
    faceQualityState = .faceNotFound

    #if DEBUG
      debugModeEnabled = true
    #else
      debugModeEnabled = false
    #endif
    hideBackgroundModeEnabled = false
      
  }
    
    //MARK: - SHOW FACEBOUNDARY WHEN PICTURE TAKEN
    
    lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        
        
        let faceLandmarksRequest = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] request, error in
            self?.handleDetection(request: request, errror: error)
        })
        return faceLandmarksRequest
        
        
        
    }()
    func reTake(){
        
        DispatchQueue.main.async {
            
            
            withAnimation{
                self.isTaken = false
                
            }
            //clearing ...
            
            
        }
        self.isSaved = false
        self.isDetected = false
        self.checkCompleted = false
        
        self.picData = Data(count: 0)
        self.detectedFacesCGRect.removeAll()
        self.detectedFacesCGRectX.removeAll()
        self.detectedNumberOfFaces = 0
        self.modifyPoint.removeAll()
        self.comparePoint.removeAll()
        
        self.detectedImage = originalImage
        
        
        
    }
    // MARK: - PERMISSION FOR CAMERA
    func Check(){
        
        // first checking camerahas got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
         cameraNotAuthorized = false
            return
            // Setting Up Session
        case .notDetermined:
            // retusting for permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.cameraNotAuthorized = false
                    
                }
            }
        case .denied:
            cameraNotAuthorized = true
            return
            
        default:
            return
        }
    }
    
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
                
//
                self!.detectedFacesCGRect.append(CGRect(x: facebounds.origin.x , y: facebounds.origin.y + facebounds.height, width: 300 , height: 300))
//
                self!.detectedFacesCGRectX.append(facebounds.origin.x)
                
                debugPrint( "얼굴 값 순서\(facebounds.origin.x)")
                
                
                
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
        let textFont = UIFont(name: "SUIT-ExtraBold", size: 100)!
        
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
    func calculatePoint(){
        debugPrint(modifyPoint[0], "포인트")
        if self.modifyPoint[0] > self.modifyPoint[1]{
            self.textToImage(drawText: "\(self.modifyPoint[0])% \n  W", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[0])
            self.textToImage(drawText: "\(self.modifyPoint[1])% \n  L", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[1])
        }else{
            self.textToImage(drawText: "\(self.modifyPoint[1])% \n  W", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[1])
            self.textToImage(drawText: "\(self.modifyPoint[0])% \n  L", inImage: self.detectedImage!, detectedFaceCGRect: self.detectedFacesCGRect[0])
        }
    }
    
    
    func requestImage(index : Int){
        //얼굴 인식 한 수가 2명 이 아닐경우 경고 문을 내고 다시 찍게 하기
        
        self.modifyPoint.removeAll()
        self.comparePoint.removeAll()
        
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
                  
                    UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: AppStorageKeys.stars) - 1, forKey: AppStorageKeys.stars)
                    self.isProgressing = false
                    
                    self.checkCompleted = true
                    
                    
                    for i in 0..<2{
//                        self.detectedFacesCGRect.append(CGRect(x: (((response.value?.faces[i].bbox.x)! * 2) + (response.value?.faces[i].bbox.w)!) / 3 , y: (response.value?.faces[i].bbox.y)! + (response.value?.faces[i].bbox.h)! , width: 500 , height: 500))
//
                        switch index{
                        case 0...1 :   self.comparePoint.append((response.value?.faces[i].scores.beauty)!)
                        case 2  :   self.comparePoint.append((response.value?.faces[i].scores.cute)!)
                        case 3  :   self.comparePoint.append((response.value?.faces[i].scores.money)!)
                        case 4  :   self.comparePoint.append((response.value?.faces[i].scores.trouble)!)
                        default:
                            break
                        }
                        
//                        debugPrint(self.detectedFacesCGRect[i], "위치값")
                    }
//                    if ((response.value?.faces[0].bbox.x)! - (response.value?.faces[1].bbox.x)!) > 0 && (self.detectedFacesCGRectX[0] - self.detectedFacesCGRectX[1]) > 0 {
                        self.modifyPoint.append(Int(self.comparePoint[0]  / (self.comparePoint[0] + self.comparePoint[1]) * 100))
                        self.modifyPoint.append(100 - Int(self.comparePoint[0]  / (self.comparePoint[0] + self.comparePoint[1]) * 100))
//
//
//                    }else{
//                        self.modifyPoint.append(Int(self.comparePoint[1]  / (self.comparePoint[1] + self.comparePoint[0]) * 100))
//                        self.modifyPoint.append(100 - Int(self.comparePoint[1]  / (self.comparePoint[0] + self.comparePoint[1]) * 100))
//                    }
                    
                    
                    
                    self.calculatePoint()
                    
                    
                }
                
            }
        
        }
        
        
        
        
    }
    
    

  // MARK: Actions

  func perform(action: CameraViewModelAction) {
    switch action {
    case .windowSizeDetected(let windowRect):
      handleWindowSizeChanged(toRect: windowRect)
    case .noFaceDetected:
      publishNoFaceObserved()
    case .faceObservationDetected(let faceObservation):
      publishFaceObservation(faceObservation)
    case .faceQualityObservationDetected(let faceQualityObservation):
      publishFaceQualityObservation(faceQualityObservation)
    case .toggleDebugMode:
      toggleDebugMode()
    case .toggleHideBackgroundMode:
      toggleHideBackgroundMode()
    case .takePhoto:
      takePhoto()
    case .savePhoto(let image):
      savePhoto(image)
    }
  }

  // MARK: Action handlers

  private func handleWindowSizeChanged(toRect: CGRect) {
    faceLayoutGuideFrame = CGRect(
      x: toRect.midX - faceLayoutGuideFrame.width / 2,
      y: toRect.midY - faceLayoutGuideFrame.height / 2,
      width: faceLayoutGuideFrame.width,
      height: faceLayoutGuideFrame.height
    )
  }

  private func publishNoFaceObserved() {
    DispatchQueue.main.async { [self] in
      faceDetectedState = .noFaceDetected
      faceGeometryState = .faceNotFound
      faceQualityState = .faceNotFound
    }
  }

  private func publishFaceObservation(_ faceGeometryModel: FaceGeometryModel) {
    DispatchQueue.main.async { [self] in
      faceDetectedState = .faceDetected
      faceGeometryState = .faceFound(faceGeometryModel)
    }
  }

  private func publishFaceQualityObservation(_ faceQualityModel: FaceQualityModel) {
    DispatchQueue.main.async { [self] in
      faceDetectedState = .faceDetected
      faceQualityState = .faceFound(faceQualityModel)
    }
  }

  private func toggleDebugMode() {
    debugModeEnabled.toggle()
  }

  private func toggleHideBackgroundMode() {
    hideBackgroundModeEnabled.toggle()
  }

  private func takePhoto() {
    shutterReleased.send()
  }

  private func savePhoto(_ photo: UIImage) {
//    UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
    DispatchQueue.main.async { [self] in
//      passportPhoto = photo
        detectedImage = photo
        self.launchDetection(image: detectedImage!)
        self.isDetected = true
        self.isTaken = true
    }
      
  }
}

// MARK: Private instance methods

extension CameraViewModel {
  func invalidateFaceGeometryState() {
    isAcceptableRoll = false
    isAcceptablePitch = false
    isAcceptableYaw = false
    isAcceptableBounds = .unknown
  }

  func processUpdatedFaceGeometry() {
    switch faceGeometryState {
    case .faceNotFound:
      invalidateFaceGeometryState()
    case .errored(let error):
      print(error.localizedDescription)
      invalidateFaceGeometryState()
    case .faceFound(let faceGeometryModel):
      let boundingBox = faceGeometryModel.boundingBox
      let roll = faceGeometryModel.roll.doubleValue
      let pitch = faceGeometryModel.pitch.doubleValue
      let yaw = faceGeometryModel.yaw.doubleValue

      updateAcceptableBounds(using: boundingBox)
      updateAcceptableRollPitchYaw(using: roll, pitch: pitch, yaw: yaw)
    }
  }

  func updateAcceptableBounds(using boundingBox: CGRect) {
    // First, check face is roughly the same size as the layout guide
    if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
      isAcceptableBounds = .detectedFaceTooLarge
    } else if boundingBox.width * 1.2 < faceLayoutGuideFrame.width {
      isAcceptableBounds = .detectedFaceTooSmall
    } else {
      // Next, check face is roughly centered in the frame
      if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
        isAcceptableBounds = .detectedFaceOffCentre
      } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
        isAcceptableBounds = .detectedFaceOffCentre
      } else {
        isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
      }
    }
  }

  func updateAcceptableRollPitchYaw(using roll: Double, pitch: Double, yaw: Double) {
    isAcceptableRoll = (roll > 1.2 && roll < 1.6)
    isAcceptablePitch = abs(CGFloat(pitch)) < 0.2
    isAcceptableYaw = abs(CGFloat(yaw)) < 0.15
  }

  func processUpdatedFaceQuality() {
    switch faceQualityState {
    case .faceNotFound:
      isAcceptableQuality = false
    case .errored(let error):
      print(error.localizedDescription)
      isAcceptableQuality = false
    case .faceFound(let faceQualityModel):
      if faceQualityModel.quality < 0.2 {
        isAcceptableQuality = false
      }

      isAcceptableQuality = true
    }
  }

  func calculateDetectedFaceValidity() {
    hasDetectedValidFace =
    isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
    isAcceptableRoll &&
    isAcceptablePitch &&
    isAcceptableYaw &&
    isAcceptableQuality
  }
    
    
   
    
    
    
    
}
