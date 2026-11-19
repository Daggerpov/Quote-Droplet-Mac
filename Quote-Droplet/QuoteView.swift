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

/// Colors for the menu bar card. Dark mode uses the iOS app's Espresso palette (the warm wood
/// tones this app always had), light mode its Linen palette.
struct MenuPalette {
    let background: Color
    let card: Color
    let text: Color
    let accent: Color
    let onAccent: Color

    static let espresso = MenuPalette(
        background: Color(red: 0x3A / 255, green: 0x2C / 255, blue: 0x24 / 255),
        card: Color(red: 0x47 / 255, green: 0x39 / 255, blue: 0x31 / 255),
        text: Color(red: 0xF7 / 255, green: 0xEE / 255, blue: 0xDD / 255),
        accent: Color(red: 0xE8 / 255, green: 0xB6 / 255, blue: 0x6B / 255),
        onAccent: Color(red: 0x15 / 255, green: 0x15 / 255, blue: 0x1A / 255)
    )
    static let linen = MenuPalette(
        background: Color(red: 0xF6 / 255, green: 0xF0 / 255, blue: 0xE6 / 255),
        card: Color(red: 0xFC / 255, green: 0xFA / 255, blue: 0xF6 / 255),
        text: Color(red: 0x3A / 255, green: 0x2E / 255, blue: 0x27 / 255),
        accent: Color(red: 0xA9 / 255, green: 0x49 / 255, blue: 0x2A / 255),
        onAccent: .white
    )

    static func forScheme(_ scheme: ColorScheme) -> MenuPalette {
        scheme == .dark ? .espresso : .linen
    }
}

struct QuoteView: View {
    @State private var quoteString = "No Quote Found"
    @State private var author: String? = nil
    @State private var fetching = false
    @State private var copied = false
    @FocusState private var focusedField: Bool
    @AppStorage("quoteClassification") var quoteClassification: QuoteClassification = .everything

    @State private var notificationTime = Date()

    @Environment(\.colorScheme) private var colorScheme
    let quotes: [QuoteJSON] // Add quotes as a parameter

    @State private var quoteCounts: [QuoteClassification: Int] = [QuoteClassification.discipline: 96]

    init(quotes: [QuoteJSON]) { // Initialize QuoteView with quotes
        self.quotes = quotes
    }

    private var palette: MenuPalette { .forScheme(colorScheme) }

    /// "All" first, then the categories alphabetically.
    private var categoryOrder: [QuoteClassification] {
        [.everything] + QuoteClassification.allCases.filter { $0 != .everything }.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            categoryChips
            quoteCard
            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
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
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "drop.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(palette.accent)
            Text("Quote Droplet")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(palette.text)
            Spacer()
        }
    }

    /// The categories as chips, four per row (plain buttons work reliably inside a menu).
    private var categoryChips: some View {
        let rows = stride(from: 0, to: categoryOrder.count, by: 4).map { Array(categoryOrder[$0..<min($0 + 4, categoryOrder.count)]) }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        let isSelected = item == quoteClassification
                        Button {
                            quoteClassification = item
                            Task {
                                await getQuote(quoteClassification.classification)
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(isSelected ? palette.onAccent : palette.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(isSelected ? palette.accent : palette.card))
                                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : palette.text.opacity(0.10), lineWidth: 1))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("\(quoteCounts[item] ?? 0) quotes")
                    }
                }
            }
        }
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(palette.accent.opacity(0.75))
            if fetching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(quoteString)
                    .font(.system(size: 200, design: .serif)) // scaled down to fit, like the iOS widget
                    .lineSpacing(2)
                    .lineLimit(nil)
                    .foregroundColor(palette.text)
                    .minimumScaleFactor(0.01)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .id(quoteString)
                    .transition(.opacity)
                if (isAuthorValid(authorGiven: author)) {
                    Text("— \(author ?? "")")  // Don't show author if blank
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(palette.accent)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.text.opacity(0.10), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            iconButton(copied ? "checkmark" : "doc.on.doc", help: "Copy quote") {
                let authorForSharing = (isAuthorValid(authorGiven: author)) ? author : ""
                let wholeAuthorText = (authorForSharing != "") ? "\n— \(authorForSharing ?? "Unknown Author")" : ""
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(quoteString)\(wholeAuthorText)", forType: .string)
                withAnimation(.easeOut(duration: 0.15)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation(.easeOut(duration: 0.2)) { copied = false }
                }
            }
            iconButton("arrow.clockwise", help: "New quote") {
                Task {
                    await getQuote(quoteClassification.classification)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(palette.accent)
                Text("Daily at")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.text.opacity(0.75))
                DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.stepperField)
                    .labelsHidden()
                    .focused($focusedField, equals: true)
                    .fixedSize()
            }
            .help("Time of your daily quote notification")
        }
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(palette.text)
                .frame(width: 30, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(palette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(palette.text.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
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
            .frame(width: 340, height: 340)
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
