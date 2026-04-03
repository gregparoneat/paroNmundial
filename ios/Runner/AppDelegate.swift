import UIKit
import Flutter

private let splashBackgroundColor = UIColor(
  red: 0.9647058824,
  green: 0.9647058824,
  blue: 0.9647058824,
  alpha: 1
)

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      controller.view.backgroundColor = splashBackgroundColor
    }
    window?.backgroundColor = splashBackgroundColor

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
