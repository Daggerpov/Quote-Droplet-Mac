//
//  ContentView.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import SwiftUI

struct QuoteView: View {
    @State private var quoteString = "No Quote Found"
    @State private var author: String? = nil
    @State private var fetching = false
    @AppStorage("quoteClassification") var quoteClassification: QuoteClassification = .everything
    
    @Environment(\.colorScheme) private var colorScheme
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
                    Spacer()
                        .frame(height: 5) // Adjust the height as needed
                    Text(author ?? "") // Don't show author if blank
                        .font(.system(size: 14))
                        .foregroundColor(textColor) // Use the dynamic text color
                }
                .id(UUID())
            }
            Spacer()
        }
        .padding()
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
        fetching.toggle()
        defer {
            fetching.toggle()
        }
        do {
            let (quote, error) = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<(Quote?, Error?), Error>) -> Void in
                getRandomQuoteByClassification(classification: classification) { quote, error in
                    continuation.resume(returning: (quote, error))
                }
            }
            
            if let quote = quote {
                quoteString = quote.text
                if quote.author == "Unknown Author" {
                    author = nil // Leave the optional author name blank
                } else {
                    author = quote.author // Assign the author name
                }
            } else {
                quoteString = "No Quote Found"
                author = nil // Reset the optional author name
            }
            
            if let error = error {
                throw error
            }
        } catch {
            quoteString = error.localizedDescription
            author = nil // Reset the optional author name in case of an error
        }
    }


}

struct QuoteView_Previews: PreviewProvider {
    static var previews: some View {
        QuoteView()
            .frame(width: 225, height: 225)
    }
}
