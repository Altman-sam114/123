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
            Label("战局", systemImage: "scroll")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: MingDesignTokens.minimumTapSize)
    }

    private var continueTitle: String {
        guard let savedGameInfo else {
            return "继续战局"
        }
        return "继续第 \(savedGameInfo.turn) 回合 · \(savedGameInfo.activeFaction.displayName)"
    }
}
