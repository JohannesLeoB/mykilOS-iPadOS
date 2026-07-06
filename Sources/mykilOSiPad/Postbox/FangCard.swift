import SwiftUI
import UIKit

/// Fang → Versteh → Verräum — die zentrale Schnell-Erfassung. Gegenüber
/// mykilOS iOS (vorerst) ohne Sprachaufnahme, Visitenkarten-/Lieferschein-OCR
/// (siehe `WORK_STATUS.md`, Task #19) — Text-Fang und Feld-Foto-Kamera sind
/// aber echt und schreiben in dieselben Stores wie das Original.
struct FangCard: View {
    let postbox: PostboxStore
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var eingabe = ""
    @State private var aktiv: FangKind?
    @State private var erledigtText: String?
    @State private var schreibFehler: String?
    @State private var zeigeKamera = false
    @State private var frischesBild: FrischesBild?

    private let chips: [String] = ["'4h CAD für Kunde'", "'Idee: Messing für die Bar'"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FANG → VERSTEH → VERRÄUM")
                .font(.mykMono(11))
                .tracking(1.2)
                .foregroundStyle(MykColor.brand)

            HStack(spacing: 8) {
                TextField("Sprich oder tippe einen Moment…", text: $eingabe)
                    .textFieldStyle(.plain)
                    .padding(13)
                    .background(MykColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line, lineWidth: 1.5))
                    .onSubmit { fangenFalls(eingabe) }

                Button {
                    fangenFalls(eingabe)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(MykColor.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    zeigeKamera = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(MykColor.brand)
                        .frame(width: 44, height: 44)
                        .background(MykColor.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                }
                .accessibilityLabel("Kamera — Feld-Foto")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(chips, id: \.self) { chip in
                        Button(chip) { fangen(chip) }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(MykColor.brand)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MykColor.brand.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            if let kind = aktiv {
                karte(for: kind)
            }
            if let text = erledigtText {
                Text(text)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MykColor.ok)
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.ok, lineWidth: 1.5))
            }
            if let fehler = schreibFehler {
                Text(fehler).font(.footnote.weight(.semibold)).foregroundStyle(MykColor.crit)
            }
            if !postbox.items.isEmpty {
                NavigationLink {
                    PostboxView(postbox: postbox)
                } label: {
                    Text("\(postbox.items.count) in der Postbox · ansehen")
                        .font(.mykMono(11))
                        .foregroundStyle(MykColor.muted)
                }
            }
        }
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { bild, _ in
                    frischesBild = FrischesBild(bild: bild, aufgenommenAm: Date())
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $frischesBild) { frisch in
            FeldFotoBestaetigungView(
                bild: frisch.bild,
                aufgenommenAm: frisch.aufgenommenAm,
                store: store,
                feldFotoStore: feldFotoStore,
                onFertig: { frischesBild = nil }
            )
        }
    }

    private var erkanntesProjekt: Project? {
        let text = eingabe.lowercased()
        guard !text.isEmpty else { return nil }
        return store.projects
            .filter { $0.title.count >= 3 && text.contains($0.title.lowercased()) }
            .max { $0.title.count < $1.title.count }
    }

    private func fangenFalls(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        fangen(text)
    }

    private func fangen(_ text: String) {
        erledigtText = nil
        schreibFehler = nil
        eingabe = text
            .trimmingCharacters(in: CharacterSet(charactersIn: "\u{201E}\u{201C}\u{201D}"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        aktiv = FangKind.versteh(eingabe)
    }

    private func bestaetigen(_ kind: FangKind) {
        let projektZusatz = erkanntesProjekt.map { " · Projekt \($0.projectNumber)" } ?? ""
        let item: PostboxItem
        switch kind {
        case .zeit(let dauer, let kontext):
            item = PostboxItem(kind: "zeit", text: dauer, kontext: kontext + projektZusatz)
        case .idee(let text):
            item = PostboxItem(kind: "idee", text: text, kontext: projektZusatz.trimmingCharacters(in: CharacterSet(charactersIn: " ·")))
        case .fotoHinweis:
            return
        }
        do {
            try postbox.append(item)
            erledigtText = "✓ In der Postbox abgelegt."
            schreibFehler = nil
            aktiv = nil
            eingabe = ""
        } catch {
            schreibFehler = Fehlertext.deutsch(error)
        }
    }

    @ViewBuilder
    private func karte(for kind: FangKind) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kind.titel).font(.mykMono(11)).foregroundStyle(kind.gesperrt ? MykColor.muted : MykColor.brand)
            Text(kind.koerper).font(.subheadline)
            Text(kind.meta).font(.caption).foregroundStyle(MykColor.muted)

            if !kind.gesperrt, let projekt = erkanntesProjekt {
                Label("\(projekt.title) · \(projekt.projectNumber)", systemImage: "mappin.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MykColor.brand)
            }

            if !kind.gesperrt {
                HStack(spacing: 8) {
                    Button("Bestätigen") { bestaetigen(kind) }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.brand)
                    Button("Verwerfen") { aktiv = nil }
                        .buttonStyle(.bordered)
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(12)
        .background(kind.gesperrt ? Color.clear : MykColor.brand.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(kind.gesperrt ? MykColor.muted : MykColor.brand, lineWidth: 1.4))
    }
}

private struct FrischesBild: Identifiable {
    let id = UUID()
    let bild: UIImage
    let aufgenommenAm: Date
}

#Preview {
    NavigationStack {
        FangCard(postbox: PostboxStore(), store: ProjectStore(), feldFotoStore: FeldFotoStore())
            .padding(20)
    }
}
