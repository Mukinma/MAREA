import Foundation

struct NearbyPlace {
  let id: String
  let route: String
  let title: String
  let latitude: Double
  let longitude: Double
  let expiresAt: Date?
  var kind: String { route.hasPrefix("/missions/") ? "mission" : "marker" }

  init?(_ fields: [String: Any]) {
    guard fields["exact"] as? Bool == true, let id = fields["id"] as? String,
          UUID(uuidString: id) != nil, let route = fields["route"] as? String,
          route == "/missions/\(id)" || route == "/ar-markers/\(id)/scan",
          let title = fields["title"] as? String,
          !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          let latitude = fields["latitude"] as? Double,
          let longitude = fields["longitude"] as? Double,
          (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
    self.id = id
    self.route = route
    self.title = String(title.prefix(120))
    self.latitude = latitude
    self.longitude = longitude
    if let raw = fields["expiresAt"] {
      guard let milliseconds = raw as? NSNumber else { return nil }
      expiresAt = Date(timeIntervalSince1970: milliseconds.doubleValue / 1000)
    } else {
      expiresAt = nil
    }
  }
}

struct ProximityDetector {
  private var inside = Set<String>()
  private var lastAlert: [String: Date] = [:]
  private var lastFix: Date?

  mutating func entries(places: [NearbyPlace], latitude: Double, longitude: Double,
                        accuracy: Double, timestamp: Date, now: Date) -> [NearbyPlace] {
    let age = now.timeIntervalSince(timestamp)
    guard (-90...90).contains(latitude), (-180...180).contains(longitude),
          (0...20).contains(accuracy), (0...30).contains(age),
          lastFix.map({ timestamp >= $0 }) ?? true else { return [] }
    lastFix = timestamp
    var entries = [NearbyPlace]()
    for place in places where place.expiresAt.map({ now < $0 }) ?? true {
      let meters = Self.distance(latitude, longitude, place.latitude, place.longitude)
      if meters >= 30 - 1e-7 {
        inside.remove(place.route)
      } else if meters <= 20 + 1e-7, inside.insert(place.route).inserted,
                lastAlert[place.route].map({ now.timeIntervalSince($0) >= 300 }) ?? true {
        lastAlert[place.route] = now
        entries.append(place)
      }
    }
    return entries
  }

  private static func distance(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
    let radians = Double.pi / 180
    let h = pow(sin((c - a) * radians / 2), 2)
      + cos(a * radians) * cos(c * radians) * pow(sin((d - b) * radians / 2), 2)
    return 6_371_000 * 2 * asin(sqrt(min(1, max(0, h))))
  }
}
