import SwiftUI

@MainActor
enum ShareCardRenderer {
    /// Render at @3x so the 360 × 480 logical canvas becomes a 1080 × 1440
    /// final image — sized for Instagram (well within the 4:5 feed crop
    /// window), WhatsApp, Messages, and AirDrop.
    static func render(
        data: ShareCardData,
        type: ShareCardType,
        isProUser: Bool
    ) -> UIImage? {
        let view = ShareCardView(data: data, type: type, isProUser: isProUser)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    static func renderToFile(
        data: ShareCardData,
        type: ShareCardType,
        isProUser: Bool
    ) -> URL? {
        guard let image = render(data: data, type: type, isProUser: isProUser),
              let pngData = image.pngData()
        else { return nil }

        let fileName = "hardly-working-\(type.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")).png"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: tempURL)
            return tempURL
        } catch {
            print("[ShareCardRenderer] Write failed: \(error)")
            return nil
        }
    }
}
