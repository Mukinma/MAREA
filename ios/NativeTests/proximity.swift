import Foundation

@main
enum ProximityChecks {
  static func main() {
    let id = "33333333-3333-4333-8333-333333333333"
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let fields: [String: Any] = ["id": id, "title": "QA", "route": "/missions/\(id)",
                                  "exact": true, "latitude": 0.0, "longitude": 0.0]
    let mission = NearbyPlace(fields)!
    let marker = NearbyPlace(fields.merging(["route": "/ar-markers/\(id)/scan"]) { _, new in new })!
    for changes: [String: Any] in [["exact": false], ["route": "https://invalid.test"], ["latitude": Double.nan],
                                   ["id": UUID().uuidString], ["expiresAt": "invalid"]] {
      precondition(NearbyPlace(fields.merging(changes) { _, new in new }) == nil)
    }
    let expired = NearbyPlace(fields.merging(["expiresAt": now.timeIntervalSince1970 * 1000]) { _, v in v })!
    var detector = ProximityDetector()
    func check(_ meters: Double, _ offset: TimeInterval, accuracy: Double = 1, age: Double = 0,
               targets: [NearbyPlace] = []) -> [String] {
      let time = now.addingTimeInterval(offset)
      return detector.entries(places: targets.isEmpty ? [mission, marker, mission] : targets,
                              latitude: meters / 6_371_000 * 180 / .pi, longitude: 0,
                              accuracy: accuracy, timestamp: time.addingTimeInterval(-age), now: time).map(\.kind)
    }
    precondition(check(0, 0, targets: [expired]).isEmpty)
    precondition(check(0, 1, accuracy: 20.001).isEmpty)
    precondition(check(0, 1, accuracy: -1).isEmpty)
    precondition(check(0, 1, age: 31).isEmpty)
    precondition(check(0, 1, age: -1).isEmpty)
    precondition(check(20.01, 1).isEmpty)
    precondition(check(20, 2, accuracy: 20) == ["mission", "marker"])
    precondition(check(31, 1).isEmpty) // out-of-order exit cannot re-arm
    precondition(check(0, 305).isEmpty)
    precondition(check(29.99, 306).isEmpty)
    precondition(check(0, 307).isEmpty)
    precondition(check(30, 308).isEmpty)
    precondition(check(19.99, 309) == ["mission", "marker"])
    precondition(check(31, 310).isEmpty)
    precondition(check(0, 311).isEmpty)
    print("Proximity detector passed on \(ProcessInfo.processInfo.operatingSystemVersionString)")
  }
}
