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
    
    // Add a property to hold all quotes
    var allQuotes: [QuoteJSON] = []
    
    // Initialize submitQuoteWindowController in the constructor
    override init() {
        super.init()

        // Load quotes from JSON
        loadQuotesFromJSON()
    }
    
    // Method to load quotes from JSON
    func loadQuotesFromJSON() {
        guard let path = Bundle.main.path(forResource: "QuotesBackup", ofType: "json") else {
            print("Error: Unable to locate QuotesBackup.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            allQuotes = try decoder.decode([QuoteJSON].self, from: data)
        } catch {
            print("Error decoding QuotesBackup JSON: \(error.localizedDescription)")
        }
    }
    
    
    // Get the app version from the bundle
    var versionNumber: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }
        return version
    }
    
    func createMenu() -> NSMenu {
        let quoteView = QuoteView(quotes: allQuotes)
        
        let topView = NSHostingView(rootView: quoteView)
        topView.frame.size = CGSize(width: 340, height: 340) // ! previously width of 250, then 325
        // SwiftUI draws the background (it follows light/dark mode)
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView
        
        
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())

		// MARK - submit a quote

        let quoteSubmissionMenuItem = NSMenuItem(title: "Submit a Quote",
                                         action: #selector(openLink),
                                         keyEquivalent: "s")
		quoteSubmissionMenuItem.target = self
		quoteSubmissionMenuItem.image = NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: nil)
		quoteSubmissionMenuItem.representedObject = "https://quote-dropper-production.up.railway.app/submit-quote"
        menu.addItem(quoteSubmissionMenuItem)

		// MARK - submit feedback

        let feedbackSubmissionMenuItem = NSMenuItem(title: "Submit Feedback",
                                         action: #selector(openLink),
                                         keyEquivalent: "f")
		feedbackSubmissionMenuItem.target = self
		feedbackSubmissionMenuItem.image = NSImage(systemSymbolName: "bubble.left", accessibilityDescription: nil)
		feedbackSubmissionMenuItem.representedObject = "https://quote-dropper-production.up.railway.app/submit-feedback"
        menu.addItem(feedbackSubmissionMenuItem)

		// MARK - landing page

        let landingMenuItem = NSMenuItem(title: "Visit Landing Page",
                                         action: #selector(openLink),
                                         keyEquivalent: "l")
        landingMenuItem.target = self
        landingMenuItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        landingMenuItem.representedObject = "https://quote-droplet-landing.vercel.app/"
        menu.addItem(landingMenuItem)
        
		// MARK - about

        let aboutMenuItem = NSMenuItem(title: "About Quote Droplet",
                                       action: #selector(about),
                                       keyEquivalent: "a")
        aboutMenuItem.target = self
        aboutMenuItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutMenuItem)
        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(title: "Quit",
                                      action: #selector(quit),
                                      keyEquivalent: "q")
        quitMenuItem.target = self
        quitMenuItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    @objc func about(sender: NSMenuItem) {
        let aboutPanel = NSAlert()
        aboutPanel.messageText = "About Quote Droplet"
        aboutPanel.informativeText = """
        Version \(versionNumber)
        
        If you want this app to automatically stay open, you can navigate to your System Settings -> General -> Login Items -> Click the "+" -> find Quote Droplet in your applications.
        
        Be sure to also install Quote Droplet on your iPhone or iPad from the App Store, as it comes with convenient widgets and notifications.
        
        Once you install it on your iPhone or iPad, you can also add it as a widget for your Mac—by pressing the date button on the top right of your screen -> "Edit Widgets"
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

