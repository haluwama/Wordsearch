//
//  GeographyModels.swift
//  Wordsearch
//
//  Created by Codex on 17/03/2026.
//

import Foundation

enum GeographyRegion: String, CaseIterable, Codable, Identifiable {
    case africa = "Africa"
    case americas = "Americas"
    case asia = "Asia"
    case europe = "Europe"
    case oceania = "Oceania"

    var id: String { rawValue }

    var challengeTitle: String {
        "Find the \(rawValue) cities"
    }

    var lowercasedName: String {
        rawValue.lowercased()
    }
}

struct CityEntry: Identifiable, Hashable {
    let id: String
    let displayName: String
    let puzzleWord: String
    let region: GeographyRegion
    let countryName: String

    init(displayName: String, region: GeographyRegion, countryName: String) {
        self.displayName = displayName
        self.puzzleWord = displayName.normalizedPuzzleWord
        self.region = region
        self.countryName = countryName
        self.id = "\(region.rawValue)-\(self.puzzleWord)"
    }
}

extension String {
    var normalizedPuzzleWord: String {
        folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        .uppercased()
        .unicodeScalars
        .filter { scalar in
            CharacterSet.letters.contains(scalar) && scalar.isASCII
        }
        .map(String.init)
        .joined()
    }
}
