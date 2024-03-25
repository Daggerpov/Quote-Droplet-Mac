//
//  ContentView.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import SwiftUI
import ServiceManagement

struct QuoteView: View {
    
    
    @State private var quoteString = "No Quote Found"
    @State private var author: String? = nil
    @State private var fetching = false
    @AppStorage("quoteClassification") var quoteClassification: QuoteClassification = .everything
    
    @Environment(\.colorScheme) private var colorScheme
    let quotes: [QuoteJSON] // Add quotes as a parameter
    
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
                            Text(item.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(item == quoteClassification ?
                                    (colorScheme == .light ? Color(red: 0.0, green: 0.1, blue: 0.4) : .blue) :
                                    (colorScheme == .light ? .black : .primary))
                        }
                        if isUpdatingLaunchAtLogin {
                            ProgressView()
                                .foregroundColor(.blue)
                                .padding(.trailing, 10)
                        }
                        Image("QuoteDroplet")
                            .resizable()
                            .frame(width: 100, height: 100)
                    }
                    .padding(.horizontal, 8)
                    
                    HStack (alignment: .top) {
                        VStack (alignment: .trailing) {
                            ForEach(QuoteClassification.allCases, id: \.self) { item in
                                Button {
                                    quoteClassification = item
                                    Task {
                                        await getQuote(quoteClassification.classification)
                                    }
                                } label: {
                                    Text(item.rawValue)
                                        .foregroundColor(item == quoteClassification ?
                                                         (colorScheme == .light ? Color(red: 0.0, green: 0.1, blue: 0.4) : .blue) :
                                                            (colorScheme == .light ? .black : .primary))
                                }
                            }
                        }
                        .padding(.horizontal, 8)
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
                            Text(item.rawValue)
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
                            Text(item.rawValue)
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
                        .font(.system(size: 20))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(textColor) // Use the dynamic text color
                        .padding(.horizontal, 8)
                    Spacer()
                        .frame(height: 5) // Adjust the height as needed
                    Text(author ?? "") // Don't show author if blank
                        .font(.system(size: 14))
                        .foregroundColor(textColor) // Use the dynamic text color
                }
                
                .id(UUID())
            }
        }
        .onChange(of: launchAtLogin) { newValue in
            // Update the updatedLaunchAtLogin immediately
            updatedLaunchAtLogin = newValue
            
            isUpdatingLaunchAtLogin = true
            // Save the updated launchAtLogin value to UserDefaults
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: "launchAtLoginUserDefault")
            
            // Update the launch at login setting
            SMLoginItemSetEnabled(Constants.helperBundleID as CFString, newValue)
            
            // Set a delay to simulate an asynchronous process (replace this with the actual completion callback)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isUpdatingLaunchAtLogin = false
                launchAtLogin = updatedLaunchAtLogin // Update launchAtLogin to reflect the latest value
            }
        }
        .frame(minWidth: 250, idealWidth: 250, maxWidth: .infinity, minHeight: 250, idealHeight: 250, maxHeight: .infinity) // Adjust the frame sizes
        .task {
            await getQuote(quoteClassification.classification)
        }
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

}

struct QuoteView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleQuotes: [QuoteJSON] = [
            QuoteJSON(id: 102, text: "Do it or do not do it—you will regret both.", author: "Soren Kierkegaard", classification: "wisdom"),
            QuoteJSON(id: 163, text: "I can see the sun, but even if I cannot see the sun, I know that it exists. And to know that the sun is there—that is living.", author: "Fyodor Dostoyevsky", classification: "upliftment"),
            
        ]
        
        return QuoteView(quotes: sampleQuotes)
            .frame(width: 225, height: 225)
    }
}
