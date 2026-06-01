#!/usr/bin/swift
// Generates Scalator's app icon: white 0-10 scale dial on dark gray background.
import CoreGraphics
import ImageIO
import Foundation

let SIZE = 1024
let fSz  = CGFloat(SIZE)
let cs   = CGColorSpace(name: CGColorSpace.sRGB)!

guard let ctx = CGContext(data: nil, width: SIZE, height: SIZE,
                          bitsPerComponent: 8, bytesPerRow: SIZE * 4, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { fputs("CGContext failed\n", stderr); exit(1) }

let cx = fSz / 2, cy = fSz / 2

// ── Background (dark charcoal rounded rect) ───────────────────────────────────
let bgPath = CGMutablePath()
bgPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: fSz, height: fSz),
                      cornerWidth: 224, cornerHeight: 224)
ctx.setFillColor(CGColor(colorSpace: cs, components: [0.21, 0.21, 0.23, 1.0])!)
ctx.addPath(bgPath); ctx.fillPath()

// Subtle inner glow
let glowPath = CGMutablePath()
glowPath.addEllipse(in: CGRect(x: cx - fSz*0.45, y: cy - fSz*0.45, width: fSz*0.90, height: fSz*0.90))
ctx.setFillColor(CGColor(gray: 1.0, alpha: 0.04))
ctx.addPath(glowPath); ctx.fillPath()

// ── Scale parameters ──────────────────────────────────────────────────────────
let radius: CGFloat = fSz * 0.375
let startV: CGFloat = -135, endV: CGFloat = 135
let sweep  = endV - startV       // 270°
let major  = 11, minor = 4
let total  = (major - 1) * (minor + 1)  // 50 intervals

// Visual angle (CW from top) → Core Graphics radians (CCW from right, y-up)
func toRad(_ v: CGFloat) -> CGFloat { (90 - v) * .pi / 180 }

// ── Subtle guide arc ──────────────────────────────────────────────────────────
// CGContext arc: angles in radians, CCW positive, y-up
// startV=-135 → mathAngle=225°; endV=135 → mathAngle=-45°
// Travelling CW visually = decreasing math angle = clockwise: true in CG
let arcR = radius + fSz * 0.005
ctx.setStrokeColor(CGColor(gray: 1.0, alpha: 0.12))
ctx.setLineWidth(fSz * 0.004)
ctx.addArc(center: CGPoint(x: cx, y: cy), radius: arcR,
           startAngle: toRad(startV), endAngle: toRad(endV), clockwise: true)
ctx.strokePath()

// ── Tick marks ────────────────────────────────────────────────────────────────
ctx.setLineCap(.round)
for i in 0...total {
    let frac  = CGFloat(i) / CGFloat(total)
    let angle = toRad(startV + frac * sweep)
    let isMajor = i % (minor + 1) == 0

    let len:   CGFloat = isMajor ? fSz * 0.080 : fSz * 0.040
    let width: CGFloat = isMajor ? fSz * 0.016 : fSz * 0.008
    let alpha: CGFloat = isMajor ? 1.0 : 0.80

    ctx.setStrokeColor(CGColor(gray: 1.0, alpha: alpha))
    ctx.setLineWidth(width)
    ctx.move(to:    CGPoint(x: cx + cos(angle) * radius,         y: cy + sin(angle) * radius))
    ctx.addLine(to: CGPoint(x: cx + cos(angle) * (radius - len), y: cy + sin(angle) * (radius - len)))
    ctx.strokePath()
}

// ── Numeric labels: 0, 5, 10 via Core Text ───────────────────────────────────
import CoreText

let labelR = radius - fSz * 0.080 - fSz * 0.058  // inside the ticks
let fontSize = fSz * 0.062
let ctFont = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, fontSize, nil)

for (mi, lbl) in [(0,"0"), (5,"5"), (10,"10")] {
    let frac  = CGFloat(mi) / CGFloat(major - 1)
    let angle = toRad(startV + frac * sweep)
    let lx = cx + cos(angle) * labelR
    let ly = cy + sin(angle) * labelR

    let aStr = NSAttributedString(string: lbl, attributes: [
        kCTFontAttributeName as NSAttributedString.Key: ctFont,
        kCTForegroundColorAttributeName as NSAttributedString.Key:
            CGColor(gray: 0.92, alpha: 1.0) as AnyObject
    ])
    let line = CTLineCreateWithAttributedString(aStr)
    let b = CTLineGetBoundsWithOptions(line, [])

    ctx.saveGState()
    ctx.textMatrix = .identity
    ctx.translateBy(x: lx - b.width/2 - b.origin.x,
                    y: ly - b.height/2 - b.origin.y)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// ── Center dot ────────────────────────────────────────────────────────────────
let dr: CGFloat = fSz * 0.022
ctx.setFillColor(CGColor(gray: 0.60, alpha: 1.0))
ctx.fillEllipse(in: CGRect(x: cx-dr, y: cy-dr, width: dr*2, height: dr*2))

// ── Save PNG ──────────────────────────────────────────────────────────────────
guard let img = ctx.makeImage() else { fputs("makeImage failed\n", stderr); exit(1) }
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/scalator_icon.png"
guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                                  "public.png" as CFString, 1, nil)
else { fputs("Destination failed\n", stderr); exit(1) }
CGImageDestinationAddImage(dest, img, nil)
guard CGImageDestinationFinalize(dest) else { fputs("Finalize failed\n", stderr); exit(1) }
print("Icon saved: \(out)")
