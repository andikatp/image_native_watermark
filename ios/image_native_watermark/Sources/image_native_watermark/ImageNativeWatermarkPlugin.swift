import Flutter
import UIKit
import CoreGraphics

public class ImageNativeWatermarkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_native_watermark", binaryMessenger: registrar.messenger())
        let instance = ImageNativeWatermarkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "processFrame" {
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let path = try self.processFrame(args: args)
                    DispatchQueue.main.async { result(path) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PROCESS_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func processFrame(args: [String: Any]) throws -> String {
        let flutterData = args["bytes"] as! FlutterStandardTypedData
        let bytes = flutterData.data
        let width = args["width"] as! Int
        let height = args["height"] as! Int
        let bytesPerRow = args["bytesPerRow"] as! Int
        let rotationAngle = args["rotationAngle"] as! Int
        let isFrontCamera = args["isFrontCamera"] as! Bool
        let watermarkText = args["watermarkText"] as! String
        let quality = args["quality"] as! Int
        let targetMaxWidth = args["targetMaxWidth"] as! Int
        let outputPath = args["outputPath"] as! String

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

        guard let provider = CGDataProvider(data: bytes as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw NSError(domain: "ImageNativeWatermark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
        }

        let orientation = imageOrientation(rotationAngle: rotationAngle, isFrontCamera: isFrontCamera)
        let orientedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)

        UIGraphicsBeginImageContextWithOptions(orientedImage.size, true, 1.0)
        orientedImage.draw(in: CGRect(origin: .zero, size: orientedImage.size))
        guard let normalized = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            throw NSError(domain: "ImageNativeWatermark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to normalize orientation"])
        }
        UIGraphicsEndImageContext()

        var finalSize = normalized.size
        if Int(finalSize.width) > targetMaxWidth {
            let scale = CGFloat(targetMaxWidth) / finalSize.width
            finalSize = CGSize(width: CGFloat(targetMaxWidth), height: finalSize.height * scale)
        }

        UIGraphicsBeginImageContextWithOptions(finalSize, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            throw NSError(domain: "ImageNativeWatermark", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
        }

        normalized.draw(in: CGRect(origin: .zero, size: finalSize))

        if !watermarkText.isEmpty {
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white,
            ]

            // 1. Trim leading spaces from each line, filter empties
            let lines = watermarkText.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if !lines.isEmpty {
                // 2. Calculate bounding box for the entire text block
                var maxLineWidth: CGFloat = 0
                var totalTextHeight: CGFloat = 0
                var lineHeights: [CGFloat] = []

                for line in lines {
                    let textSize = (line as NSString).size(withAttributes: textAttributes)
                    if textSize.width > maxLineWidth { maxLineWidth = textSize.width }
                    let lh = textSize.height
                    lineHeights.append(lh)
                    totalTextHeight += lh + 3 // 3 is line spacing
                }

                // 3. Define the single background rectangle
                let x: CGFloat = 40
                let yStart: CGFloat = finalSize.height * 0.7
                let bgPadding: CGFloat = 15

                ctx.setFillColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor)
                ctx.fill(CGRect(
                    x: x - bgPadding,
                    y: yStart - lineHeights[0] - bgPadding, // Start higher to account for first line height
                    width: maxLineWidth + bgPadding * 2,
                    height: totalTextHeight + bgPadding * 2 - 3 // Subtract last spacing
                ))

                // 4. Draw all text lines inside the rectangle (left aligned)
                var currentY = yStart - lineHeights[0]
                for (i, line) in lines.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: textAttributes)
                    currentY += lineHeights[i] + 3
                }
            }
        }

        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext(),
              let jpegData = finalImage.jpegData(compressionQuality: CGFloat(quality) / 100.0) else {
            UIGraphicsEndImageContext()
            throw NSError(domain: "ImageNativeWatermark", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JPEG"])
        }
        UIGraphicsEndImageContext()

        try jpegData.write(to: URL(fileURLWithPath: outputPath))
        return outputPath
    }

    private func imageOrientation(rotationAngle: Int, isFrontCamera: Bool) -> UIImage.Orientation {
        switch rotationAngle {
        case 90:
            return .right
        case 180:
            return .down
        case 270:
            return .left
        default:
            return .up
        }
    }
}
