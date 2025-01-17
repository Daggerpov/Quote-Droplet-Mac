//
//  JSONHelper.swift
//  Quote Droplet
//
//  Created by Daniel Agapov on 2024-07-20.
//

import SwiftUI
import WidgetKit
import UserNotifications
import Foundation

struct QuoteJSON: Codable {
    let id: Int
    var text: String
    var author: String
    let classification: String
}


extension Quote {
    func toQuoteJSON() -> QuoteJSON {
        return QuoteJSON(id: self.id, text: self.text, author: self.author ?? "", classification: self.classification ?? "")
    }
}

extension QuoteJSON {
    func toQuote() -> Quote {
        return Quote(id: self.id, text: self.text, author: self.author, classification: self.classification)
    }
}

func loadQuotesFromJSON() -> [QuoteJSON] {
    // Load quotes from JSON file
    guard let path = Bundle.main.path(forResource: "QuotesBackup", ofType: "json") else {
        print("Error: Unable to locate quotes.json")
        return []
    }
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        return try decoder.decode([QuoteJSON].self, from: data) // quotes
    } catch {
        print("Error decoding quotes JSON: \(error.localizedDescription)")
    }
    return []
}

//
//func getLikedQuotes() -> [Quote] {
//    @AppStorage("likedQuotes", store: UserDefaults(suiteName: "group.selectedSettings"))
//    var likedQuotesData: Data = Data()
//    if let quotes = try? JSONDecoder().decode([Quote].self, from: likedQuotesData) {
//        return quotes
//    }
//    return []
//}
//
//func saveLikedQuotes(_ quotes: [Quote]) {
//    @AppStorage("likedQuotes", store: UserDefaults(suiteName: "group.selectedSettings"))
//    var likedQuotesData: Data = Data()
//    if let data = try? JSONEncoder().encode(quotes) {
//        likedQuotesData = data
//    }
//}
//
////func isQuoteLiked(_ quote: Quote) -> Bool {
////    return getLikedQuotes().contains(where: { $0.id == quote.id })
////}
////
////func isQuoteBookmarked(_ quote: Quote) -> Bool {
////    return getBookmarkedQuotes().contains(where: { $0.id == quote.id })
////}
