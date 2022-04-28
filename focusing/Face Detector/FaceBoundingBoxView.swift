

import SwiftUI

struct FaceBoundingBoxView: View {
  @ObservedObject private(set) var model: CameraViewModel

  var body: some View {
    switch model.faceGeometryState {
    case .faceNotFound:
      Rectangle().fill(Color.clear)
    case .faceFound(let faceGeometryModel):
      Rectangle()
        .path(in: CGRect(
          x: faceGeometryModel.boundingBox.origin.x,
          y: faceGeometryModel.boundingBox.origin.y,
          width: faceGeometryModel.boundingBox.width,
          height: faceGeometryModel.boundingBox.height
        ))
        .stroke(Color("tangerine"), lineWidth: 1)
    case .errored:
      Rectangle().fill(Color.clear)
    }
  }
}

struct FaceBoundingBoxView_Previews: PreviewProvider {
  static var previews: some View {
    FaceBoundingBoxView(model: CameraViewModel())
  }
}
