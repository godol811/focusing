//
//  StyleForm.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//
import SwiftUI
import AVFoundation

struct Bold : ViewModifier{
    
    var size = 15
   

    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-Bold", size: CGFloat(size)))
            
    }
}

struct ExtraBold : ViewModifier{
    
    var size = 15
   
    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-ExtraBold", size: CGFloat(size)))
            
    }
}

struct ExtraLight : ViewModifier{
    
    var size = 15
    
    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-ExtraLight", size: CGFloat(size)))
    }
}
struct Heavy : ViewModifier{
    
    var size = 15
   
    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-Heavy", size: CGFloat(size)))
            
    }
}

struct Light : ViewModifier{
    
    var size = 15
   

    func body(content: Content) -> some View {
        
        content
            .font(.custom("SUIT-Light", size: CGFloat(size)))
            
    }
}

struct Medium : ViewModifier{
    
    var size = 15
   

    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-Medium", size: CGFloat(size)))
            
    }
}

struct Regular : ViewModifier{
    
    var size = 15
    
    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-Regular", size: CGFloat(size)))
    }
}
struct SemiBold : ViewModifier{
    
    var size = 15
   

    func body(content: Content) -> some View {
        content
            .font(.custom("SUIT-SemiBold", size: CGFloat(size)))
            
    }
}

struct Thin : ViewModifier{
    
    var size = 15
   

    func body(content: Content) -> some View {
        
        content
            .font(.custom("SUIT-Thin", size: CGFloat(size)))
            
    }
}

func determineScale(cgImage: CGImage, imageViewFrame:CGRect) -> CGRect{
    let originalWidth = CGFloat(cgImage.width)
    let originalHeight = CGFloat(cgImage.height)
    
    let imageFrame = imageViewFrame
    let widthRatio = originalWidth / imageFrame.width
    let heightRatio = originalHeight / imageFrame.height
    
    let scaleRatio = max(widthRatio, heightRatio)
    
    let scaledImageWidth = originalWidth / scaleRatio
    let scaledImageHeight = originalHeight / scaleRatio
    
    let scaledImageX = (imageFrame.width - scaledImageWidth) / 2
    let scaledImageY = (imageFrame.height - scaledImageHeight) / 2
    
    return CGRect(x: scaledImageX, y: scaledImageY, width : scaledImageWidth, height: scaledImageHeight)
}

func convertUnitToPoint(originalImageRect: CGRect, targetRect: CGRect) -> CGRect {
    var pointRect = targetRect
    
    pointRect.origin.x = originalImageRect.origin.x + (targetRect.origin.x * originalImageRect.size.width)
    pointRect.origin.y = originalImageRect.origin.y + (1 - targetRect.origin.y - targetRect.height) * originalImageRect.size.height
    pointRect.size.width *= originalImageRect.size.width
    pointRect.size.height *= originalImageRect.size.height
    
    
    return pointRect
}
extension UIImage {
    
    func coreOrientation() -> CGImagePropertyOrientation {
        switch imageOrientation {
        case .up : return .up
        case .upMirrored: return .upMirrored
        case .down: return .down // 0th row at bottom, 0th column on right  - 180 deg rotation
        case .downMirrored : return .downMirrored// 0th row at bottom, 0th column on left   - vertical flip
        case .leftMirrored : return .leftMirrored // 0th row on left,   0th column at top
        case .right : return .right // 0th row on right,  0th column at top    - 90 deg CW
        case .rightMirrored : return .rightMirrored // 0th row on right,  0th column on bottom
        case .left : return .left // 0th row on left,   0th column at bottom - 90 deg CCW
        @unknown default:
            fatalError()
        }
    }
}

struct ShutterButton: View {
  let isDisabled: Bool
    
    
  let action: (() -> Void)

  var body: some View {
    Button(action: {
      action()
    }, label: {
        Image("Capture")
            .resizable()
            .frame(width: 64, height: 64, alignment: .center)
            .padding(.top, 22)
    })
      .disabled(isDisabled)
      .tint(.white)
  }
}
struct AppStorageKeys {
    static let stars = "stars"
    
}
// Check when the sound setting is on.
func playSound(file: String , ext: String) -> Void {
    var audioPlayer = AVAudioPlayer()
        do{
            let url = URL.init(fileURLWithPath: Bundle.main.path(forResource: file, ofType: ext) ?? "mp3")
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        }catch let error{
            NSLog(error.localizedDescription)
        }
    
}
