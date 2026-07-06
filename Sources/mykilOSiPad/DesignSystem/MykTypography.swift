import SwiftUI

/// mykilOS-CI-Typografie: ABC Monument Grotesk (Medium) für Überschriften/UI,
/// ABC Monument Grotesk Mono für Zahlen/Codes/technische Werte (Maße,
/// Projektnummern) — Font-Dateien 1:1 aus dem mykilOS-Design-System
/// übernommen (`MYKILOS Design System/assets/fonts/`), PostScript-Namen per
/// `fontTools` verifiziert statt geraten.
enum MykFont {
    static func grotesk(_ size: CGFloat) -> Font {
        .custom("ABCMonumentGrotesk-Medium", size: size)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom("ABCMonumentGroteskMono-Regular", size: size)
    }
}

extension Font {
    static func mykGrotesk(_ size: CGFloat) -> Font { MykFont.grotesk(size) }
    static func mykMono(_ size: CGFloat) -> Font { MykFont.mono(size) }
}
