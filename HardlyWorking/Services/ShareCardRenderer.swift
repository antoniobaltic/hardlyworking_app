import SwiftUI

@MainActor
enum ShareCardRenderer {
    static func render(
        data: ShareCardData,
        type: ShareCardType,
        format: ShareCardFormat,
        isProUser: Bool
    ) -> UIImage? {
        let view = ShareCardView(data: data, type: type, format: format, isProUser: isProUser)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    static func renderToFile(
        data: ShareCardData,
        type: ShareCardType,
        format: ShareCardFormat,
        isProUser: Bool
    ) -> URL? {
        guard let image = render(data: data, type: type, format: format, isProUser: isProUser),
              let pngData = image.pngData()
        else { return nil }

        let fileName = "hardly-working-\(type.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))-\(format.rawValue.lowercased()).png"
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
