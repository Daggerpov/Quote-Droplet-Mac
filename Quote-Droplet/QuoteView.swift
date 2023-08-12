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
    
    @State private var launchAtLogin = false {
        didSet {
            SMLoginItemSetEnabled(Constants.helperBundleID as CFString, launchAtLogin)
        }
    }
    
    private struct Constants {
        static let helperBundleID = "com.Daggerpov.Quote-Droplet"
    }
    
    // Load the launchAtLogin value from UserDefaults
    init() {
        let defaults = UserDefaults.standard
        _launchAtLogin = State(initialValue: defaults.bool(forKey: "launchAtLoginUserDefault"))
    }
    
    @State private var isUpdatingLaunchAtLogin = false
    @State private var updatedLaunchAtLogin = false
    
    var body: some View {
        VStack {
            ZStack {
                Toggle(isOn: $launchAtLogin) {
                    Text(" Launch at Login")
                }
                if isUpdatingLaunchAtLogin {
                    ProgressView()
                        .foregroundColor(.blue) 
                        .padding(.trailing, 10)
                }
            }
            HStack(alignment: .top) {
                Image("QuoteDroplet")
                    .resizable()
                    .frame(width: 100, height: 100)
                Spacer()
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
            }
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
                    Text(author ?? "Unknown Author")
                        .font(.system(size: 14))
                        .foregroundColor(textColor) // Use the dynamic text color
                }
                .id(UUID())
            }
            Spacer()
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
                    author = quote.author // Assign the optional author name
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
