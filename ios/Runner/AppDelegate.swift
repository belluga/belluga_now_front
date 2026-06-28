import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let deferredLinkChannelName = "com.belluga_now/deferred_link"
  // Keep this prefix aligned with the web promotion clipboard seeder.
  private static let deferredLinkClipboardPrefix = "belluga_now_deferred_link_v1:"
  private var deferredLinkPasteboardPayloadCache: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: Self.deferredLinkChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "getDeferredLinkPasteboardPayload":
          self?.handleDeferredLinkPasteboardPayload(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleDeferredLinkPasteboardPayload(result: @escaping FlutterResult) {
    if let cachedPayload = deferredLinkPasteboardPayloadCache {
      result([
        "resolver_payload": cachedPayload
      ])
      return
    }

    guard let rawPayload = UIPasteboard.general.string?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      rawPayload.hasPrefix(Self.deferredLinkClipboardPrefix)
    else {
      result(nil)
      return
    }

    let payload = String(rawPayload.dropFirst(Self.deferredLinkClipboardPrefix.count))
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if payload.isEmpty {
      result(nil)
      return
    }

    deferredLinkPasteboardPayloadCache = payload
    UIPasteboard.general.string = nil
    result([
      "resolver_payload": payload
    ])
  }
}
