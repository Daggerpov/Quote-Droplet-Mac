//
//  ApplicationMenu.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-07-16.
//

import Foundation
import SwiftUI

class ApplicationMenu: NSObject {
    let menu = NSMenu()
    
    // Get the app version from the bundle
    var versionNumber: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }
        return version
    }
    
    func createMenu() -> NSMenu {
        let quoteView = QuoteView()
        
        let topView = NSHostingView(rootView: quoteView)
        topView.frame.size = CGSize(width: 250, height: 300)
        topView.wantsLayer = true
        topView.layer?.backgroundColor = backgroundColor.cgColor
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView
        
        
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        let aboutMenuItem = NSMenuItem(title: "About Quote Droplet",
                                       action: #selector(about),
                                       keyEquivalent: "")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)
        
        let webLinkMenuItem = NSMenuItem(title: "Visit my GitHub",
                                         action: #selector(openLink),
                                         keyEquivalent: "")
        webLinkMenuItem.target = self
        webLinkMenuItem.representedObject = "https://github.com/Daggerpov"
        menu.addItem(webLinkMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "Quit",
                                      action: #selector(quit),
                                      keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    // Compute the dynamic background color based on the color scheme
    private var backgroundColor: NSColor {
        if NSApp.effectiveAppearance.name == .darkAqua {
            // Use dark wood background color for dark mode
            return NSColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1.0)
        } else {
            // Use light wood background color for light mode
            return NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        }
    }
    
    @objc func about(sender: NSMenuItem) {
        let aboutPanel = NSAlert()
        aboutPanel.messageText = "About Quote Droplet"
        aboutPanel.informativeText = """
        Version \(versionNumber)
        
        If you want this app to automatically stay open, you can navigate to your System Settings -> General -> Login Items -> Click the "+" -> find Quote Droplet in your applications.

        Be sure to also install Quote Droplet on your iPhone or iPad from the App Store.
        """
        aboutPanel.addButton(withTitle: "OK")
        aboutPanel.runModal()
    }
    
    @objc func openLink(sender: NSMenuItem) {
        let link = sender.representedObject as! String
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
}
