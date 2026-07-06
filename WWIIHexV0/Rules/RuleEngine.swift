import Foundation

struct RuleEngine {
    private let validator = CommandValidator()
    private let executor = CommandExecutor()

    func execute(_ command: Command, in state: GameState) -> CommandResult {
        let preparedState = EconomyRules().bootstrapIfNeeded(state)
        let validation = validator.validate(command, in: preparedState)
        guard validation.isValid else {
            let errorMessage = validation.errors.map(\.rawValue).joined(separator: ", ")
            return CommandResult(
                command: command,
                validation: validation,
                state: preparedState,
                message: "军令驳回：\(errorMessage)。"
            )
        }

        let nextState = executor.execute(command, in: preparedState)
        return CommandResult(
            command: command,
            validation: validation,
            state: nextState,
            message: "军令执行：\(command.ruleReportDisplayName)。"
        )
    }

    func apply(_ command: Command, to state: GameState) -> GameState {
        execute(command, in: state).state
    }
}

private extension Command {
    var ruleReportDisplayName: String {
        switch self {
        case .move(let divisionId, let destination):
            return "调动\(divisionId)至舆图格 \(destination.q),\(destination.r)"
        case .attack(let attackerId, let targetId):
            return "\(attackerId)攻打\(targetId)"
        case .hold(let divisionId):
            return "\(divisionId)固守"
        case .allowRetreat(let divisionId):
            return "\(divisionId)准许退守"
        case .resupply(let divisionId):
            return "\(divisionId)补给整备"
        case .queueProduction(let kind):
            return "营造筹备\(kind.displayName)"
        case .enactCourtProject(let kind):
            return "朝廷项目\(kind.displayName)"
        case .endTurn:
            return "结束本阶段"
        }
    }
}
