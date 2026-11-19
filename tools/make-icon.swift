// Renders the app icon (1024x1024 PNG): white cup on a rounded coffee-colored background.
// Usage: swift tools/make-icon.swift output.png
import AppKit

let side = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS icon grid: 824 px content area centered, ~185 px corner radius.
let box = NSRect(x: 100, y: 100, width: 824, height: 824)
let background = NSBezierPath(roundedRect: box, xRadius: 185, yRadius: 185)
NSGradient(
    starting: NSColor(red: 0.62, green: 0.40, blue: 0.24, alpha: 1),
    ending: NSColor(red: 0.29, green: 0.16, blue: 0.09, alpha: 1))!
    .draw(in: background, angle: -90)

let configuration = NSImage.SymbolConfiguration(pointSize: 420, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(configuration)!
let size = symbol.size
symbol.draw(in: NSRect(
    x: (CGFloat(side) - size.width) / 2, y: (CGFloat(side) - size.height) / 2,
    width: size.width, height: size.height))

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
