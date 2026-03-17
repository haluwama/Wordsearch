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

                GeometryReader { proxy in
                    content(for: proxy.size.width)
                }
            }
            .navigationTitle("Atlas Search")
        }
    }

    @ViewBuilder
    private func content(for availableWidth: CGFloat) -> some View {
        if let error = viewModel.loadingError {
            errorState(message: error)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let puzzle = viewModel.puzzle {
            ScrollView {
                gameLayout(for: puzzle, availableWidth: availableWidth)
                .frame(maxWidth: availableWidth >= 1100 ? 1480 : 920)
                .padding(20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView("Building puzzle...")
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func gameLayout(for puzzle: GeographyPuzzle, availableWidth: CGFloat) -> some View {
        if availableWidth >= 1100 {
            HStack(alignment: .top, spacing: 20) {
                selectionSidebar(for: puzzle, isWideLayout: true)
                    .frame(width: 290)

                VStack(alignment: .leading, spacing: 20) {
                    boardSummaryCard(for: puzzle)

                    PuzzleGridView(
                        puzzle: puzzle,
                        foundCells: viewModel.foundCells,
                        selectionStart: viewModel.selectionStart,
                        onTap: viewModel.handleTap(on:)
                    )
                }
                .frame(maxWidth: 760)

                remainingWordsSidebar(for: puzzle)
                    .frame(width: 310)
            }
        } else {
            VStack(alignment: .leading, spacing: 20) {
                selectionSidebar(for: puzzle, isWideLayout: false)

                PuzzleGridView(
                    puzzle: puzzle,
                    foundCells: viewModel.foundCells,
                    selectionStart: viewModel.selectionStart,
                    onTap: viewModel.handleTap(on:)
                )

                remainingWordsSidebar(for: puzzle)
            }
        }
    }

    private func selectionSidebar(for puzzle: GeographyPuzzle, isWideLayout: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Region")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.31, blue: 0.17))

                Text(puzzle.region.challengeTitle)
                    .font(.system(size: isWideLayout ? 30 : 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.10, green: 0.17, blue: 0.21))

                Text("Only cross out \(puzzle.region.lowercasedName) cities. Use the grid to ignore decoys from other regions.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.26, blue: 0.33))
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: isWideLayout ? 1 : 2
                ),
                spacing: 10
            ) {
                ForEach(GeographyRegion.allCases) { region in
                    Button {
                        viewModel.changeRegion(to: region)
                    } label: {
                        HStack {
                            Text(region.rawValue)
                                .font(.system(size: 15, weight: .bold, design: .rounded))

                            Spacer(minLength: 8)

                            if viewModel.selectedRegion == region {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundStyle(viewModel.selectedRegion == region ? Color.white : Color(red: 0.12, green: 0.26, blue: 0.33))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    viewModel.selectedRegion == region
                                    ? Color(red: 0.16, green: 0.42, blue: 0.48)
                                    : Color.white.opacity(0.72)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("New Puzzle") {
                viewModel.generatePuzzle()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.78, green: 0.36, blue: 0.20))

            VStack(alignment: .leading, spacing: 10) {
                Text("Progress")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.31, blue: 0.17))

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

    private func boardSummaryCard(for puzzle: GeographyPuzzle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Challenge")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.55))

            Text(distractorLine(for: puzzle))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 0.14, green: 0.25, blue: 0.31).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
    }

    private func remainingWordsSidebar(for puzzle: GeographyPuzzle) -> some View {
        let remainingCities = remainingTargetCities(for: puzzle)
        let foundCities = foundTargetCities(for: puzzle)

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Remaining Words")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.10, green: 0.17, blue: 0.21))

                Text("\(remainingCities.count) target cities still need to be crossed out.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.26, blue: 0.33))
            }

            VStack(alignment: .leading, spacing: 10) {
                if remainingCities.isEmpty {
                    Text("All target cities found.")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.22, green: 0.48, blue: 0.18))
                } else {
                    ForEach(remainingCities) { city in
                        WordStatusRow(city: city, isFound: false)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Crossed Out")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.31, blue: 0.17))

                if foundCities.isEmpty {
                    Text("Nothing crossed out yet.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.39, green: 0.44, blue: 0.47))
                } else {
                    ForEach(foundCities) { city in
                        WordStatusRow(city: city, isFound: true)
                    }
                }
            }

            Text("Decoy cities from \(puzzle.distractorRegions.map(\.rawValue).formatted(.list(type: .and))) are hidden in the grid too.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.63, green: 0.32, blue: 0.08))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.99, green: 0.91, blue: 0.80))
                )
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

    private func remainingTargetCities(for puzzle: GeographyPuzzle) -> [CityEntry] {
        puzzle.targetCities
            .filter { !viewModel.isFoundTarget($0) }
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    private func foundTargetCities(for puzzle: GeographyPuzzle) -> [CityEntry] {
        puzzle.targetCities
            .filter { viewModel.isFoundTarget($0) }
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
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

private struct WordStatusRow: View {
    let city: CityEntry
    let isFound: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isFound ? Color(red: 0.57, green: 0.78, blue: 0.47) : Color(red: 0.16, green: 0.42, blue: 0.48))
                .frame(width: 10, height: 10)

            Text(city.displayName)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .strikethrough(isFound)
                .foregroundStyle(foreground)

            Spacer(minLength: 8)

            Text(isFound ? "Found" : "To Find")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(isFound ? Color(red: 0.22, green: 0.48, blue: 0.18) : Color(red: 0.16, green: 0.42, blue: 0.48))
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
        if isFound {
            return Color(red: 0.86, green: 0.95, blue: 0.84)
        }

        return Color.white.opacity(0.80)
    }

    private var foreground: Color {
        if isFound {
            return Color(red: 0.22, green: 0.48, blue: 0.18)
        }

        return Color(red: 0.10, green: 0.17, blue: 0.21)
    }

    private var borderColor: Color {
        if isFound {
            return Color(red: 0.57, green: 0.78, blue: 0.47)
        }

        return Color.white.opacity(0.30)
    }
}

#Preview {
    ContentView()
}
