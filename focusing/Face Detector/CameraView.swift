

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
  typealias UIViewControllerType = CameraViewController

  private(set) var model: CameraViewModel

  func makeUIViewController(context: Context) -> CameraViewController {
    let faceDetector = FaceDetector()
    faceDetector.model = model

    let viewController = CameraViewController()
    viewController.faceDetector = faceDetector

    return viewController
  }

  func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}
