

import AVFoundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

protocol FaceDetectorDelegate: NSObjectProtocol {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
  func draw(image: CIImage)
}

class FaceDetector: NSObject {
  weak var viewDelegate: FaceDetectorDelegate?
  weak var model: CameraViewModel? {
    didSet {
      model?.shutterReleased.sink { completion in
        switch completion {
        case .finished:
          return
        case .failure(let error):
          print("Received error: \(error)")
        }
      } receiveValue: { _ in
        self.isCapturingPhoto = true
      }
      .store(in: &subscriptions)
    }
  }

  var sequenceHandler = VNSequenceRequestHandler()
  var isCapturingPhoto = false
  var currentFrameBuffer: CVImageBuffer?

  var subscriptions = Set<AnyCancellable>()

  let imageProcessingQueue = DispatchQueue(
    label: "Image Processing Queue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem
  )
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    if isCapturingPhoto {
      isCapturingPhoto = false

      savePassportPhoto(from: imageBuffer)
    }

    let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
    detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3

    let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
    detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2

    let detectSegmentationRequest = VNGeneratePersonSegmentationRequest(completionHandler: detectedSegmentationRequest)
    detectSegmentationRequest.qualityLevel = .balanced

    currentFrameBuffer = imageBuffer
    do {
      try sequenceHandler.perform(
        [detectFaceRectanglesRequest, detectCaptureQualityRequest, detectSegmentationRequest],
        on: imageBuffer,
        orientation: .leftMirrored)
    } catch {
      print(error.localizedDescription)
    }
  }
}

// MARK: - Private methods

extension FaceDetector {
  func detectedFaceRectangles(request: VNRequest, error: Error?) {
    guard let model = model, let viewDelegate = viewDelegate else {
      return
    }

    guard
      let results = request.results as? [VNFaceObservation],
      let result = results.first
    else {
      model.perform(action: .noFaceDetected)
      return
    }

    let convertedBoundingBox =
      viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)

    let faceObservationModel = FaceGeometryModel(
      boundingBox: convertedBoundingBox,
      roll: result.roll ?? 0,
      pitch: result.pitch ?? 0,
      yaw: result.yaw ?? 0
    )

    model.perform(action: .faceObservationDetected(faceObservationModel))
  }

  func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
    guard let model = model else {
      return
    }

    guard
      let results = request.results as? [VNFaceObservation],
      let result = results.first
    else {
      model.perform(action: .noFaceDetected)
      return
    }

    let faceQualityModel = FaceQualityModel(
      quality: result.faceCaptureQuality ?? 0
    )

    model.perform(action: .faceQualityObservationDetected(faceQualityModel))
  }

  func detectedSegmentationRequest(request: VNRequest, error: Error?) {
    guard
      let model = model,
      let results = request.results as? [VNPixelBufferObservation],
      let result = results.first,
      let currentFrameBuffer = currentFrameBuffer
    else {
      return
    }

    if model.hideBackgroundModeEnabled {
      let originalImage = CIImage(cvImageBuffer: currentFrameBuffer)
      let maskPixelBuffer = result.pixelBuffer
      let outputImage = removeBackgroundFrom(image: originalImage, using: maskPixelBuffer)
      viewDelegate?.draw(image: outputImage.oriented(.upMirrored))
    } else {
      let originalImage = CIImage(cvImageBuffer: currentFrameBuffer).oriented(.upMirrored)
      viewDelegate?.draw(image: originalImage)
    }
  }

  func savePassportPhoto(from pixelBuffer: CVPixelBuffer) {
    guard let model = model else {
      return
    }

    imageProcessingQueue.async { [self] in
      let originalImage = CIImage(cvPixelBuffer: pixelBuffer)
      var outputImage = originalImage

      if model.hideBackgroundModeEnabled {
        let detectSegmentationRequest = VNGeneratePersonSegmentationRequest()
        detectSegmentationRequest.qualityLevel = .accurate

        try? sequenceHandler.perform(
          [detectSegmentationRequest],
          on: pixelBuffer,
          orientation: .leftMirrored
        )

        if let maskPixelBuffer = detectSegmentationRequest.results?.first?.pixelBuffer {
          outputImage = removeBackgroundFrom(image: originalImage, using: maskPixelBuffer)
        }
      }


      let coreImageWidth = outputImage.extent.width
      let coreImageHeight = outputImage.extent.height

      let desiredImageHeight = coreImageWidth * 4 / 3

      // Calculate frame of photo
      let yOrigin = (coreImageHeight - desiredImageHeight) / 2
//      let photoRect = CGRect(x: 0, y: yOrigin, width: coreImageWidth, height: desiredImageHeight)

      let context = CIContext()
//        let ciContext = CIContext(options: nil)
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
        let passportPhoto = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)

        DispatchQueue.main.async {
          model.perform(action: .savePhoto(passportPhoto))
        }
      }
    }
  }

  func removeBackgroundFrom(image: CIImage, using maskPixelBuffer: CVPixelBuffer) -> CIImage {
    var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

    let originalImage = image.oriented(.right)

    // Scale the mask image to fit the bounds of the video frame.
    let scaleX = originalImage.extent.width / maskImage.extent.width
    let scaleY = originalImage.extent.height / maskImage.extent.height
    maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY)).oriented(.upMirrored)

    let backgroundImage = CIImage(color: .white).clampedToExtent().cropped(to: originalImage.extent)

    let blendFilter = CIFilter.blendWithRedMask()
    blendFilter.inputImage = originalImage
    blendFilter.backgroundImage = backgroundImage
    blendFilter.maskImage = maskImage

    if let outputImage = blendFilter.outputImage?.oriented(.left) {
      return outputImage
    }

    return originalImage
  }
}
