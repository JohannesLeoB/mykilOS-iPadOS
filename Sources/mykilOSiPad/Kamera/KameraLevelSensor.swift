import CoreMotion
import Observation

/// Live-Neigungsmessung für den „Geradehalten"-Assistenten der Kamera.
/// Reine on-device CoreMotion-Messung (kein Netzwerk, keine Info.plist-
/// Berechtigung für den reinen Beschleunigungssensor nötig). 1:1 aus
/// mykilOS iOS (`KameraLevelSensor.swift`) übernommen: interpretiert Roll &
/// Pitch relativ zur *aufrechten Foto-Haltung* (Gerät senkrecht, Rückkamera
/// nach vorn) und meldet, ob die Senkrechten im Bild wirklich senkrecht stehen.
@MainActor
@Observable
final class KameraLevelSensor {
    /// Seitliche Verkippung (Roll) in Grad. 0 = Gerät exakt waagerecht gehalten.
    private(set) var rollGrad: Double = 0
    /// Vor/Zurück-Neigung (Pitch) gegenüber der Senkrechten in Grad.
    /// 0 = Gerät exakt senkrecht (Bildebene lotrecht → Senkrechte bleiben senkrecht).
    private(set) var neigungGrad: Double = 0
    private(set) var verfuegbar = true

    /// Toleranz in Grad, innerhalb derer „sauber ausgerichtet" gilt.
    let toleranz: Double = 2.5

    /// true, wenn Roll UND Pitch innerhalb der Toleranz liegen.
    var ausgerichtet: Bool {
        abs(rollGrad) <= toleranz && abs(neigungGrad) <= toleranz
    }

    private let motionManager = CMMotionManager()

    func starten() {
        guard motionManager.isDeviceMotionAvailable else {
            verfuegbar = false
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.rollGrad = data.attitude.roll * 180 / .pi
            // Pitch relativ zur senkrechten Haltung: beim aufrechten Fotografieren
            // liegt der rohe Pitch bei ~+90°; wir ziehen 90° ab, damit 0° =
            // „Gerät senkrecht, Bildebene lotrecht" bedeutet.
            self.neigungGrad = data.attitude.pitch * 180 / .pi - 90
        }
    }

    func stoppen() {
        motionManager.stopDeviceMotionUpdates()
    }
}
