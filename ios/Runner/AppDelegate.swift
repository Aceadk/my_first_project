import AdSupport
import AppTrackingTransparency
import AVFAudio
import AVFoundation
import CallKit
import Flutter
import UIKit

final class ScreenCaptureStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }

  @objc private func handleScreenshot() {
    guard let sink = eventSink else { return }
    sink([
      "type": "screenshot",
      "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
    ])
  }

  @objc private func handleCaptureChanged() {
    guard let sink = eventSink else { return }
    let isCaptured = UIScreen.main.isCaptured
    sink([
      "type": isCaptured ? "recording_started" : "recording_stopped",
      "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
    ])
  }
}

final class CallKitCoordinator: NSObject, CXProviderDelegate {
  private let provider: CXProvider
  private let callController = CXCallController()
  private var eventSink: FlutterEventSink?
  private var pendingEvents: [[String: Any]] = []

  private var uuidByCallId: [String: UUID] = [:]
  private var metadataByCallId: [String: [String: Any]] = [:]
  private var answeredCallIds: Set<String> = []

  override init() {
    let config = CXProviderConfiguration(localizedName: "Crush")
    config.supportsVideo = true
    config.includesCallsInRecents = true
    config.maximumCallGroups = 1
    config.maximumCallsPerCallGroup = 1
    config.supportedHandleTypes = [.generic]
    provider = CXProvider(configuration: config)
    super.init()
    provider.setDelegate(self, queue: nil)
  }

  func setEventSink(_ sink: FlutterEventSink?) {
    eventSink = sink
    guard sink != nil, !pendingEvents.isEmpty else { return }
    let queued = pendingEvents
    pendingEvents.removeAll()
    queued.forEach { emit($0) }
  }

  func reportIncomingCall(payload: [String: Any]) {
    var normalized = payload
    let callId = normalizedString(normalized["callId"])
      ?? "incoming_\(Int(Date().timeIntervalSince1970 * 1000))"
    let callerId = normalizedString(normalized["callerId"]) ?? "unknown"
    let callerName = normalizedString(normalized["callerName"]) ?? callerId
    let isVideo = parseBool(normalized["isVideoCall"])
      || normalizedString(normalized["callType"])?.lowercased() == "video"

    normalized["callId"] = callId
    normalized["callerId"] = callerId
    normalized["callerName"] = callerName
    normalized["isVideoCall"] = isVideo
    metadataByCallId[callId] = normalized

    let uuid = uuidByCallId[callId] ?? UUID()
    uuidByCallId[callId] = uuid

    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = isVideo
    update.supportsDTMF = false
    update.supportsHolding = false
    update.supportsGrouping = false
    update.supportsUngrouping = false

    provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
      guard let self else { return }
      if let error {
        self.emit([
          "type": "incoming_report_failed",
          "callId": callId,
          "error": error.localizedDescription,
          "payload": normalized,
        ])
        return
      }
      self.emit([
        "type": "incoming_reported",
        "callId": callId,
        "payload": normalized,
      ])
    }
  }

  func requestEndCall(callId: String, reason: String = "ended") {
    guard let uuid = uuidByCallId[callId] else { return }
    let action = CXEndCallAction(call: uuid)
    let transaction = CXTransaction(action: action)
    callController.request(transaction) { [weak self] error in
      guard let self else { return }
      if let error {
        self.emit([
          "type": "end_request_failed",
          "callId": callId,
          "reason": reason,
          "error": error.localizedDescription,
        ])
      }
    }
  }

  func requestMute(callId: String, isMuted: Bool) {
    guard let uuid = uuidByCallId[callId] else { return }
    let action = CXSetMutedCallAction(call: uuid, muted: isMuted)
    let transaction = CXTransaction(action: action)
    callController.request(transaction) { [weak self] error in
      guard let self else { return }
      if let error {
        self.emit([
          "type": "mute_request_failed",
          "callId": callId,
          "isMuted": isMuted,
          "error": error.localizedDescription,
        ])
      }
    }
  }

  func handleRemoteIncomingPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
    let type = normalizedString(userInfo["type"])?.lowercased()
    guard type == "incoming_call" || type == "call" else { return false }

    var payload: [String: Any] = [:]
    userInfo.forEach { key, value in
      payload[String(describing: key)] = value
    }

    reportIncomingCall(payload: payload)
    return true
  }

  func providerDidReset(_ provider: CXProvider) {
    uuidByCallId.removeAll()
    metadataByCallId.removeAll()
    answeredCallIds.removeAll()
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    guard let callId = callId(for: action.callUUID) else {
      action.fail()
      return
    }
    answeredCallIds.insert(callId)
    emit([
      "type": "answered",
      "callId": callId,
      "payload": payload(for: callId) ?? [:],
    ])
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    guard let callId = callId(for: action.callUUID) else {
      action.fail()
      return
    }
    let eventType = answeredCallIds.contains(callId) ? "ended" : "declined"
    answeredCallIds.remove(callId)
    emit([
      "type": eventType,
      "callId": callId,
      "payload": payload(for: callId) ?? [:],
    ])
    removeCallState(callId: callId)
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
    guard let callId = callId(for: action.callUUID) else {
      action.fail()
      return
    }
    emit([
      "type": "muted_changed",
      "callId": callId,
      "isMuted": action.isMuted,
      "payload": payload(for: callId) ?? [:],
    ])
    action.fulfill()
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    do {
      try audioSession.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers]
      )
      try audioSession.setActive(true)
    } catch {
      emit([
        "type": "audio_activate_failed",
        "error": error.localizedDescription,
      ])
      return
    }
    emit(["type": "audio_activated"])
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    do {
      try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    } catch {
      emit([
        "type": "audio_deactivate_failed",
        "error": error.localizedDescription,
      ])
      return
    }
    emit(["type": "audio_deactivated"])
  }

  private func emit(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let sink = self.eventSink {
        sink(payload)
      } else {
        self.pendingEvents.append(payload)
      }
    }
  }

  private func removeCallState(callId: String) {
    uuidByCallId[callId] = nil
    metadataByCallId[callId] = nil
    answeredCallIds.remove(callId)
  }

  private func callId(for uuid: UUID) -> String? {
    uuidByCallId.first { $0.value == uuid }?.key
  }

  private func payload(for callId: String) -> [String: Any]? {
    metadataByCallId[callId]
  }

  private func normalizedString(_ value: Any?) -> String? {
    guard let raw = value as? String else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func parseBool(_ value: Any?) -> Bool {
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let stringValue = value as? String {
      let lowered = stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return lowered == "true" || lowered == "1" || lowered == "yes"
    }
    if let number = value as? NSNumber {
      return number.boolValue
    }
    return false
  }
}

final class CallKitEventStreamHandler: NSObject, FlutterStreamHandler {
  private let coordinator: CallKitCoordinator

  init(coordinator: CallKitCoordinator) {
    self.coordinator = coordinator
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    coordinator.setEventSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    coordinator.setEventSink(nil)
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let screenCaptureHandler = ScreenCaptureStreamHandler()
  private let callKitCoordinator = CallKitCoordinator()
  private lazy var callKitEventHandler = CallKitEventStreamHandler(
    coordinator: callKitCoordinator
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    configureFlutterChannels(binaryMessenger: engineBridge.applicationRegistrar.messenger())
  }

  private func configureFlutterChannels(binaryMessenger: FlutterBinaryMessenger) {
    let screenCaptureChannel = FlutterEventChannel(
      name: "crushhour/screen_capture_events",
      binaryMessenger: binaryMessenger
    )
    screenCaptureChannel.setStreamHandler(screenCaptureHandler)

    let callKitMethodChannel = FlutterMethodChannel(
      name: "crushhour/callkit",
      binaryMessenger: binaryMessenger
    )
    callKitMethodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "callkit_unavailable",
            message: "CallKit coordinator unavailable.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "showIncomingCall":
        guard let args = call.arguments as? [String: Any] else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "showIncomingCall requires payload map.",
              details: nil
            )
          )
          return
        }
        self.callKitCoordinator.reportIncomingCall(payload: args)
        result(true)
      case "endCall":
        guard
          let args = call.arguments as? [String: Any],
          let callId = args["callId"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "endCall requires callId.",
              details: nil
            )
          )
          return
        }
        let reason = args["reason"] as? String ?? "ended"
        self.callKitCoordinator.requestEndCall(callId: callId, reason: reason)
        result(true)
      case "setMuted":
        guard
          let args = call.arguments as? [String: Any],
          let callId = args["callId"] as? String,
          let isMuted = args["isMuted"] as? Bool
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "setMuted requires callId and isMuted.",
              details: nil
            )
          )
          return
        }
        self.callKitCoordinator.requestMute(callId: callId, isMuted: isMuted)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let callKitEventChannel = FlutterEventChannel(
      name: "crushhour/callkit_events",
      binaryMessenger: binaryMessenger
    )
    callKitEventChannel.setStreamHandler(callKitEventHandler)

    let permissionChannel = FlutterMethodChannel(
      name: "crushhour/native_permissions",
      binaryMessenger: binaryMessenger
    )
    permissionChannel.setMethodCallHandler { [weak self] call, result in
      self?.handlePermissionCall(call, result: result)
    }

    let trackingChannel = FlutterMethodChannel(
      name: "app_tracking_transparency",
      binaryMessenger: binaryMessenger
    )
    trackingChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleTrackingCall(call, result: result)
    }
  }

  private func handlePermissionCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let permission = args["permission"] as? String,
      let mediaType = mediaType(for: permission)
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "Permission call requires camera or microphone permission.",
          details: nil
        )
      )
      return
    }

    switch call.method {
    case "hasPermission":
      result(AVCaptureDevice.authorizationStatus(for: mediaType) == .authorized)
    case "requestPermission":
      requestMediaAccess(mediaType: mediaType, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func mediaType(for permission: String) -> AVMediaType? {
    switch permission {
    case "camera":
      return .video
    case "microphone":
      return .audio
    default:
      return nil
    }
  }

  private func requestMediaAccess(mediaType: AVMediaType, result: @escaping FlutterResult) {
    switch AVCaptureDevice.authorizationStatus(for: mediaType) {
    case .authorized:
      result(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    case .denied, .restricted:
      result(false)
    @unknown default:
      result(false)
    }
  }

  private func handleTrackingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      switch call.method {
      case "getTrackingAuthorizationStatus":
        result(Int(ATTrackingManager.trackingAuthorizationStatus.rawValue))
      case "requestTrackingAuthorization":
        ATTrackingManager.requestTrackingAuthorization { status in
          DispatchQueue.main.async {
            result(Int(status.rawValue))
          }
        }
      case "getAdvertisingIdentifier":
        result(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
      default:
        result(FlutterMethodNotImplemented)
      }
      return
    }

    switch call.method {
    case "getTrackingAuthorizationStatus", "requestTrackingAuthorization":
      result(4)
    case "getAdvertisingIdentifier":
      result("")
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if callKitCoordinator.handleRemoteIncomingPayload(userInfo) {
      completionHandler(.newData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}
