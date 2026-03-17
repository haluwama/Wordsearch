//
//  GeographyCityCatalog.swift
//  Wordsearch
//
//  Created by Codex on 17/03/2026.
//

import Foundation

struct GeographyCityCatalog {
    let citiesByRegion: [GeographyRegion: [CityEntry]]

    init(cities: [CityEntry]) {
        var uniqueCities: [String: CityEntry] = [:]

        for city in cities {
            uniqueCities[city.puzzleWord] = uniqueCities[city.puzzleWord] ?? city
        }

        var grouped = Dictionary(uniqueKeysWithValues: GeographyRegion.allCases.map { ($0, [CityEntry]()) })

        for city in uniqueCities.values {
            grouped[city.region, default: []].append(city)
        }

        self.citiesByRegion = grouped.mapValues { cities in
            cities.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        }
    }

    func cities(in region: GeographyRegion) -> [CityEntry] {
        citiesByRegion[region] ?? []
    }

    static func load(bundle: Bundle = .main) throws -> GeographyCityCatalog {
        guard let url = bundle.url(forResource: "countries", withExtension: "json") else {
            throw GeographyCatalogError.missingCountriesFile
        }

        let data = try Data(contentsOf: url)
        return try load(data: data)
    }

    static func load(data: Data) throws -> GeographyCityCatalog {
        let decoder = JSONDecoder()
        let countries = try decoder.decode([CountryRecord].self, from: data)

        let cities = countries.compactMap { country -> CityEntry? in
            guard let capital = country.capital?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return nil
            }

            guard !capital.isEmpty else {
                return nil
            }

            guard let region = GeographyRegion(rawValue: country.region) else {
                return nil
            }

            let normalized = capital.normalizedPuzzleWord

            guard (4...10).contains(normalized.count) else {
                return nil
            }

            return CityEntry(displayName: capital, region: region, countryName: country.name)
        }

        return GeographyCityCatalog(cities: cities)
    }
}

enum GeographyCatalogError: LocalizedError {
    case missingCountriesFile

    var errorDescription: String? {
        switch self {
        case .missingCountriesFile:
            return "countries.json is missing from the app bundle."
        }
    }
}

private struct CountryRecord: Decodable {
    let name: String
    let capital: String?
    let region: String
}
