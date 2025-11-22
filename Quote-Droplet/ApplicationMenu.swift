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
        topView.frame.size = CGSize(width: 325, height: 300) // ! previously width of 250
        topView.wantsLayer = true
        topView.layer?.backgroundColor = backgroundColor.cgColor
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView
        
        
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())

		// MARK - submit a quote

        let quoteSubmissionMenuItem = NSMenuItem(title: "Submit a Quote",
                                         action: #selector(openLink),
                                         keyEquivalent: "s")
		quoteSubmissionMenuItem.target = self
		quoteSubmissionMenuItem.representedObject = "https://quote-dropper-production.up.railway.app/submit-quote"
        menu.addItem(quoteSubmissionMenuItem)

		// MARK - submit feedback

        let feedbackSubmissionMenuItem = NSMenuItem(title: "Submit Feedback",
                                         action: #selector(openLink),
                                         keyEquivalent: "f")
		feedbackSubmissionMenuItem.target = self
		feedbackSubmissionMenuItem.representedObject = "https://quote-dropper-production.up.railway.app/submit-feedback"
        menu.addItem(feedbackSubmissionMenuItem)

		// MARK - landing page

        let landingMenuItem = NSMenuItem(title: "Visit Landing Page",
                                         action: #selector(openLink),
                                         keyEquivalent: "l")
        landingMenuItem.target = self
        landingMenuItem.representedObject = "https://quote-droplet-landing.vercel.app/"
        menu.addItem(landingMenuItem)
        
		// MARK - about

        let aboutMenuItem = NSMenuItem(title: "About Quote Droplet",
                                       action: #selector(about),
                                       keyEquivalent: "a")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

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

