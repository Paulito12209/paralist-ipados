// Zusammenhang: Paralist/Resources/Assets.xcassets/AppIcon.appiconset, Theme/Palette.swift (sheetTop, sheetBottom, sheetGlow), Pages/OverviewParts.swift (Kacheln), Entries/TypeLook.swift (Farben), Assets XoolRocket/XoolCube
import AppKit
import SwiftUI

let size: CGFloat = 1024
let assets = "Paralist/Resources/Assets.xcassets"
let outDir = "\(assets)/AppIcon.appiconset"

func hex(_ v: UInt32) -> Color {
    Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
}

func svg(_ name: String) -> NSImage {
    let img = NSImage(contentsOfFile: "\(assets)/\(name).imageset/\(name).svg")!
    img.isTemplate = true
    img.size = NSSize(width: size, height: size)
    return img
}

struct Glyph: View {
    let asset: String?
    let symbol: String?
    let color: Color
    var body: some View {
        Group {
            if let asset { Image(nsImage: svg(asset)).renderingMode(.template).resizable().scaledToFit() }
            else { Image(systemName: symbol!).resizable().scaledToFit() }
        }
        .fontWeight(.light)
        .foregroundStyle(color)
        .frame(width: 236, height: 236)
    }
}

struct IconView: View {
    let dark: Bool
    var body: some View {
        ZStack {
            LinearGradient(colors: [hex(dark ? 0x24262C : 0xF4F6FB), hex(dark ? 0x24407F : 0xBBCDF2)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [hex(dark ? 0xC8D4F0 : 0xFFFFFF).opacity(0.18), .clear], center: .top, startRadius: 0, endRadius: 640)
            RadialGradient(colors: [hex(dark ? 0xC8D4F0 : 0xFFFFFF).opacity(0.12), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 520)
            Grid(horizontalSpacing: 120, verticalSpacing: 120) {
                GridRow {
                    Glyph(asset: "XoolRocket", symbol: nil, color: hex(0xE03E3E))
                    Glyph(asset: nil, symbol: "square.stack.3d.up", color: hex(0xD09020))
                }
                GridRow {
                    Glyph(asset: "XoolCube", symbol: nil, color: hex(0x10B981))
                    Glyph(asset: nil, symbol: "archivebox", color: hex(dark ? 0xC4C7C5 : 0x444746))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

@MainActor func render(dark: Bool, to file: String) {
    let r = ImageRenderer(content: IconView(dark: dark))
    r.scale = 1
    guard let cg = r.cgImage else { fatalError("render failed") }
    let rep = NSBitmapImageRep(cgImage: cg)
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(file)"))
    print("wrote \(file) \(cg.width)x\(cg.height)")
}

MainActor.assumeIsolated {
    render(dark: false, to: "AppIcon.png")
    render(dark: true, to: "AppIcon-Dark.png")
}
