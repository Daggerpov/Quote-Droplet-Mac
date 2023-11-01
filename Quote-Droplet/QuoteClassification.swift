//
//  QuoteClassification.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import Foundation

enum QuoteClassification: String, Codable, CaseIterable {
    case
    motivation = "Motivation",
    inspiration = "Inspiration",
    philosophy = "Philosophy",
    discipline = "Discipline",
    wisdom = "Wisdom",
    upliftment = "Upliftment",
    everything = "All"
    
    var classification: String {
        switch self {
        case .motivation:
            return "motivation"
        case .inspiration:
            return "inspiration"
        case .philosophy:
            return "philosophy"
        case .discipline:
            return "discipline"
        case .wisdom:
            return "wisdom"
        case .upliftment:
            return "upliftment"
        case .everything:
            return "all"
        }
    }
}

