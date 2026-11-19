import AppKit
import SwiftUI

// Renders the Mac app's QuoteView offscreen (both appearances) to PNGs. Run it through render.sh.
// usage: render <QuotesBackup.json> <outdir> <category-raw> <quote-id>
let args = CommandLine.arguments
let data = try! Data(contentsOf: URL(fileURLWithPath: args[1]))
let all = try! JSONDecoder().decode([QuoteJSON].self, from: data)
let wantedID = Int(args[4]) ?? -1
let quotes = all.filter { $0.id == wantedID }.isEmpty ? all : all.filter { $0.id == wantedID }
UserDefaults.standard.set(args[3], forKey: "quoteClassification")

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

for (name, appearance) in [("dark", NSAppearance.Name.darkAqua), ("light", NSAppearance.Name.aqua)] {
    let view = NSHostingView(rootView: QuoteView(quotes: quotes).frame(width: 340, height: 340))
    view.frame = NSRect(x: 0, y: 0, width: 340, height: 340)
    let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    window.appearance = NSAppearance(named: appearance)
    window.contentView = view
    window.backingType = .buffered
    view.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(1.0))
    view.layoutSubtreeIfNeeded()
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: rep)
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(args[2])/menu_\(name).png"))
    print("wrote", name, rep.pixelsWide, rep.pixelsHigh)
}
