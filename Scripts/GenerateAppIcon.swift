import AppKit
import CoreGraphics

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalog = root.appendingPathComponent("PocketNotes/Assets.xcassets", isDirectory: true)
let iconSet = catalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

guard let bitmap = NSBitmapImageRep(
    pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: false, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create app icon bitmap")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
graphics.imageInterpolation = .high
let c = graphics.cgContext
c.setAllowsAntialiasing(true)
c.setShouldAntialias(true)

let bgColors = [
    NSColor(calibratedRed: 0.008, green: 0.025, blue: 0.13, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.015, green: 0.12, blue: 0.48, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.015, green: 0.30, blue: 0.88, alpha: 1).cgColor
] as CFArray
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0, 0.52, 1])!
c.drawLinearGradient(bg, start: CGPoint(x: 80, y: 980), end: CGPoint(x: 980, y: 40), options: [])

func ribbon(_ p: (CGPoint, CGPoint, CGPoint, CGPoint), _ color: NSColor, _ width: CGFloat) {
    let path = CGMutablePath()
    path.move(to: p.0)
    path.addCurve(to: p.3, control1: p.1, control2: p.2)
    c.saveGState()
    c.addPath(path)
    c.setLineCap(.round)
    c.setLineWidth(width)
    c.setStrokeColor(color.cgColor)
    c.strokePath()
    c.restoreGState()
}
ribbon((CGPoint(x: -100, y: 170), CGPoint(x: 220, y: 390), CGPoint(x: 560, y: -20), CGPoint(x: 1120, y: 90)), NSColor(calibratedRed: 0.03, green: 0.40, blue: 1, alpha: 0.45), 112)
ribbon((CGPoint(x: 700, y: 1120), CGPoint(x: 730, y: 870), CGPoint(x: 1010, y: 840), CGPoint(x: 1130, y: 620)), NSColor(calibratedRed: 0.02, green: 0.52, blue: 1, alpha: 0.42), 105)
ribbon((CGPoint(x: -100, y: 40), CGPoint(x: 260, y: 240), CGPoint(x: 660, y: -70), CGPoint(x: 1120, y: -5)), NSColor(calibratedRed: 0.015, green: 0.30, blue: 0.95, alpha: 0.30), 58)

let page = CGMutablePath()
page.move(to: CGPoint(x: 312, y: 170))
page.addCurve(to: CGPoint(x: 728, y: 170), control1: CGPoint(x: 260, y: 170), control2: CGPoint(x: 640, y: 170))
page.addCurve(to: CGPoint(x: 824, y: 266), control1: CGPoint(x: 824, y: 170), control2: CGPoint(x: 824, y: 218))
page.addLine(to: CGPoint(x: 824, y: 620))
page.addLine(to: CGPoint(x: 650, y: 798))
page.addLine(to: CGPoint(x: 312, y: 798))
page.addCurve(to: CGPoint(x: 220, y: 706), control1: CGPoint(x: 220, y: 798), control2: CGPoint(x: 220, y: 752))
page.addLine(to: CGPoint(x: 220, y: 262))
page.addCurve(to: CGPoint(x: 312, y: 170), control1: CGPoint(x: 220, y: 216), control2: CGPoint(x: 264, y: 170))
page.closeSubpath()

c.saveGState()
c.setShadow(offset: CGSize(width: 0, height: -26), blur: 42, color: NSColor(calibratedRed: 0, green: 0.01, blue: 0.07, alpha: 0.68).cgColor)
c.addPath(page)
c.setFillColor(NSColor.white.cgColor)
c.fillPath()
c.restoreGState()

c.saveGState()
c.addPath(page)
c.clip()
let paperColors = [
    NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.91, green: 0.94, blue: 1, alpha: 1).cgColor
] as CFArray
let paper = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: paperColors, locations: [0, 1])!
c.drawLinearGradient(paper, start: CGPoint(x: 280, y: 850), end: CGPoint(x: 760, y: 160), options: [])
c.restoreGState()

let fold = CGMutablePath()
fold.move(to: CGPoint(x: 650, y: 798))
fold.addLine(to: CGPoint(x: 650, y: 650))
fold.addLine(to: CGPoint(x: 824, y: 620))
fold.closeSubpath()
c.saveGState()
c.addPath(fold)
let foldColors = [
    NSColor(calibratedRed: 0.82, green: 0.87, blue: 0.98, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 1, alpha: 1).cgColor
] as CFArray
let foldGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: foldColors, locations: [0, 1])!
c.drawLinearGradient(foldGradient, start: CGPoint(x: 650, y: 798), end: CGPoint(x: 824, y: 620), options: [])
c.restoreGState()
c.move(to: CGPoint(x: 650, y: 650))
c.addLine(to: CGPoint(x: 824, y: 620))
c.setStrokeColor(NSColor(calibratedRed: 0.70, green: 0.77, blue: 0.92, alpha: 0.75).cgColor)
c.setLineWidth(3)
c.strokePath()

func line(_ rect: CGRect, _ radius: CGFloat, _ color: NSColor) {
    c.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    c.setFillColor(color.cgColor)
    c.fillPath()
}
let ink = NSColor(calibratedRed: 0.025, green: 0.075, blue: 0.24, alpha: 1)
line(CGRect(x: 315, y: 570, width: 340, height: 44), 22, ink)
line(CGRect(x: 315, y: 478, width: 390, height: 44), 22, ink)
c.addPath(CGPath(ellipseIn: CGRect(x: 315, y: 365, width: 52, height: 52), transform: nil))
c.setFillColor(NSColor(calibratedRed: 0.015, green: 0.40, blue: 0.98, alpha: 1).cgColor)
c.fillPath()
line(CGRect(x: 405, y: 369, width: 300, height: 44), 22, ink)
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
try png.write(to: iconSet.appendingPathComponent("AppIcon.png"), options: .atomic)
let iconJSON = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try iconJSON.write(to: iconSet.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
let catalogJSON = """
{ "info" : { "author" : "xcode", "version" : 1 } }
"""
try catalogJSON.write(to: catalog.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Generated Pocket Notes 1024x1024 app icon")
