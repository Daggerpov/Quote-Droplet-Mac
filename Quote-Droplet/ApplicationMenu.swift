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
    
    func createMenu() -> NSMenu {
        let quoteView = QuoteView()
        let topView = NSHostingController(rootView: quoteView)
        topView.view.frame.size = CGSize(width: 225, height: 225)
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView.view
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        
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
    
    @objc func openLink(sender: NSMenuItem) {
        let link = sender.representedObject as! String
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
}
