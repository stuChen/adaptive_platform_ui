import Flutter
import UIKit

class iOS26ModalBarrierFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26ModalBarrierPlatformView(frame: frame, arguments: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class iOS26ModalBarrierPlatformView: NSObject, FlutterPlatformView {
    private let container: UIView

    init(frame: CGRect, arguments args: Any?) {
        container = UIView(frame: frame)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.isUserInteractionEnabled = false

        if let params = args as? [String: Any],
           let colorValue = params["color"] as? NSNumber {
            container.backgroundColor = Self.colorFromARGB(colorValue.intValue)
        } else {
            container.backgroundColor = .clear
        }

        super.init()
    }

    func view() -> UIView {
        return container
    }

    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xff) / 255.0
        let r = CGFloat((argb >> 16) & 0xff) / 255.0
        let g = CGFloat((argb >> 8) & 0xff) / 255.0
        let b = CGFloat(argb & 0xff) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
