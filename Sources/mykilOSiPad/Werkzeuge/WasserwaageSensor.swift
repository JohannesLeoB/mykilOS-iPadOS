import CoreMotion
import Observation

/// Reine on-device Neigungsmessung (CoreMotion, kein Netzwerk). Der
/// Beschleunigungs-/Bewegungssensor ist — anders als Standort/Kamera/Mikrofon —
/// ohne Consent-Dialog nutzbar. Portiert aus mykilOS iOS (`WasserwaageSensor`),
/// unverändert, weil rein sensorbasiert.
@MainActor
@Observable
final class WasserwaageSensor {
    private(set) var neigungGrad: Double = 0   // Vorne/Hinten (Pitch)
    private(set) var rollGrad: Double = 0      // Links/Rechts (Roll)
    private(set) var verfuegbar = true

    private let motionManager = CMMotionManager()

    func starten() {
        guard motionManager.isDeviceMotionAvailable else {
            verfuegbar = false
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.neigungGrad = data.attitude.pitch * 180 / .pi
            self.rollGrad = data.attitude.roll * 180 / .pi
        }
    }

    func stoppen() {
        motionManager.stopDeviceMotionUpdates()
    }
}
