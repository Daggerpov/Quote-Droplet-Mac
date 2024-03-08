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
        
        // Add "Submit a Quote" menu item
        let submitQuoteMenuItem = NSMenuItem(title: "Submit a Quote",
                                             action: #selector(submitQuote),
                                             keyEquivalent: "")
        submitQuoteMenuItem.target = self
        menu.addItem(submitQuoteMenuItem)
        
        
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
        
        That app enables you to see quotes inside of an iOS widget and through push notifications.
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
    
    @objc func submitQuote(sender: NSMenuItem) {
        let submitQuoteWindow = SubmitQuoteWindow(submitHandler: { quoteText, author, category in
            if !quoteText.isEmpty && !author.isEmpty {
                // Call the global function addQuote to submit the quote
                addQuote(text: quoteText, author: author, classification: category.rawValue.lowercased()) { success, error in
                    if success {
                        // Show success message using SwiftUI alert
                        let alert = NSAlert()
                        alert.messageText = "Submission Received"
                        alert.informativeText = "Thanks for submitting a quote. It is now awaiting approval to be added to this app's quote database."
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    } else if let error = error {
                        // Show error message using SwiftUI alert
                        let alert = NSAlert()
                        alert.messageText = "Submission Error"
                        alert.informativeText = error.localizedDescription
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    } else {
                        // Show unknown error message using SwiftUI alert
                        let alert = NSAlert()
                        alert.messageText = "Unknown Error"
                        alert.informativeText = "An unknown error occurred."
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            } else {
                // Show error message if quote text or author is empty using SwiftUI alert
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Please enter both quote text and author."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        })
        
        if let window = NSApplication.shared.mainWindow {
            window.beginSheet(submitQuoteWindow) { _ in }
        }
    }


    // Method to display submission alert
    func showSubmissionAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Submission Received"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}


struct SubmitQuoteWindow: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var quoteText = ""
    @State private var author = ""
    @State private var selectedClassification: QuoteClassification? = nil // Change selectedCategory to selectedClassification
    
    var body: some View {
        VStack {
            Text("Submit Quote")
                .font(.title)
                .padding()
            
            TextField("Quote Text", text: $quoteText)
                .padding()
            
            TextField("Author", text: $author)
                .padding()
            
            Picker("Classification", selection: $selectedClassification) {
                ForEach(QuoteClassification.allCases, id: \.self) { classification in
                    Text(classification.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                
                Button("Submit") {
                    guard let classification = selectedClassification else { // Change category to classification
                        // Show an alert indicating category selection is required
                        return
                    }
                    // Call the function to submit the quote
                    addQuote(text: quoteText, author: author, classification: classification.classification) { success, error in
                        if success {
                            // Show success message
                            let alert = NSAlert()
                            alert.messageText = "Submission Received"
                            alert.informativeText = "Thanks for submitting a quote. It is now awaiting approval to be added to this app's quote database."
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        } else if let error = error {
                            // Show error message
                            let alert = NSAlert()
                            alert.messageText = "Submission Error"
                            alert.informativeText = error.localizedDescription
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        } else {
                            // Show unknown error message
                            let alert = NSAlert()
                            alert.messageText = "Unknown Error"
                            alert.informativeText = "An unknown error occurred."
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}



struct SubmitQuoteWindow_Previews: PreviewProvider {
    static var previews: some View {
        SubmitQuoteWindow()
    }
}
