//
//  ContentView.swift
//  Wordsearch
//
//  Created by Codex on 17/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GeographyGameViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.89, blue: 0.78),
                        Color(red: 0.77, green: 0.86, blue: 0.86),
                        Color(red: 0.12, green: 0.26, blue: 0.33)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                content
            }
            .navigationTitle("Atlas Search")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.loadingError {
            errorState(message: error)
        } else if let puzzle = viewModel.puzzle {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard(for: puzzle)

                    PuzzleGridView(
                        puzzle: puzzle,
                        foundCells: viewModel.foundCells,
                        selectionStart: viewModel.selectionStart,
                        onTap: viewModel.handleTap(on:)
                    )

                    wordBankCard(for: puzzle)
                }
                .frame(maxWidth: 920)
                .padding(20)
                .padding(.bottom, 24)
            }
        } else {
            ProgressView("Building puzzle...")
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func headerCard(for puzzle: GeographyPuzzle) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(puzzle.region.challengeTitle)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.10, green: 0.17, blue: 0.21))

                Text("Only cross out \(puzzle.region.lowercasedName) cities. \(distractorLine(for: puzzle))")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.26, blue: 0.33))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Picker(
                    "Target Region",
                    selection: Binding(
                        get: { viewModel.selectedRegion },
                        set: { viewModel.changeRegion(to: $0) }
                    )
                ) {
                    ForEach(GeographyRegion.allCases) { region in
                        Text(region.rawValue).tag(region)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.78), in: Capsule())

                Button("New Puzzle") {
                    viewModel.generatePuzzle()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.78, green: 0.36, blue: 0.20))
            }

            HStack(spacing: 12) {
                StatPill(
                    label: "Correct",
                    value: "\(viewModel.foundCount)/\(viewModel.targetCount)"
                )

                StatPill(
                    label: "Remaining",
                    value: "\(viewModel.remainingCount)"
                )
            }

            Text(viewModel.feedback)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.23, green: 0.14, blue: 0.08))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.60))
                )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.96, green: 0.91, blue: 0.83).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private func wordBankCard(for puzzle: GeographyPuzzle) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Mixed City Bank")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.10, green: 0.17, blue: 0.21))

            Text("Every city below is hidden in the grid. Cross out only the ones that belong to \(puzzle.region.rawValue).")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.26, blue: 0.33))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 12)], spacing: 12) {
                ForEach(puzzle.wordBank) { city in
                    CityChip(
                        city: city,
                        isFoundTarget: viewModel.isFoundTarget(city),
                        isRevealedDistractor: viewModel.isRevealedDistractor(city)
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.95, green: 0.98, blue: 0.98).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Game Data Error")
                .font(.system(size: 28, weight: .bold, design: .serif))

            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))

            Button("Retry") {
                viewModel.generatePuzzle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(20)
    }

    private func distractorLine(for puzzle: GeographyPuzzle) -> String {
        let regions = puzzle.distractorRegions.map(\.rawValue)

        guard !regions.isEmpty else {
            return "No distractor regions were added."
        }

        return "Distractors from \(regions.formatted(.list(type: .and))) are mixed in to slow the player down."
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.33, green: 0.28, blue: 0.18))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.10, green: 0.17, blue: 0.21))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PuzzleGridView: View {
    let puzzle: GeographyPuzzle
    let foundCells: Set<GridPoint>
    let selectionStart: GridPoint?
    let onTap: (GridPoint) -> Void

    private let columns: [GridItem]

    init(
        puzzle: GeographyPuzzle,
        foundCells: Set<GridPoint>,
        selectionStart: GridPoint?,
        onTap: @escaping (GridPoint) -> Void
    ) {
        self.puzzle = puzzle
        self.foundCells = foundCells
        self.selectionStart = selectionStart
        self.onTap = onTap
        self.columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: puzzle.size)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Letter Grid")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.83))

            Text("Tap one letter to start, then tap the final letter of a straight-line city.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.84))

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<(puzzle.size * puzzle.size), id: \.self) { index in
                    let row = index / puzzle.size
                    let column = index % puzzle.size
                    let point = GridPoint(row: row, column: column)

                    Button {
                        onTap(point)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(cellBackground(for: point))

                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(cellBorder(for: point), lineWidth: selectionStart == point ? 2.5 : 0)

                            Text(String(puzzle.grid[row][column]))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundStyle(foregroundColor(for: point))
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.11, green: 0.22, blue: 0.29).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 10)
    }

    private func cellBackground(for point: GridPoint) -> some ShapeStyle {
        if foundCells.contains(point) {
            return Color(red: 0.62, green: 0.80, blue: 0.46)
        }

        if selectionStart == point {
            return Color(red: 0.94, green: 0.74, blue: 0.32)
        }

        return Color.white.opacity(0.92)
    }

    private func cellBorder(for point: GridPoint) -> Color {
        selectionStart == point ? Color(red: 0.51, green: 0.24, blue: 0.07) : .clear
    }

    private func foregroundColor(for point: GridPoint) -> Color {
        foundCells.contains(point) ? Color(red: 0.12, green: 0.24, blue: 0.11) : Color(red: 0.07, green: 0.12, blue: 0.16)
    }
}

private struct CityChip: View {
    let city: CityEntry
    let isFoundTarget: Bool
    let isRevealedDistractor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(city.displayName)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .strikethrough(isFoundTarget)
                .foregroundStyle(foreground)

            if isRevealedDistractor {
                Text(city.region.rawValue)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.73, green: 0.39, blue: 0.09))
            } else if isFoundTarget {
                Text("Correct")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.22, green: 0.48, blue: 0.18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var background: some ShapeStyle {
        if isFoundTarget {
            return Color(red: 0.86, green: 0.95, blue: 0.84)
        }

        if isRevealedDistractor {
            return Color(red: 0.99, green: 0.91, blue: 0.80)
        }

        return Color.white.opacity(0.80)
    }

    private var foreground: Color {
        if isFoundTarget {
            return Color(red: 0.22, green: 0.48, blue: 0.18)
        }

        if isRevealedDistractor {
            return Color(red: 0.63, green: 0.32, blue: 0.08)
        }

        return Color(red: 0.10, green: 0.17, blue: 0.21)
    }

    private var borderColor: Color {
        if isFoundTarget {
            return Color(red: 0.57, green: 0.78, blue: 0.47)
        }

        if isRevealedDistractor {
            return Color(red: 0.89, green: 0.67, blue: 0.39)
        }

        return Color.white.opacity(0.30)
    }
}

#Preview {
    ContentView()
}
