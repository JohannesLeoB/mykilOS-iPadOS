import SwiftUI
import UIKit
import AVFoundation

/// Live-Kamera für die Aufmaß-Aufnahme — kein Fotoalbum-Zugriff, das Foto wird
/// im Moment geboren, nie nachsortiert. 1:1 aus mykilOS iOS übernommen.
///
/// Eigene AVFoundation-Kamera (statt UIImagePickerController), damit zwei
/// Aufnahme-Hilfen live übers Kamerabild gelegt werden können:
///  • **Drittel-Gitterraster** (3×3) zum sauberen Ausrichten des Bildausschnitts.
///  • **„Geradehalten"-Assistent** — eine CoreMotion-Libelle, die grün wird,
///    wenn das Gerät senkrecht/waagerecht gehalten wird.
struct KameraAufnahmeView: View {
    let onAufnahme: (UIImage, [String: Any]) -> Void
    let onAbbruch: () -> Void

    @State private var kamera = KameraController()
    @State private var level = KameraLevelSensor()
    @State private var zeigeGitter = false
    @State private var zeigeLibelle = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            KameraVorschau(controller: kamera)
                .ignoresSafeArea()

            if zeigeGitter {
                DrittelGitter()
                    .allowsHitTesting(false)
            }

            if zeigeLibelle && level.verfuegbar {
                LibellenAnzeige(level: level)
                    .allowsHitTesting(false)
            }

            untererBereich
        }
        .safeAreaInset(edge: .top) {
            obereLeiste
        }
        .onAppear {
            kamera.starten()
            level.starten()
        }
        .onDisappear {
            kamera.stoppen()
            level.stoppen()
        }
    }

    private var obereLeiste: some View {
        HStack(spacing: 10) {
            Button { onAbbruch() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.4), in: Circle())
            }
            Spacer()
            werkzeugToggle(an: zeigeGitter, symbol: "grid", titel: "Raster") {
                zeigeGitter.toggle()
            }
            werkzeugToggle(an: zeigeLibelle, symbol: "level", titel: "Gerade") {
                zeigeLibelle.toggle()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var untererBereich: some View {
        VStack {
            Spacer()

            if zeigeLibelle && level.verfuegbar {
                Text(level.ausgerichtet ? "senkrecht · sauber ausgerichtet" : "Gerät geradehalten")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background((level.ausgerichtet ? MykColor.ok : Color.black.opacity(0.5)), in: Capsule())
                    .padding(.bottom, 10)
            }

            HStack {
                Spacer()
                Button { ausloesen() } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 74, height: 74)
                        Circle().fill(.white).frame(width: 60, height: 60)
                    }
                }
                .disabled(!kamera.bereit)
                .opacity(kamera.bereit ? 1 : 0.4)
                Spacer()
            }
            .padding(.bottom, 28)
        }
    }

    private func werkzeugToggle(an: Bool, symbol: String, titel: String, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                Text(titel).font(.caption2.weight(.semibold))
            }
            .foregroundStyle(an ? MykColor.brand : .white)
            .frame(width: 56, height: 44)
            .background(.black.opacity(an ? 0.55 : 0.4), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func ausloesen() {
        kamera.fotoAufnehmen { bild in
            guard let bild else { onAbbruch(); return }
            onAufnahme(bild, [:])
        }
    }
}

// MARK: - Drittel-Gitter (3×3-Linien)

private struct DrittelGitter: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width, h = geo.size.height
                for i in 1...2 {
                    let x = w * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                    let y = h * CGFloat(i) / 3
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(.white.opacity(0.55), lineWidth: 0.75)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Libelle (Geradehalten-Assistent)

private struct LibellenAnzeige: View {
    let level: KameraLevelSensor

    var body: some View {
        let gut = level.ausgerichtet
        let farbe = gut ? MykColor.ok : Color.white
        let dx = CGFloat(max(-10, min(10, level.rollGrad))) * 6
        let dy = CGFloat(max(-10, min(10, level.neigungGrad))) * 6

        return ZStack {
            Circle().stroke(farbe.opacity(0.9), lineWidth: 2).frame(width: 64, height: 64)
            Rectangle().fill(farbe.opacity(0.9)).frame(width: 22, height: 2)
            Rectangle().fill(farbe.opacity(0.9)).frame(width: 2, height: 22)
            Circle().fill(farbe).frame(width: 14, height: 14)
                .offset(x: dx, y: dy)
                .shadow(color: .black.opacity(0.4), radius: 2)
        }
        .animation(.easeOut(duration: 0.08), value: gut)
    }
}

// MARK: - AVFoundation-Preview (UIViewRepresentable)

private struct KameraVorschau: UIViewRepresentable {
    let controller: KameraController

    func makeUIView(context: Context) -> VorschauView {
        let v = VorschauView()
        v.videoPreviewLayer.session = controller.session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: VorschauView, context: Context) {
        uiView.videoPreviewLayer.session = controller.session
    }

    final class VorschauView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Kamera-Controller (AVCaptureSession)

@MainActor
@Observable
final class KameraController: NSObject {
    let session = AVCaptureSession()
    private(set) var bereit = false

    private let ausgabe = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.johannes.mykilOSiPad.kamera")
    private var konfiguriert = false
    private var aufnahmeCallback: ((UIImage?) -> Void)?

    func starten() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] erlaubt in
            guard let self else { return }
            guard erlaubt else {
                Task { @MainActor in self.bereit = false }
                return
            }
            self.queue.async {
                self.konfigurieren()
                if !self.session.isRunning { self.session.startRunning() }
                Task { @MainActor in self.bereit = self.konfiguriert }
            }
        }
    }

    func stoppen() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func fotoAufnehmen(_ fertig: @escaping (UIImage?) -> Void) {
        guard bereit else { fertig(nil); return }
        aufnahmeCallback = fertig
        let settings = AVCapturePhotoSettings()
        queue.async { [weak self] in
            guard let self else { return }
            self.ausgabe.capturePhoto(with: settings, delegate: self)
        }
    }

    private func konfigurieren() {
        guard !konfiguriert else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard
            let geraet = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let eingang = try? AVCaptureDeviceInput(device: geraet),
            session.canAddInput(eingang),
            session.canAddOutput(ausgabe)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(eingang)
        session.addOutput(ausgabe)
        session.commitConfiguration()
        konfiguriert = true
    }
}

extension KameraController: @preconcurrency AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let bild: UIImage? = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        let cb = self.aufnahmeCallback
        self.aufnahmeCallback = nil
        cb?(bild)
    }
}
