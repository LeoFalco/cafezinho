// Gera o ícone do app (PNG 1024x1024): xícara branca sobre fundo café com cantos arredondados.
// Uso: swift tools/gera-icone.swift saida.png
import AppKit

let lado = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: lado, pixelsHigh: lado, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Grade de ícone do macOS: área útil de 824 px centralizada, raio de canto de ~185 px.
let caixa = NSRect(x: 100, y: 100, width: 824, height: 824)
let fundo = NSBezierPath(roundedRect: caixa, xRadius: 185, yRadius: 185)
NSGradient(
    starting: NSColor(red: 0.62, green: 0.40, blue: 0.24, alpha: 1),
    ending: NSColor(red: 0.29, green: 0.16, blue: 0.09, alpha: 1))!
    .draw(in: fundo, angle: -90)

let configuracao = NSImage.SymbolConfiguration(pointSize: 420, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
let simbolo = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(configuracao)!
let tamanho = simbolo.size
simbolo.draw(in: NSRect(
    x: (CGFloat(lado) - tamanho.width) / 2, y: (CGFloat(lado) - tamanho.height) / 2,
    width: tamanho.width, height: tamanho.height))

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
