import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VcamGalleryPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(name: "com.example.vcam/gallery", binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "saveToPhotos" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Path is missing", details: nil))
          return
        }

        let fileUrl = URL(fileURLWithPath: filePath)
        let saveAction = {
          PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: fileUrl, options: nil)
          }) { success, error in
            DispatchQueue.main.async {
              if success {
                result(true)
              } else {
                result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
              }
            }
          }
        }

        if #available(iOS 14, *) {
          PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
              saveAction()
            } else {
              DispatchQueue.main.async {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Photos access denied", details: nil))
              }
            }
          }
        } else {
          PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
              saveAction()
            } else {
              DispatchQueue.main.async {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Photos access denied", details: nil))
              }
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
