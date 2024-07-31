//
//  Quote_DropletApp.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import SwiftUI
import UserNotifications

@main
struct Quote_DropletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var instance: AppDelegate!
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = ApplicationMenu()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        statusBarItem.button?.image = NSImage(named: NSImage.Name("QuoteDropletSmall"))
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.menu = menu.createMenu()
        
        // auto-start:
        
        let mainAppIdentifier = "com.Daggerpov.Quote-Droplet"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
        
        
        if !isRunning {
            var pathComponents = (Bundle.main.bundlePath as NSString).pathComponents
            pathComponents.removeLast()
            pathComponents.removeLast()
            pathComponents.removeLast()
            pathComponents.removeLast()
            let newPath = NSString.path(withComponents: pathComponents)
            
            NSWorkspace.shared.launchApplication(newPath)
        }
        
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
//                print("All set!")
                // what was previously in `registerNotifications()` function call is this 3-line block:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                if #available(iOS 15, *) {
                    NotificationScheduler.shared.scheduleNotifications()
                } else {
                    // Fallback on earlier versions
                }
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
}

