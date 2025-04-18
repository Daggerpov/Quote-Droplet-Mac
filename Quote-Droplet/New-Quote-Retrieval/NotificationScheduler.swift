//
//  NotificationScheduler.swift
//  Quote Droplet
//
//  Created by Daniel Agapov on 2024-03-22.
//

import Foundation
import UserNotifications
import SwiftUI
import WidgetKit
import Foundation

let notificationPermissionKey = "notificationPermissionGranted"
let notificationToggleKey = "notificationToggleEnabled"
private var scheduledNotificationIDs: Set<String> = Set() // for the quotes shown already

class NotificationScheduler {
    static let shared = NotificationScheduler()
    
    // notifications default settings:
    private var defaultNotificationTime: Date = Calendar.current.date(byAdding: .minute, value: 3, to: Date.now) ?? Date.now
    private var defaultQuoteCategory: QuoteCategory = QuoteCategory.all
    
    public static var isDefaultConfigOverwritten: Bool = false
    
    public static var previouslySelectedNotificationTime: Date = Calendar.current.date(byAdding: .minute, value: 3, to: Date.now) ?? Date.now
    public static var previouslySelectedNotificationCategory: QuoteCategory = QuoteCategory.all

    @AppStorage(notificationToggleKey, store: UserDefaults(suiteName: "group.selectedSettings"))
    var notificationToggleEnabled: Bool = false
    
    private var quotes = [QuoteJSON]()
    
    public static var defaultScheduledNotificationTime: Date = Calendar.current.date(byAdding: .minute, value: 3, to: Date.now) ?? Date.now
    
    private init() {
        quotes = loadQuotesFromJSON()
    }
    
    func scheduleNotifications() {
        // removed toggle check to make sure user has opted in; simply notififying no matter if opted in.
        if NotificationScheduler.isDefaultConfigOverwritten {
            scheduleNotifications(notificationTime: NotificationScheduler.previouslySelectedNotificationTime, quoteCategory: NotificationScheduler.previouslySelectedNotificationCategory, defaults: true)
        } else {
            scheduleNotifications(notificationTime: defaultNotificationTime, quoteCategory: defaultQuoteCategory, defaults: true)
        }
    }
    
    
    func scheduleNotifications(notificationTime: Date, quoteCategory: QuoteCategory, defaults: Bool) {
        if defaults == false {
            NotificationScheduler.previouslySelectedNotificationTime = notificationTime
            NotificationScheduler.previouslySelectedNotificationCategory = quoteCategory
            NotificationScheduler.isDefaultConfigOverwritten = true
        }
        
        // Cancel existing notifications to reschedule them with the new time
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let classification = quoteCategory.displayName
        
        // Create a calendar instance
        let calendar = Calendar.current
        
        // Get the current date
        let currentDate = Date()
        
        // Iterate over 60 days
        for i in 0..<60 {
            // Calculate the trigger date for the current notification
            guard let futureDate = calendar.date(byAdding: .day, value: i, to: currentDate) else {
                print("Error: Unable to calculate future date.")
                continue
            }
            
            var triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            triggerDate.year = calendar.component(.year, from: futureDate)
            triggerDate.month = calendar.component(.month, from: futureDate)
            triggerDate.day = calendar.component(.day, from: futureDate)
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "sound-for-noti-water-drip-pixabay.mp3"))
            
            let shortQuotes = quotes.filter { $0.text.count <= 100 }
            
            // Fetch a random quote for the specified classification
            var randomQuote: QuoteJSON
            if classification.lowercased() == "all" {
                guard let randomElement = shortQuotes.randomElement() else {
                    print("Error: Unable to retrieve a random quote.")
                    continue
                }
                randomQuote = randomElement
                content.title = "Quote Droplet"
            } else {
                let filteredQuotes = shortQuotes.filter { $0.classification.lowercased() == classification.lowercased() }
                guard let randomElement = filteredQuotes.randomElement() else {
                    print("Error: Unable to retrieve a random quote.")
                    continue
                }
                randomQuote = randomElement
                content.title = "Quote Droplet: \(classification)"
            }
            
            if isAuthorValid(authorGiven: randomQuote.author) {
                content.body = "\(randomQuote.text)\n— \(randomQuote.author)"
            } else {
                content.body = "\(randomQuote.text)"
            }
            
            // Create notification trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            // Generate a unique identifier for this notification
            let notificationID = UUID().uuidString
            
            // Create notification request
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }

}

