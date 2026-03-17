//
//  GeographyPuzzleTests.swift
//  WordsearchTests
//
//  Created by Codex on 17/03/2026.
//

import Testing
@testable import Wordsearch

struct GeographyPuzzleTests {
    @Test func normalizesPuzzleWords() {
        #expect("São Tomé".normalizedPuzzleWord == "SAOTOME")
        #expect("Port-of-Spain".normalizedPuzzleWord == "PORTOFSPAIN")
    }

    @Test func buildsPuzzleWithBalancedDistractors() throws {
        let catalog = GeographyCityCatalog(
            cities: [
                CityEntry(displayName: "Paris", region: .europe, countryName: "France"),
                CityEntry(displayName: "Madrid", region: .europe, countryName: "Spain"),
                CityEntry(displayName: "Warsaw", region: .europe, countryName: "Poland"),
                CityEntry(displayName: "Rome", region: .europe, countryName: "Italy"),
                CityEntry(displayName: "Cairo", region: .africa, countryName: "Egypt"),
                CityEntry(displayName: "Rabat", region: .africa, countryName: "Morocco"),
                CityEntry(displayName: "Tokyo", region: .asia, countryName: "Japan"),
                CityEntry(displayName: "Seoul", region: .asia, countryName: "South Korea"),
                CityEntry(displayName: "Quito", region: .americas, countryName: "Ecuador"),
                CityEntry(displayName: "Ottawa", region: .americas, countryName: "Canada"),
                CityEntry(displayName: "Suva", region: .oceania, countryName: "Fiji"),
                CityEntry(displayName: "Apia", region: .oceania, countryName: "Samoa")
            ]
        )

        var generator = SeededGenerator(seed: 42)
        let factory = GeographyPuzzleFactory(
            catalog: catalog,
            configuration: .init(
                targetCityCount: 3,
                distractorCityCount: 4,
                minimumGridSize: 8,
                placementAttemptsPerSize: 40,
                maximumGridGrowth: 2
            )
        )

        let puzzle = try factory.makePuzzle(for: .europe, using: &generator)

        #expect(puzzle.targetCities.count == 3)
        #expect(puzzle.wordBank.count == 7)
        #expect(Set(puzzle.targetCities.map(\.region)) == Set([GeographyRegion.europe]))
        #expect(Set(puzzle.wordBank.filter { !puzzle.targetCityIDs.contains($0.id) }.map(\.region)).count >= 3)

        for hiddenCity in puzzle.hiddenCities {
            let letters = hiddenCity.points.map { point in
                puzzle.grid[point.row][point.column]
            }

            #expect(String(letters) == hiddenCity.city.puzzleWord)
        }
    }
}
