//
//  GeographyGameViewModel.swift
//  Wordsearch
//
//  Created by Codex on 17/03/2026.
//

import Foundation
import Combine

@MainActor
final class GeographyGameViewModel: ObservableObject {
    @Published private(set) var selectedRegion: GeographyRegion = .europe
    @Published private(set) var puzzle: GeographyPuzzle?
    @Published private(set) var foundTargetIDs: Set<String> = []
    @Published private(set) var revealedDistractorIDs: Set<String> = []
    @Published private(set) var selectionStart: GridPoint?
    @Published var feedback = "Loading geography puzzle..."
    @Published var loadingError: String?

    private let factory: GeographyPuzzleFactory?

    init(catalog: GeographyCityCatalog? = nil) {
        do {
            let resolvedCatalog: GeographyCityCatalog

            if let catalog {
                resolvedCatalog = catalog
            } else {
                resolvedCatalog = try GeographyCityCatalog.load()
            }

            self.factory = GeographyPuzzleFactory(catalog: resolvedCatalog)
            generatePuzzle()
        } catch {
            self.factory = nil
            self.loadingError = error.localizedDescription
            self.feedback = "The game data could not be loaded."
        }
    }

    var targetCount: Int {
        puzzle?.targetCityIDs.count ?? 0
    }

    var foundCount: Int {
        foundTargetIDs.count
    }

    var remainingCount: Int {
        max(targetCount - foundCount, 0)
    }

    var foundCells: Set<GridPoint> {
        guard let puzzle else {
            return []
        }

        return Set(
            puzzle.hiddenCities
                .filter { foundTargetIDs.contains($0.city.id) }
                .flatMap(\.points)
        )
    }

    func changeRegion(to region: GeographyRegion) {
        guard selectedRegion != region else {
            return
        }

        selectedRegion = region
        generatePuzzle()
    }

    func generatePuzzle() {
        guard let factory else {
            return
        }

        do {
            puzzle = try factory.makePuzzle(for: selectedRegion)
            foundTargetIDs = []
            revealedDistractorIDs = []
            selectionStart = nil
            loadingError = nil
            feedback = "Find every \(selectedRegion.lowercasedName) city. The other continents are decoys."
        } catch {
            loadingError = error.localizedDescription
        }
    }

    func handleTap(on point: GridPoint) {
        guard puzzle != nil else {
            return
        }

        if let selectionStart {
            if selectionStart == point {
                self.selectionStart = nil
                feedback = "Selection cleared."
                return
            }

            guard let selection = puzzle?.line(from: selectionStart, to: point) else {
                self.selectionStart = point
                feedback = "Pick a straight line: horizontal, vertical, or diagonal."
                return
            }

            submit(selection: selection)
            self.selectionStart = nil
        } else {
            selectionStart = point
            feedback = "Start selected. Tap the last letter of the city."
        }
    }

    func isFoundTarget(_ city: CityEntry) -> Bool {
        foundTargetIDs.contains(city.id)
    }

    func isRevealedDistractor(_ city: CityEntry) -> Bool {
        revealedDistractorIDs.contains(city.id)
    }

    private func submit(selection: [GridPoint]) {
        guard let puzzle else {
            return
        }

        guard let hiddenCity = puzzle.city(on: selection) else {
            feedback = "That line does not match one of the hidden cities."
            return
        }

        if puzzle.targetCityIDs.contains(hiddenCity.city.id) {
            let insertion = foundTargetIDs.insert(hiddenCity.city.id)

            if insertion.inserted {
                if remainingCount == 0 {
                    feedback = "Puzzle solved. Every \(selectedRegion.lowercasedName) city has been crossed out."
                } else {
                    feedback = "\(hiddenCity.city.displayName) is correct. \(remainingCount) target cities left."
                }
            } else {
                feedback = "\(hiddenCity.city.displayName) is already crossed out."
            }
        } else {
            revealedDistractorIDs.insert(hiddenCity.city.id)
            feedback = "\(hiddenCity.city.displayName) belongs to \(hiddenCity.city.region.rawValue), so leave it uncrossed."
        }
    }
}
