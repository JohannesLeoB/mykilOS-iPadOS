import Foundation

/// Übersetzt häufige Netzwerkfehler in verständliches Deutsch statt roher
/// System-Meldungen. 1:1 aus mykilOS iOS übernommen.
enum Fehlertext {
    static func deutsch(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Kein Internet — bitte WLAN oder Mobilfunk prüfen."
            case .timedOut:
                return "Zeitüberschreitung — die Verbindung war zu langsam oder tot."
            case .cannotFindHost, .cannotConnectToHost:
                return "Server nicht erreichbar — später nochmal versuchen."
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
