import SwiftUI

/// A plain 8-bit-per-channel RGB color plus color-science helpers.
struct RGB: Equatable {
    var r: Int
    var g: Int
    var b: Int

    // MARK: Parsing

    /// Parses "#RRGGBB", "RRGGBB", "#RGB" or "RGB".
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.hasPrefix("0X") { s.removeFirst(2) }

        // Expand shorthand like "F00" -> "FF0000".
        if s.count == 3 {
            s = s.map { "\($0)\($0)" }.joined()
        }
        guard s.count == 6, let value = Int(s, radix: 16) else { return nil }
        self.r = (value >> 16) & 0xFF
        self.g = (value >> 8) & 0xFF
        self.b = value & 0xFF
    }

    init(r: Int, g: Int, b: Int) {
        self.r = min(max(r, 0), 255)
        self.g = min(max(g, 0), 255)
        self.b = min(max(b, 0), 255)
    }

    /// Parses free-form RGB input such as "rgb(255, 87, 34)", "255,87,34" or "255 87 34".
    static func parseRGB(_ input: String) -> RGB? {
        let numbers = input
            .replacingOccurrences(of: "rgb", with: "", options: .caseInsensitive)
            .components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted)
            .filter { !$0.isEmpty }
            .compactMap { Int($0) }
        guard numbers.count >= 3 else { return nil }
        return RGB(r: numbers[0], g: numbers[1], b: numbers[2])
    }

    /// Accepts either a hex string or an RGB triplet.
    static func parse(_ input: String) -> RGB? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains(",") || trimmed.lowercased().contains("rgb") {
            return parseRGB(trimmed)
        }
        // Bare triple of numbers separated by spaces.
        let spaceParts = trimmed.split(separator: " ")
        if spaceParts.count == 3, spaceParts.allSatisfy({ Int($0) != nil }) {
            return parseRGB(trimmed)
        }
        return RGB(hex: trimmed)
    }

    // MARK: Output

    var hexString: String {
        String(format: "#%02X%02X%02X", r, g, b)
    }

    // MARK: Linear channels (for luminance)

    private static func linearize(_ channel: Int) -> Double {
        let c = Double(channel) / 255.0
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    var rLinear: Double { RGB.linearize(r) }
    var gLinear: Double { RGB.linearize(g) }
    var bLinear: Double { RGB.linearize(b) }

    // MARK: CIELAB conversion (D65)

    var lab: LAB {
        let rl = rLinear, gl = gLinear, bl = bLinear

        // Linear sRGB -> XYZ.
        var x = rl * 0.4124 + gl * 0.3576 + bl * 0.1805
        var y = rl * 0.2126 + gl * 0.7152 + bl * 0.0722
        var z = rl * 0.0193 + gl * 0.1192 + bl * 0.9505

        // Normalize by D65 white point.
        x /= 0.95047
        y /= 1.00000
        z /= 1.08883

        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : (7.787 * t) + (16.0 / 116.0)
        }
        let fx = f(x), fy = f(y), fz = f(z)

        return LAB(
            l: (116.0 * fy) - 16.0,
            a: 500.0 * (fx - fy),
            b: 200.0 * (fy - fz)
        )
    }
}

/// A color in CIELAB space.
struct LAB {
    let l: Double
    let a: Double
    let b: Double

    /// CIE76 perceptual distance (Delta E).
    func distance(to other: LAB) -> Double {
        let dl = l - other.l
        let da = a - other.a
        let db = b - other.b
        return (dl * dl + da * da + db * db).squareRoot()
    }
}

extension Color {
    /// Creates a Color from a hex string, falling back to clear if invalid.
    init(hex: String) {
        if let rgb = RGB(hex: hex) {
            self.init(.sRGB,
                      red: Double(rgb.r) / 255.0,
                      green: Double(rgb.g) / 255.0,
                      blue: Double(rgb.b) / 255.0,
                      opacity: 1.0)
        } else {
            self = .clear
        }
    }
}

/// A search result pairing a swatch with its perceptual distance to a query color.
struct ColorMatch: Identifiable {
    let id = UUID()
    let swatch: MaterialSwatch
    let distance: Double
}

enum ColorFinder {
    /// Returns the `count` material swatches nearest to `query`, sorted closest-first.
    static func nearest(to query: RGB, count: Int = 3) -> [ColorMatch] {
        let queryLab = query.lab
        return MaterialPalette.allSwatches
            .compactMap { swatch -> ColorMatch? in
                guard let rgb = RGB(hex: swatch.hex) else { return nil }
                return ColorMatch(swatch: swatch, distance: rgb.lab.distance(to: queryLab))
            }
            .sorted { $0.distance < $1.distance }
            .prefix(count)
            .map { $0 }
    }
}
