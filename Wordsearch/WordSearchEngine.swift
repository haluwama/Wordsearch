//
//  WordSearchEngine.swift
//  Wordsearch
//
//  Created by Codex on 17/03/2026.
//

import Foundation

struct GridPoint: Hashable {
    let row: Int
    let column: Int
}

struct HiddenCity: Hashable {
    let city: CityEntry
    let points: [GridPoint]
}

struct GeographyPuzzle {
    let region: GeographyRegion
    let size: Int
    let grid: [[Character]]
    let hiddenCities: [HiddenCity]
    let wordBank: [CityEntry]
    let targetCityIDs: Set<String>

    var targetCities: [CityEntry] {
        hiddenCities.map(\.city).filter { targetCityIDs.contains($0.id) }
    }

    var distractorRegions: [GeographyRegion] {
        Array(
            Set(
                wordBank
                    .filter { !targetCityIDs.contains($0.id) }
                    .map(\.region)
            )
        )
        .sorted { $0.rawValue < $1.rawValue }
    }

    func line(from start: GridPoint, to end: GridPoint) -> [GridPoint]? {
        let rowDelta = end.row - start.row
        let columnDelta = end.column - start.column

        let isStraight = rowDelta == 0 || columnDelta == 0 || abs(rowDelta) == abs(columnDelta)
        guard isStraight else {
            return nil
        }

        let steps = max(abs(rowDelta), abs(columnDelta))
        let rowStep = rowDelta == 0 ? 0 : rowDelta / abs(rowDelta)
        let columnStep = columnDelta == 0 ? 0 : columnDelta / abs(columnDelta)

        return (0...steps).map { index in
            GridPoint(
                row: start.row + (index * rowStep),
                column: start.column + (index * columnStep)
            )
        }
    }

    func city(on selection: [GridPoint]) -> HiddenCity? {
        hiddenCities.first { hiddenCity in
            hiddenCity.points == selection || hiddenCity.points.reversed().elementsEqual(selection)
        }
    }
}

enum GeographyPuzzleError: LocalizedError {
    case notEnoughCities(region: GeographyRegion)
    case notEnoughDistractorCities
    case couldNotPlaceCities

    var errorDescription: String? {
        switch self {
        case .notEnoughCities(let region):
            return "Not enough \(region.lowercasedName) cities are available to build this puzzle."
        case .notEnoughDistractorCities:
            return "There are not enough distractor cities to mix into the puzzle."
        case .couldNotPlaceCities:
            return "The puzzle generator could not fit every city into the grid."
        }
    }
}

struct GeographyPuzzleFactory {
    struct Configuration {
        var targetCityCount = 6
        var distractorCityCount = 6
        var minimumGridSize = 12
        var placementAttemptsPerSize = 30
        var maximumGridGrowth = 3
    }

    let catalog: GeographyCityCatalog
    var configuration = Configuration()

    func makePuzzle(for region: GeographyRegion, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) throws -> GeographyPuzzle {
        var generator = SeededGenerator(seed: seed)
        return try makePuzzle(for: region, using: &generator)
    }

    func makePuzzle<R: RandomNumberGenerator>(
        for region: GeographyRegion,
        using generator: inout R
    ) throws -> GeographyPuzzle {
        let targetCities = try pickTargetCities(for: region, using: &generator)
        let distractorCities = try pickDistractorCities(excluding: region, using: &generator)
        let allCities = (targetCities + distractorCities).shuffled(using: &generator)
        let targetIDs = Set(targetCities.map(\.id))
        let baseSize = recommendedGridSize(for: allCities)

        for size in baseSize...(baseSize + configuration.maximumGridGrowth) {
            for _ in 0..<configuration.placementAttemptsPerSize {
                if let placement = tryPlace(cities: allCities, size: size, using: &generator) {
                    return GeographyPuzzle(
                        region: region,
                        size: size,
                        grid: placement.grid,
                        hiddenCities: placement.hiddenCities,
                        wordBank: allCities.shuffled(using: &generator),
                        targetCityIDs: targetIDs
                    )
                }
            }
        }

        throw GeographyPuzzleError.couldNotPlaceCities
    }

    private func pickTargetCities<R: RandomNumberGenerator>(
        for region: GeographyRegion,
        using generator: inout R
    ) throws -> [CityEntry] {
        let pool = catalog.cities(in: region)
        guard pool.count >= configuration.targetCityCount else {
            throw GeographyPuzzleError.notEnoughCities(region: region)
        }

        return Array(pool.shuffled(using: &generator).prefix(configuration.targetCityCount))
    }

    private func pickDistractorCities<R: RandomNumberGenerator>(
        excluding targetRegion: GeographyRegion,
        using generator: inout R
    ) throws -> [CityEntry] {
        var chosen: [CityEntry] = []
        var chosenIDs: Set<String> = []
        var distractorRegions = GeographyRegion.allCases.filter { $0 != targetRegion }

        distractorRegions.shuffle(using: &generator)

        while chosen.count < configuration.distractorCityCount {
            var addedCityThisRound = false

            for region in distractorRegions {
                let candidates = catalog
                    .cities(in: region)
                    .filter { !chosenIDs.contains($0.id) }

                guard let city = candidates.randomElement(using: &generator) else {
                    continue
                }

                chosen.append(city)
                chosenIDs.insert(city.id)
                addedCityThisRound = true

                if chosen.count == configuration.distractorCityCount {
                    break
                }
            }

            guard addedCityThisRound else {
                throw GeographyPuzzleError.notEnoughDistractorCities
            }

            distractorRegions.shuffle(using: &generator)
        }

        return chosen
    }

    private func recommendedGridSize(for cities: [CityEntry]) -> Int {
        let longestWord = cities.map { $0.puzzleWord.count }.max() ?? configuration.minimumGridSize
        let totalLetters = cities.reduce(0) { $0 + $1.puzzleWord.count }
        let densityTarget = Int(Double(totalLetters).squareRoot().rounded(.up)) + 4

        return max(configuration.minimumGridSize, longestWord + 2, densityTarget)
    }

    private func tryPlace<R: RandomNumberGenerator>(
        cities: [CityEntry],
        size: Int,
        using generator: inout R
    ) -> PlacementResult? {
        var grid = Array(
            repeating: Array<Character?>(repeating: nil, count: size),
            count: size
        )
        var hiddenCities: [HiddenCity] = []

        let citiesByLength = cities.sorted { lhs, rhs in
            if lhs.puzzleWord.count == rhs.puzzleWord.count {
                return lhs.puzzleWord < rhs.puzzleWord
            }

            return lhs.puzzleWord.count > rhs.puzzleWord.count
        }

        for city in citiesByLength {
            let letters = Array(city.puzzleWord)
            var candidates: [[GridPoint]] = []

            for row in 0..<size {
                for column in 0..<size {
                    let start = GridPoint(row: row, column: column)

                    for direction in Direction.allCases {
                        guard let points = pointsForPlacement(
                            letterCount: letters.count,
                            start: start,
                            direction: direction,
                            size: size
                        ) else {
                            continue
                        }

                        guard canPlace(letters: letters, at: points, in: grid) else {
                            continue
                        }

                        candidates.append(points)
                    }
                }
            }

            guard let selectedPoints = candidates.randomElement(using: &generator) else {
                return nil
            }

            for (index, point) in selectedPoints.enumerated() {
                grid[point.row][point.column] = letters[index]
            }

            hiddenCities.append(HiddenCity(city: city, points: selectedPoints))
        }

        let filledGrid = grid.map { row in
            row.map { character in
                character ?? Self.alphabet.randomElement(using: &generator)!
            }
        }

        return PlacementResult(grid: filledGrid, hiddenCities: hiddenCities)
    }

    private func pointsForPlacement(
        letterCount: Int,
        start: GridPoint,
        direction: Direction,
        size: Int
    ) -> [GridPoint]? {
        let endRow = start.row + ((letterCount - 1) * direction.rowDelta)
        let endColumn = start.column + ((letterCount - 1) * direction.columnDelta)

        guard (0..<size).contains(endRow), (0..<size).contains(endColumn) else {
            return nil
        }

        return (0..<letterCount).map { index in
            GridPoint(
                row: start.row + (index * direction.rowDelta),
                column: start.column + (index * direction.columnDelta)
            )
        }
    }

    private func canPlace(
        letters: [Character],
        at points: [GridPoint],
        in grid: [[Character?]]
    ) -> Bool {
        for (index, point) in points.enumerated() {
            if let existing = grid[point.row][point.column], existing != letters[index] {
                return false
            }
        }

        return true
    }

    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

private struct PlacementResult {
    let grid: [[Character]]
    let hiddenCities: [HiddenCity]
}

private enum Direction: CaseIterable {
    case east
    case west
    case south
    case north
    case southEast
    case southWest
    case northEast
    case northWest

    var rowDelta: Int {
        switch self {
        case .east, .west:
            return 0
        case .south, .southEast, .southWest:
            return 1
        case .north, .northEast, .northWest:
            return -1
        }
    }

    var columnDelta: Int {
        switch self {
        case .north, .south:
            return 0
        case .east, .northEast, .southEast:
            return 1
        case .west, .northWest, .southWest:
            return -1
        }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var result = state
        result = (result ^ (result >> 30)) &* 0xBF58476D1CE4E5B9
        result = (result ^ (result >> 27)) &* 0x94D049BB133111EB
        return result ^ (result >> 31)
    }
}
