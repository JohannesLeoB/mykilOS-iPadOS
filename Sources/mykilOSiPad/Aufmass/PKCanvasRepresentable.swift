import PencilKit
import SwiftUI

/// Dünner UIViewRepresentable-Wrapper um `PKCanvasView` — die Grundlage für
/// Apple-Pencil-Freihand-Annotationen im Aufmaß-Editor (Task #7, existiert in
/// mykilOS iOS noch gar nicht, komplett neu für die iPad-App). `drawingPolicy
/// = .anyInput` erlaubt bewusst auch Finger-Zeichnen, damit die Funktion nicht
/// hart an ein gekoppeltes Pencil gebunden ist.
struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var strichFarbe: UIColor = UIColor(red: 0xEA/255, green: 0x5B/255, blue: 0x25/255, alpha: 1)
    var strichBreite: CGFloat = 4

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: strichFarbe, width: strichBreite)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PKCanvasRepresentable
        init(_ parent: PKCanvasRepresentable) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
