import SpriteKit

final class UnitNode: SKNode {
    let divisionId: String

    init(
        division: Division,
        layout: HexLayout,
        placement: UnitDisplayPlacement,
        isSelected: Bool,
        isPlayerManaged: Bool = false,
        fillColorOverride: SKColor? = nil
    ) {
        self.divisionId = division.id
        super.init()

        let anchor = layout.hexToPixel(placement.hex)
        position = CGPoint(x: anchor.x + placement.offset.x, y: anchor.y + placement.offset.y)
        zPosition = 40
        alpha = division.hasActed ? 0.58 : 1

        let width = layout.hexSize * 1.08
        let height = layout.hexSize * 0.72

        if isPlayerManaged {
            let halo = SKShapeNode(rectOf: CGSize(width: width + 8, height: height + 8), cornerRadius: min(7, layout.hexSize * 0.14))
            halo.fillColor = SKColor(red: 0.95, green: 0.72, blue: 0.22, alpha: 0.22)
            halo.strokeColor = SKColor(red: 1.00, green: 0.78, blue: 0.24, alpha: 0.95)
            halo.lineWidth = max(2, layout.hexSize * 0.06)
            halo.zPosition = -1
            addChild(halo)
        }

        let body = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: min(5, layout.hexSize * 0.10))
        body.fillColor = fillColorOverride ?? TerrainStyle.unitFillColor(for: division.faction)
        body.strokeColor = isSelected ? TerrainStyle.selectedStroke : TerrainStyle.unitStrokeColor(for: division.faction)
        body.lineWidth = isSelected ? max(3, layout.hexSize * 0.08) : 1.5
        body.zPosition = 0
        addChild(body)

        addFactionSideStrip(for: division, width: width, height: height)
        addMingUnitEmblem(for: division, width: width, height: height)
        if isPlayerManaged {
            addManagedOrderSeal(layout: layout, bodyWidth: width, bodyHeight: height)
        }
        addReadinessPill(for: division, layout: layout, bodyWidth: width, bodyHeight: height)
        addBattleStatusTag(for: division, layout: layout, bodyWidth: width, bodyHeight: height)

        addSupplyMarker(for: division, layout: layout, bodyWidth: width, bodyHeight: height)
        addStackMarker(placement: placement, layout: layout, bodyWidth: width, bodyHeight: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addFactionSideStrip(for division: Division, width: CGFloat, height: CGFloat) {
        let stripWidth = max(4, width * 0.09)
        let strip = SKShapeNode(
            rectOf: CGSize(width: stripWidth, height: height * 0.76),
            cornerRadius: min(3, stripWidth / 2)
        )
        strip.fillColor = TerrainStyle.unitStrokeColor(for: division.faction).withAlphaComponent(0.92)
        strip.strokeColor = SKColor(white: 1, alpha: 0.20)
        strip.lineWidth = 0.8
        strip.position = CGPoint(x: -width / 2 + stripWidth * 0.78, y: 0)
        strip.zPosition = 1
        addChild(strip)
    }

    private func addMingUnitEmblem(for division: Division, width: CGFloat, height: CGFloat) {
        let bandHeight = max(3, height * 0.12)
        let topBand = SKShapeNode(rectOf: CGSize(width: width * 0.88, height: bandHeight), cornerRadius: min(2, bandHeight / 2))
        topBand.fillColor = SKColor(red: 0.96, green: 0.76, blue: 0.28, alpha: 0.72)
        topBand.strokeColor = .clear
        topBand.position = CGPoint(x: 0, y: height * 0.27)
        topBand.zPosition = 1
        addChild(topBand)

        addLabel(
            text: division.faction.bannerGlyph,
            y: height * 0.27,
            fontSize: max(7, height * 0.18),
            weight: "PingFangSC-Semibold",
            color: SKColor(red: 0.20, green: 0.10, blue: 0.05, alpha: 0.96)
        )

        let medallion = SKShapeNode(ellipseOf: CGSize(width: width * 0.46, height: height * 0.38))
        medallion.fillColor = SKColor(white: 0.04, alpha: 0.20)
        medallion.strokeColor = SKColor(white: 1, alpha: 0.20)
        medallion.lineWidth = 0.8
        medallion.position = CGPoint(x: 0, y: height * 0.02)
        medallion.zPosition = 1
        addChild(medallion)

        addLabel(
            text: division.markerEmblemText,
            y: height * 0.02,
            fontSize: max(12, height * 0.38),
            weight: "PingFangSC-Semibold",
            color: SKColor(white: 0.97, alpha: 1)
        )
    }

    private func addManagedOrderSeal(layout: HexLayout, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        let sealSize = CGSize(width: max(12, layout.hexSize * 0.34), height: max(10, layout.hexSize * 0.26))
        let seal = SKShapeNode(rectOf: sealSize, cornerRadius: min(4, sealSize.height / 2))
        seal.fillColor = SKColor(red: 0.70, green: 0.10, blue: 0.08, alpha: 0.96)
        seal.strokeColor = SKColor(red: 1.00, green: 0.82, blue: 0.36, alpha: 0.95)
        seal.lineWidth = 0.9
        seal.position = CGPoint(x: 0, y: bodyHeight * 0.47)
        seal.zPosition = 6
        addChild(seal)

        addLabel(
            text: "令",
            y: seal.position.y,
            fontSize: max(7, layout.hexSize * 0.15),
            weight: "PingFangSC-Semibold",
            color: SKColor(white: 0.98, alpha: 1),
            zPosition: 7
        )
    }

    private func addReadinessPill(for division: Division, layout: HexLayout, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        let pillHeight = max(10, bodyHeight * 0.21)
        let pill = SKShapeNode(
            rectOf: CGSize(width: bodyWidth * 0.66, height: pillHeight),
            cornerRadius: min(4, pillHeight / 2)
        )
        pill.fillColor = SKColor(white: 0.02, alpha: 0.26)
        pill.strokeColor = SKColor(white: 1, alpha: 0.18)
        pill.lineWidth = 0.7
        pill.position = CGPoint(x: 0, y: -bodyHeight * 0.28)
        pill.zPosition = 1
        addChild(pill)

        addLabel(
            text: division.markerReadinessText,
            y: -bodyHeight * 0.28,
            fontSize: max(7, layout.hexSize * 0.16),
            weight: "AvenirNext-Regular",
            color: SKColor(white: 0.97, alpha: 1)
        )
    }

    private func addBattleStatusTag(for division: Division, layout: HexLayout, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        guard let status = division.markerBattleStatus else {
            return
        }

        let tagHeight = max(9, bodyHeight * 0.18)
        let tagWidth = max(layout.hexSize * 0.42, CGFloat(status.text.count) * layout.hexSize * 0.17 + 10)
        let x = bodyWidth * 0.32
        let y = -bodyHeight * 0.48
        let tag = SKShapeNode(
            rectOf: CGSize(width: tagWidth, height: tagHeight),
            cornerRadius: min(4, tagHeight / 2)
        )
        tag.fillColor = status.fillColor
        tag.strokeColor = status.strokeColor
        tag.lineWidth = 0.9
        tag.position = CGPoint(x: x, y: y)
        tag.zPosition = 4
        addChild(tag)

        addLabel(
            text: status.text,
            x: x,
            y: y,
            fontSize: max(7, layout.hexSize * 0.15),
            weight: "PingFangSC-Semibold",
            color: SKColor(white: 0.98, alpha: 1),
            zPosition: 5
        )
    }

    private func addLabel(
        text: String,
        x: CGFloat = 0,
        y: CGFloat,
        fontSize: CGFloat,
        weight: String,
        color: SKColor,
        zPosition: CGFloat = 2
    ) {
        let label = SKLabelNode(text: text)
        label.fontName = weight
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: x, y: y)
        label.zPosition = zPosition
        addChild(label)
    }

    private func addSupplyMarker(for division: Division, layout: HexLayout, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        let radius = max(3, layout.hexSize * 0.10)
        let marker = SKShapeNode(circleOfRadius: radius)
        marker.fillColor = TerrainStyle.supplyColor(for: division.supplyState)
        marker.strokeColor = SKColor(white: 1, alpha: 0.85)
        marker.lineWidth = 1
        marker.position = CGPoint(x: bodyWidth / 2 - radius * 0.8, y: bodyHeight / 2 - radius * 0.8)
        marker.zPosition = 3
        addChild(marker)

        guard division.supplyState != .supplied else {
            return
        }

        let alert = SKLabelNode(text: "!")
        alert.fontName = "AvenirNext-Bold"
        alert.fontSize = max(7, layout.hexSize * 0.16)
        alert.fontColor = SKColor(white: 1, alpha: 1)
        alert.horizontalAlignmentMode = .center
        alert.verticalAlignmentMode = .center
        alert.position = marker.position
        alert.zPosition = 4
        addChild(alert)
    }

    private func addStackMarker(placement: UnitDisplayPlacement, layout: HexLayout, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        guard placement.stackCount > 1 else {
            return
        }

        let marker = SKShapeNode(circleOfRadius: max(4, layout.hexSize * 0.12))
        marker.fillColor = SKColor(white: 0.05, alpha: 0.94)
        marker.strokeColor = SKColor(white: 1, alpha: 0.75)
        marker.lineWidth = 1
        marker.position = CGPoint(x: -bodyWidth / 2 + layout.hexSize * 0.13, y: bodyHeight / 2 - layout.hexSize * 0.13)
        marker.zPosition = 4
        addChild(marker)

        let count = SKLabelNode(text: "\(placement.stackCount)")
        count.fontName = "AvenirNext-DemiBold"
        count.fontSize = max(7, layout.hexSize * 0.17)
        count.fontColor = SKColor(white: 1, alpha: 1)
        count.horizontalAlignmentMode = .center
        count.verticalAlignmentMode = .center
        count.position = marker.position
        count.zPosition = 5
        addChild(count)
    }
}

private struct UnitMarkerStatus {
    let text: String
    let fillColor: SKColor
    let strokeColor: SKColor
}

private extension Division {
    var markerEmblemText: String {
        if isSiegeCapable {
            return "城"
        }
        if isArmor {
            return "旗"
        }
        if hasFireSupport {
            return "火"
        }
        if isMobileUnit {
            return "骑"
        }
        return "步"
    }

    var markerReadinessText: String {
        "\(strength)/\(maxStrength) \(retreatMode.markerCode)"
    }

    var markerBattleStatus: UnitMarkerStatus? {
        if isDestroyed {
            return UnitMarkerStatus(
                text: "溃散",
                fillColor: SKColor(red: 0.50, green: 0.06, blue: 0.05, alpha: 0.94),
                strokeColor: SKColor(red: 1.00, green: 0.60, blue: 0.50, alpha: 0.95)
            )
        }
        if isRetreating {
            return UnitMarkerStatus(
                text: "退中",
                fillColor: SKColor(red: 0.46, green: 0.25, blue: 0.09, alpha: 0.94),
                strokeColor: SKColor(red: 1.00, green: 0.74, blue: 0.34, alpha: 0.95)
            )
        }
        switch supplyState {
        case .encircled:
            return UnitMarkerStatus(
                text: "被围",
                fillColor: SKColor(red: 0.66, green: 0.10, blue: 0.08, alpha: 0.94),
                strokeColor: SKColor(red: 1.00, green: 0.68, blue: 0.58, alpha: 0.95)
            )
        case .lowSupply:
            return UnitMarkerStatus(
                text: "缺粮",
                fillColor: SKColor(red: 0.63, green: 0.37, blue: 0.08, alpha: 0.94),
                strokeColor: SKColor(red: 1.00, green: 0.76, blue: 0.36, alpha: 0.95)
            )
        case .supplied:
            break
        }
        if hasActed {
            return UnitMarkerStatus(
                text: "已行",
                fillColor: SKColor(white: 0.12, alpha: 0.88),
                strokeColor: SKColor(white: 1.00, alpha: 0.46)
            )
        }
        return nil
    }
}

private extension RetreatMode {
    var markerCode: String {
        switch self {
        case .retreatable:
            return "退"
        case .hold:
            return "守"
        }
    }
}
