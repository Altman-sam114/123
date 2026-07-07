import SwiftUI

struct NewGameButton: View {
    let action: () -> Void
    let continueAction: (() -> Void)?
    let savedGameInfo: SavedGameInfo?

    init(
        action: @escaping () -> Void,
        continueAction: (() -> Void)? = nil,
        savedGameInfo: SavedGameInfo? = nil
    ) {
        self.action = action
        self.continueAction = continueAction
        self.savedGameInfo = savedGameInfo
    }

    var body: some View {
        Menu {
            Button(action: {
                if let continueAction {
                    continueAction()
                }
            }) {
                Label(continueTitle, systemImage: "clock.arrow.circlepath")
            }
            .disabled(continueAction == nil || savedGameInfo == nil)

            Button(role: .destructive, action: action) {
                Label("新开战局", systemImage: "arrow.counterclockwise")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: savedGameInfo == nil ? "scroll" : "clock.arrow.circlepath")
                    .foregroundStyle(statusTint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("战局")
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .padding(.horizontal, 2)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: MingDesignTokens.minimumTapSize)
        .accessibilityLabel(accessibilityText)
    }

    private var continueTitle: String {
        guard let savedGameInfo else {
            return "继续战局"
        }
        return "继续第 \(savedGameInfo.turn) 回合 · \(savedGameInfo.activeFaction.displayName)"
    }

    private var statusText: String {
        guard let savedGameInfo else {
            return "新开"
        }
        return "可续 \(savedGameInfo.activeFaction.displayName) 第 \(savedGameInfo.turn) 回合"
    }

    private var statusTint: Color {
        savedGameInfo == nil ? .secondary : MingDesignTokens.jade
    }

    private var accessibilityText: String {
        guard let savedGameInfo else {
            return "战局菜单，当前无可续读存档，可新开战局"
        }
        return "战局菜单，可续读第 \(savedGameInfo.turn) 回合，当前势力 \(savedGameInfo.activeFaction.displayName)"
    }
}
