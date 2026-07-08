import AppKit
import CoreGraphics
import Foundation

// Renders the MaterialColors app icon: a grid of material color swatches
// on a rounded white card, following the macOS icon shape/margins.

func hex(_ s: String) -> CGColor {
    var h = s; if h.hasPrefix("#") { h.removeFirst() }
    let v = Int(h, radix: 16)!
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255.0,
                   green: CGFloat((v >> 8) & 0xFF) / 255.0,
                   blue: CGFloat(v & 0xFF) / 255.0,
                   alpha: 1.0)
}

// A 3x3 selection of iconic Material 500 shades (+ two accents) for a lively palette.
let swatches: [[String]] = [
    ["#F44336", "#FF9800", "#FFC107"], // red, orange, amber
    ["#4CAF50", "#009688", "#2196F3"], // green, teal, blue
    ["#3F51B5", "#9C27B0", "#E91E63"], // indigo, purple, pink
]

func roundedRect(_ ctx: CGContext, _ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawIcon(size: CGFloat) -> CGImage {
    let space = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil,
                        width: Int(size), height: Int(size),
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)

    // Card occupies the standard macOS icon content area (~82% of canvas).
    let margin = size * 0.09
    let cardRect = CGRect(x: margin, y: margin, width: size - margin * 2, height: size - margin * 2)
    let cardRadius = cardRect.width * 0.2237

    // Soft drop shadow under the card.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.012),
                  blur: size * 0.03,
                  color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.28))
    ctx.addPath(roundedRect(ctx, cardRect, cardRadius))
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Clip content to the card.
    ctx.saveGState()
    ctx.addPath(roundedRect(ctx, cardRect, cardRadius))
    ctx.clip()

    // Swatch grid inside the card with padding + gaps.
    let cols = 3, rows = 3
    let pad = cardRect.width * 0.11
    let gap = cardRect.width * 0.05
    let gridRect = cardRect.insetBy(dx: pad, dy: pad)
    let cellW = (gridRect.width - gap * CGFloat(cols - 1)) / CGFloat(cols)
    let cellH = (gridRect.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
    let cellRadius = min(cellW, cellH) * 0.22

    for r in 0..<rows {
        for c in 0..<cols {
            // Row 0 is drawn at top of the card (flip y since CG origin is bottom-left).
            let x = gridRect.minX + CGFloat(c) * (cellW + gap)
            let y = gridRect.minY + CGFloat(rows - 1 - r) * (cellH + gap)
            let cell = CGRect(x: x, y: y, width: cellW, height: cellH)
            ctx.addPath(roundedRect(ctx, cell, cellRadius))
            ctx.setFillColor(hex(swatches[r][c]))
            ctx.fillPath()
        }
    }
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: image.width, height: image.height)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: url)
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// (filename, pixel size)
let targets: [(String, CGFloat)] = [
    ("icon_16.png", 16), ("icon_16@2x.png", 32),
    ("icon_32.png", 32), ("icon_32@2x.png", 64),
    ("icon_128.png", 128), ("icon_128@2x.png", 256),
    ("icon_256.png", 256), ("icon_256@2x.png", 512),
    ("icon_512.png", 512), ("icon_512@2x.png", 1024),
]

for (name, px) in targets {
    let img = drawIcon(size: px)
    writePNG(img, to: outDir.appendingPathComponent(name))
    print("wrote \(name) (\(Int(px))px)")
}
