//
//  ContentView.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import Foundation
import StoreKit

struct QuoteView: View {
    
    
    @State private var quoteString = "No Quote Found"
    @State private var author: String? = nil
    @State private var fetching = false
    @FocusState private var isDatePickerFocused: Bool
    @FocusState private var focusedField: Bool
    @AppStorage("quoteClassification") var quoteClassification: QuoteClassification = .everything
    
    @State private var notificationTime = Date()
    
    @Environment(\.colorScheme) private var colorScheme
    let quotes: [QuoteJSON] // Add quotes as a parameter
    
    @State private var quoteCounts: [QuoteClassification: Int] = [QuoteClassification.discipline: 96]
    
    init(quotes: [QuoteJSON]) { // Initialize QuoteView with quotes
        self.quotes = quotes
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                VStack {
                    ForEach(QuoteClassification.allCases.prefix(3), id: \.self) { item in
                        Button {
                            quoteClassification = item
                            Task {
                                await getQuote(quoteClassification.classification)
                            }
                        } label: {
                            Text("\(item.rawValue) (\(quoteCounts[item] ?? 0))")
                                .font(.system(size: 11))
                                .foregroundColor(item == quoteClassification ?
                                                 (colorScheme == .light ? Color(red: 0.0, green: 0.1, blue: 0.4) : .blue) :
                                                    (colorScheme == .light ? .black : .primary))
                        }
                    }
                }
                
                VStack {
                    ForEach(QuoteClassification.allCases.dropFirst(3).prefix(3), id: \.self) { item in
                        Button {
                            quoteClassification = item
                            Task {
                                await getQuote(quoteClassification.classification)
                            }
                        } label: {
                            Text("\(item.rawValue) (\(quoteCounts[item] ?? 0))")
                                .font(.system(size: 11))
                                .foregroundColor(item == quoteClassification ?
                                                 (colorScheme == .light ? Color(red: 0.0, green: 0.1, blue: 0.4) : .blue) :
                                                    
                                                    (colorScheme == .light ? .black : .primary))
                        }
                    }
                }
                
                VStack {
                    ForEach(QuoteClassification.allCases.dropFirst(6).prefix(3), id: \.self) { item in
                        Button {
                            quoteClassification = item
                            Task {
                                await getQuote(quoteClassification.classification)
                            }
                        } label: {
                            Text("\(item.rawValue) (\(quoteCounts[item] ?? 0))")
                                .font(.system(size: 11))
                                .foregroundColor(item == quoteClassification ?
                                                 (colorScheme == .light ? Color(red: 0.0, green: 0.1, blue: 0.4) : .blue) :
                                                    
                                                    (colorScheme == .light ? .black : .primary))
                        }
                    }
                }
            }
            Spacer()
            
            if fetching {
                ProgressView()
            } else {
                VStack {
                    Text(quoteString)
                        .font(.system(size: 500)) // previously 20
                        .lineLimit(nil)
                        .foregroundColor(textColor) // Use the dynamic text color
                        .minimumScaleFactor(0.01) // ! previously 0.5
                        .frame(alignment: .center)
                    Spacer()
                        .frame(height: 5) // Adjust the height as needed
                    if (isAuthorValid(authorGiven: author)) {
                        Text("— \(author ?? "")")  // Don't show author if blank
                            .font(.system(size: 14))
                            .foregroundColor(textColor) // Use the dynamic text color
                    } else {
//                        Text("")  // Don't show author if blank
//                            .font(.system(size: 14))
//                            .foregroundColor(textColor) // Use the dynamic text color
                        // commented out, since I don't really need any text there if there isn't an author.
                    }
                }
                .id(UUID())
            }
            Spacer()
            HStack{
                let authorForSharing = (isAuthorValid(authorGiven: author)) ? author : ""
                let wholeAuthorText = (authorForSharing != "") ? "\n— \(authorForSharing ?? "Unknown Author")" : ""
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(quoteString)\(wholeAuthorText)",
                                                   forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.title)
                        .scaleEffect(1)
                }.padding(.leading, 5)
                //                Text("Schedule Notifications").overlay {
                if #available(macOS 13.0, *) {
                    Form{
                        DatePicker("Schedule Notifications:", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.stepperField)
                            .focused($focusedField, equals: true)
                    }.defaultFocus($focusedField, true)
                } else {
                    // Fallback on earlier versions
                    DatePicker("Schedule Notifications:", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                }
                
            }
        }
        .padding()
        .task {
            await getQuote(quoteClassification.classification)
            await countQuotesByClassification()
        }
        .onAppear() {
            if NotificationScheduler.isDefaultConfigOverwritten {
                notificationTime = NotificationScheduler.previouslySelectedNotificationTime
            } else {
                notificationTime = NotificationScheduler.defaultScheduledNotificationTime
            }
            isDatePickerFocused = true
            focusedField = true
        }
        .onChange(of: quoteClassification, perform: { value in
                NotificationScheduler.shared.scheduleNotifications(
                    notificationTime:
                        notificationTime,
                    quoteCategory:
                        quoteClassification.toQuoteCategory() ?? QuoteCategory.all,
                    defaults: false
                )
            }
        )
        .onChange(of: notificationTime, perform: { value in
                NotificationScheduler.shared.scheduleNotifications(
                    notificationTime:
                        notificationTime,
                    quoteCategory:
                        quoteClassification.toQuoteCategory() ?? QuoteCategory.all,
                    defaults: false
                )
            }
        )
        .background(backgroundColor) // Set the background color based on colorScheme
        .environment(\.colorScheme, .dark) // Set the default color scheme to dark mode for testing
    }
    
    // Compute the dynamic text color based on the color scheme
    private var textColor: Color {
        if colorScheme == .dark {
            // Use white text for dark mode
            return .white
        } else {
            // Use black text for light mode
            return .black
        }
    }
    
    // Compute the dynamic background color based on the color scheme
    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.15, green: 0.1, blue: 0.05) // Dark wood color
        } else {
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Light wood color
        }
    }
    
    func getQuote(_ classification: String) async {
        if classification.lowercased() == "all" {
            guard let randomQuote = quotes.randomElement() else {
                quoteString = "No Quote Found"
                author = nil
                return
            }
            // Assign the quote and author
            quoteString = randomQuote.text
            author = randomQuote.author == "Unknown Author" ? nil : randomQuote.author
        } else {
            // Fetch a random quote with the specified classification
            let filteredQuotes = quotes.filter { $0.classification.lowercased() == classification.lowercased() }
            guard let randomQuote = filteredQuotes.randomElement() else {
                quoteString = "No Quote Found"
                author = nil
                return
            }
            
            // Assign the quote and author
            quoteString = randomQuote.text
            author = randomQuote.author == "Unknown Author" ? nil : randomQuote.author
        }
    }
    
    func countQuotesByClassification() async {
        quoteCounts = [:]
        for quote in quotes {
            var capitalizedClassification = quote.classification
            capitalizedClassification.capitalizeFirstLetter()
            
            let classification = QuoteClassification(rawValue: capitalizedClassification) ?? .everything
            quoteCounts[classification, default: 0] += 1
            quoteCounts[QuoteClassification.everything, default: 0] += 1
        }
    }
}

struct QuoteView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleQuotes: [QuoteJSON] = [
            QuoteJSON(id: 102, text: "Do it or do not do it—you will regret both.", author: "Soren Kierkegaard", classification: "wisdom"),
            QuoteJSON(id: 163, text: "I can see the sun, but even if I cannot see the sun, I know that it exists. And to know that the sun is there—that is living.", author: "Fyodor Dostoyevsky", classification: "upliftment"),
            
        ]
        
        return QuoteView(quotes: sampleQuotes)
            .frame(width: 300, height: 225) // ! previous width of 225
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
