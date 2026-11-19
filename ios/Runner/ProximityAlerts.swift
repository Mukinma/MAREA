import CoreLocation
import Flutter
import UIKit
import UserNotifications

/// The authenticated Flutter session owns the target snapshot. Only its opt-in
/// survives a process restart. Location fixes are never written to disk.
final class ProximityAlerts: NSObject, CLLocationManagerDelegate {
  static let shared = ProximityAlerts()
  static let payloadKey = "marea.proximity.payload"
  static let prefix = "marea.proximity."
  private let ownerKey = "marea.proximity.owner"
  private let postedKey = "marea.proximity.posted"
  private let backgroundKey = "marea.proximity.background"
  private let defaults = UserDefaults.standard
  private let center = UNUserNotificationCenter.current()
  private lazy var location: CLLocationManager = {
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = 3
    manager.delegate = self
    return manager
  }()
  private var channel: FlutterMethodChannel?
  private var account: String?
  private var places = [NearbyPlace]()
  private var detector = ProximityDetector()
  private var generation = 0
  private var running = false
  private var foreground = false
  private var pending: String?
  private var observers = [NSObjectProtocol]()
  private var permissionToNotify = false
  private var enabled: Bool { account != nil && defaults.string(forKey: ownerKey) == account }
  private var precise: Bool {
    (location.authorizationStatus == .authorizedAlways || location.authorizationStatus == .authorizedWhenInUse)
      && location.accuracyAuthorization == .fullAccuracy
  }
  private var always: Bool { location.authorizationStatus == .authorizedAlways }

  func register(_ registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "marea/proximity_background", binaryMessenger: registrar.messenger())
    channel?.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    if observers.isEmpty {
      observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
        object: nil, queue: .main) { [weak self] _ in
          self?.foreground = false
          self?.reconcile()
        })
      observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
        object: nil, queue: .main) { [weak self] _ in
          self?.foreground = true
          self?.checkNotifications { self?.reconcile() }
        })
    }
  }

  func opened(_ response: UNNotificationResponse) {
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
          let raw = response.notification.request.content.userInfo[Self.payloadKey] as? String else { return }
    pending = raw
    channel?.invokeMethod("pendingAvailable", arguments: nil)
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "bindAccount":
      let next = args["accountId"] as? String
      if (account != nil && account != next) ||
         (defaults.string(forKey: ownerKey).map { $0 != next } ?? false) || next == nil {
        reset()
      }
      account = next.flatMap { UUID(uuidString: $0) == nil ? nil : $0 }
      foreground = args["foreground"] as? Bool == true
      checkNotifications { self.reconcile(); result(nil) }
    case "status":
      checkNotifications {
        self.reconcile()
        result(["supported": true, "ios": true, "enabled": self.enabled, "running": self.running,
                "accountId": self.account as Any?, "count": self.places.count, "precise": self.precise,
                "always": self.always, "notifications": self.permissionToNotify])
      }
    case "requestNotifications":
      center.requestAuthorization(options: [.alert, .sound]) { _, error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(code: "notification_permission", message: error.localizedDescription, details: nil))
          } else { result(nil) }
        }
      }
    case "requestBackground":
      if enabled && location.authorizationStatus == .authorizedWhenInUse {
        location.requestAlwaysAuthorization()
      }
      result(nil)
    case "start", "updateTargets":
      guard let owner = args["accountId"] as? String, account == owner,
            call.method == "start" || enabled,
            let rows = args["targets"] as? [[String: Any]] else {
        result(FlutterError(code: "invalid_session", message: "La sesión cambió.", details: nil))
        return
      }
      let targets = rows.compactMap(NearbyPlace.init)
      guard targets.count == rows.count else {
        result(FlutterError(code: "invalid_place", message: "Lugar no válido.", details: nil))
        return
      }
      let token = generation
      checkNotifications {
        guard self.generation == token, self.account == owner, self.permissionToNotify, self.precise,
              call.method == "start" || self.enabled else {
          result(FlutterError(code: "permissions_required", message: "Revisa tus permisos de ubicación y avisos.", details: nil))
          return
        }
        self.places = targets
        self.clearObsoleteAlerts(owner: owner, targets: targets)
        self.defaults.set(owner, forKey: self.ownerKey)
        self.defaults.set(self.always, forKey: self.backgroundKey)
        self.reconcile()
        result(nil)
      }
    case "stop":
      reset()
      result(nil)
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)
    case "takeLaunchPayload":
      result(pending)
      pending = nil
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func checkNotifications(_ completion: @escaping () -> Void) {
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.permissionToNotify = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
          && settings.alertSetting == .enabled
        completion()
      }
    }
  }

  private func reconcile() {
    guard enabled else { return }
    guard precise, permissionToNotify, !defaults.bool(forKey: backgroundKey) || always else {
      reset()
      return
    }
    if always { defaults.set(true, forKey: backgroundKey) }
    if foreground || always {
      location.allowsBackgroundLocationUpdates = always
      location.showsBackgroundLocationIndicator = always
      if !running && foreground {
        running = true
        location.startUpdatingLocation()
      }
    } else {
      running = false
      location.stopUpdatingLocation()
    }
  }

  private func reset() {
    generation += 1
    if running { location.stopUpdatingLocation() }
    running = false
    places = []
    pending = nil
    detector = ProximityDetector()
    defaults.removeObject(forKey: ownerKey)
    defaults.removeObject(forKey: backgroundKey)
    removeAlerts(defaults.stringArray(forKey: postedKey) ?? [])
    defaults.removeObject(forKey: postedKey)
  }

  private func removeAlerts(_ ids: [String]) {
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
  }

  private func identifier(owner: String, route: String) -> String { "\(Self.prefix)\(owner)\(route)" }

  private func clearObsoleteAlerts(owner: String, targets: [NearbyPlace]) {
    let keep = Set(targets.map { identifier(owner: owner, route: $0.route) })
    let posted = Set(defaults.stringArray(forKey: postedKey) ?? [])
    removeAlerts(Array(posted.subtracting(keep)))
    defaults.set(Array(posted.intersection(keep)), forKey: postedKey)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // A notification settings read may be pending immediately after a cold bind.
    checkNotifications { self.reconcile() }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let error = error as? CLError, error.code == .denied { reset() }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard running, enabled, let owner = account, let fix = locations.last else { return }
    let token = generation
    checkNotifications {
      self.reconcile()
      guard self.generation == token, self.running, self.enabled, self.account == owner else { return }
      let entries = self.detector.entries(places: self.places, latitude: fix.coordinate.latitude,
        longitude: fix.coordinate.longitude, accuracy: fix.horizontalAccuracy,
        timestamp: fix.timestamp, now: Date())
      for place in entries { self.post(place, owner: owner, token: token) }
    }
  }

  private func post(_ place: NearbyPlace, owner: String, token: Int) {
    let data: [String: Any] = ["type": "proximity", "version": 1, "recipient_id": owner,
                               "target_id": place.id, "target_kind": place.kind, "route": place.route]
    guard let bytes = try? JSONSerialization.data(withJSONObject: data),
          let payload = String(data: bytes, encoding: .utf8) else { return }
    let content = UNMutableNotificationContent()
    content.title = "Estás cerca de \(place.title)"
    content.body = place.kind == "mission" ? "Hay una misión a 20 metros o menos." : "Hay una experiencia RA a 20 metros o menos."
    content.sound = .default
    content.userInfo = [Self.payloadKey: payload]
    let id = identifier(owner: owner, route: place.route)
    var posted = Set(defaults.stringArray(forKey: postedKey) ?? [])
    posted.insert(id)
    defaults.set(Array(posted), forKey: postedKey)
    center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) { _ in
      DispatchQueue.main.async {
        if self.generation != token || !self.places.contains(where: { $0.route == place.route }) {
          self.removeAlerts([id])
        }
      }
    }
  }
}
