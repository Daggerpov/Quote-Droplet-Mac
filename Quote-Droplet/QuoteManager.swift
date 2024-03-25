//
//  QuoteManager.swift
//  Quote Droplet
//
//  Created by Daniel Agapov on 2024-03-22.
//

import Foundation
import UserNotifications

class QuoteManager {
    static let shared = QuoteManager()
    
    private var quotes = [QuoteJSON]()
    
    private init() {
        loadQuotesFromJSON()
    }
    
    private func loadQuotesFromJSON() {
        // Load quotes from JSON file
        guard let path = Bundle.main.path(forResource: "QuotesBackup", ofType: "json") else {
            print("Error: Unable to locate quotes.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            self.quotes = try decoder.decode([QuoteJSON].self, from: data)
        } catch {
            print("Error decoding quotes JSON: \(error.localizedDescription)")
        }
    }
}

struct QuoteJSON: Codable {
    let id: Int
    let text: String
    let author: String
    let classification: String
}
