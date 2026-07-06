import CoreLocation

/// Ein einzelner Standort-Schnappschuss für die EXIF-Beweiskette — kein
/// Dauer-Tracking, keine Bewegungsspur, nur ein Fixpunkt zur Aufnahmezeit.
/// 1:1 aus mykilOS iOS übernommen.
@MainActor
final class EinmaligerOrtsSensor: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var fortsetzung: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    func hole() async -> CLLocationCoordinate2D? {
        guard CLLocationManager.locationServicesEnabled() else { return nil }
        manager.delegate = self

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return await withCheckedContinuation { continuation in
                fortsetzung = continuation
                manager.requestLocation()
            }
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return nil
        default:
            return nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            fortsetzung?.resume(returning: locations.last?.coordinate)
            fortsetzung = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            fortsetzung?.resume(returning: nil)
            fortsetzung = nil
        }
    }
}
