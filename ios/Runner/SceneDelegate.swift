import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
    if let response = connectionOptions.notificationResponse,
       response.notification.request.identifier.hasPrefix(ProximityAlerts.prefix) {
      ProximityAlerts.shared.opened(response)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

}
