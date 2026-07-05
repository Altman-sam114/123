import Foundation

enum CourtProjectDomain: String, Codable, Equatable, CaseIterable, Identifiable {
    case policy
    case economy
    case technology
    case military

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .policy:
            return "政策"
        case .economy:
            return "经济"
        case .technology:
            return "科技"
        case .military:
            return "军事"
        }
    }

    var agendaDetail: String {
        switch self {
        case .policy:
            return "民变、行政、招抚"
        case .economy:
            return "银两、民力、粮草"
        case .technology:
            return "火器、炮队、驿道"
        case .military:
            return "城防、团练、粮道"
        }
    }

    var systemImageName: String {
        switch self {
        case .policy:
            return "scroll"
        case .economy:
            return "banknote"
        case .technology:
            return "scope"
        case .military:
            return "shield"
        }
    }
}

enum CourtProjectKind: String, Codable, Equatable, CaseIterable, Identifiable {
    case raiseTax
    case relief
    case appeaseGentry
    case agrarianReform
    case fortify
    case trainMilitia
    case firearmReform
    case redCannonMaintenance
    case grainTransport

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .raiseTax:
            return "征饷"
        case .relief:
            return "赈济安民"
        case .appeaseGentry:
            return "招抚乡绅"
        case .agrarianReform:
            return "农政屯田"
        case .fortify:
            return "修城固守"
        case .trainMilitia:
            return "整训团练"
        case .firearmReform:
            return "火器整备"
        case .redCannonMaintenance:
            return "红衣炮维护"
        case .grainTransport:
            return "粮台驿道"
        }
    }

    var domainDisplayName: String {
        domains.map(\.displayName).joined(separator: "/")
    }

    var primaryDomain: CourtProjectDomain {
        domains.first ?? .policy
    }

    var domains: [CourtProjectDomain] {
        switch self {
        case .raiseTax:
            return [.economy]
        case .relief:
            return [.policy]
        case .appeaseGentry:
            return [.policy]
        case .agrarianReform:
            return [.economy, .technology]
        case .fortify,
             .trainMilitia:
            return [.military]
        case .firearmReform:
            return [.technology]
        case .redCannonMaintenance:
            return [.technology, .military]
        case .grainTransport:
            return [.economy, .technology, .military]
        }
    }

    var benefitSummary: String {
        switch self {
        case .raiseTax:
            return "补充银两，承担民变和行政代价。"
        case .relief:
            return "压低民变，恢复地方行政。"
        case .appeaseGentry:
            return "安抚地方中立和乡绅团练，恢复行政掌控。"
        case .agrarianReform:
            return "整饬屯田水利，提升州府粮草和基础设施。"
        case .fortify:
            return "加固重点州府，提升后续补给和防务。"
        case .trainMilitia:
            return "把地方守备排入募兵队列。"
        case .firearmReform:
            return "优先修整火器、炮队和攻城器械。"
        case .redCannonMaintenance:
            return "校修红衣炮与攻城炮队，恢复守城和攻城火力。"
        case .grainTransport:
            return "转运粮草并整修驿道，优先缓解缺粮部队。"
        }
    }

    var riskSummary: String {
        switch self {
        case .raiseTax:
            return "民变上升，行政掌控下降。"
        case .relief:
            return "消耗银两与粮草。"
        case .appeaseGentry:
            return "消耗银两粮草，见效限于己控地方。"
        case .agrarianReform:
            return "短期不补现粮，见效依赖己控州府。"
        case .fortify:
            return "消耗民力、银两与粮草。"
        case .trainMilitia:
            return "成军较慢，野战上限有限。"
        case .firearmReform:
            return "军械维护挤占银两。"
        case .redCannonMaintenance:
            return "耗银耗粮，见效依赖现有炮队或军械工坊。"
        case .grainTransport:
            return "银两转为粮草与役力，其他项目延后。"
        }
    }

    var systemImageName: String {
        switch self {
        case .raiseTax:
            return "banknote"
        case .relief:
            return "leaf"
        case .appeaseGentry:
            return "person.crop.circle.badge.checkmark"
        case .agrarianReform:
            return "sprout"
        case .fortify:
            return "shield"
        case .trainMilitia:
            return "person.3"
        case .firearmReform:
            return "scope"
        case .redCannonMaintenance:
            return "wrench.and.screwdriver"
        case .grainTransport:
            return "shippingbox"
        }
    }

    var cost: EconomyResources {
        switch self {
        case .raiseTax:
            return EconomyResources(manpower: 8, industry: 0, supplies: 8)
        case .relief:
            return EconomyResources(manpower: 0, industry: 45, supplies: 35)
        case .appeaseGentry:
            return EconomyResources(manpower: 10, industry: 30, supplies: 20)
        case .agrarianReform:
            return EconomyResources(manpower: 25, industry: 35, supplies: 10)
        case .fortify:
            return EconomyResources(manpower: 30, industry: 45, supplies: 15)
        case .trainMilitia:
            return EconomyResources(manpower: 45, industry: 25, supplies: 12)
        case .firearmReform:
            return EconomyResources(manpower: 25, industry: 60, supplies: 18)
        case .redCannonMaintenance:
            return EconomyResources(manpower: 12, industry: 55, supplies: 24)
        case .grainTransport:
            return EconomyResources(manpower: 0, industry: 35, supplies: 0)
        }
    }

    var resourceGain: EconomyResources {
        switch self {
        case .raiseTax:
            return EconomyResources(industry: 80)
        case .grainTransport:
            return EconomyResources(supplies: 90)
        case .relief,
             .appeaseGentry,
             .agrarianReform,
             .fortify,
             .trainMilitia,
             .firearmReform:
            return .zero
        case .redCannonMaintenance:
            return .zero
        }
    }
}
