//
//  ContentView.swift
//  Quote-Droplet
//
//  Created by Daniel Agapov on 2023-04-05.
//

import SwiftUI

struct QuoteView: View {
    @State private var quoteString = "No Quote Found"
    @State private var fetching = false
    @AppStorage("quoteClassification") var quoteClassification: QuoteClassification = .everything
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image("StewartLynch")
                    .resizable()
                    .frame(width: 60, height: 60)
                VStack {
                    ForEach(QuoteClassification.allCases, id: \.self) {
                        item in
                        Button {
                            quoteClassification = item
                            Task {
                                await getQuote(quoteClassification.classification)
                            }
                        } label: {
                            Text(item.rawValue)
                                .foregroundColor(item == quoteClassification ? .red : Color.primary)
                        }
                    }
                }
            }
            if fetching {
                ProgressView()
            } else {
                Text(quoteString)
                    .font(.system(size: 20)) // Adjust the font size as needed
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5)
            }
            Spacer()
        }
        .padding()
        .task {
            await getQuote(quoteClassification.classification)
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
            } else {
                quoteString = "No Quote Found"
            }
            if let error = error {
                throw error
            }
        } catch {
            quoteString = error.localizedDescription
        }
    }


}

struct QuoteView_Previews: PreviewProvider {
    static var previews: some View {
        QuoteView()
            .frame(width: 225, height: 225)
    }
}
