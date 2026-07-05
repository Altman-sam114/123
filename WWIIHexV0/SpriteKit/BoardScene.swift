import SpriteKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

final class BoardScene: SKScene {
    private var renderState: BoardRenderState?
    private var layout: HexLayout?
    private var onHexTapped: ((HexCoord) -> Void)?
    // v0.21: camera 平移
    private var boardCamera: SKCameraNode?
    private var lastDragViewPosition: CGPoint?
    private var lastDragScenePosition: CGPoint?
    private var totalDragDistance: CGFloat = 0
    private let tapThreshold: CGFloat = 8

    override init(size: CGSize) {
        super.init(size: size)
        // v0.21: resizeFill 让 scene 跟 SKView 同尺寸；hex 大小由 HexLayout.fixed 决定（不塞满），
        // 超出 view 的 hex 画在 scene 外，由平移（任务 0.2）暴露。
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.16, green: 0.20, blue: 0.18, alpha: 1.0)
        setupCamera()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.16, green: 0.20, blue: 0.18, alpha: 1.0)
        setupCamera()
    }

    private func setupCamera() {
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
        self.boardCamera = camera
    }

    func configure(with renderState: BoardRenderState, onHexTapped: @escaping (HexCoord) -> Void) {
        self.renderState = renderState
        self.onHexTapped = onHexTapped
        redraw()
    }

    override func didMove(to view: SKView) {
        redraw()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        redraw()
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view else { return }
        lastDragViewPosition = touch.location(in: view)
        totalDragDistance = 0
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let view,
              let prev = lastDragViewPosition,
              let camera = boardCamera else {
            return
        }
        let current = touch.location(in: view)
        let delta = CGPoint(x: current.x - prev.x, y: current.y - prev.y)
        totalDragDistance += hypot(delta.x, delta.y)
        // 拖动方向反转（手指右移 → 内容右移 → camera 左移）
        camera.position.x -= delta.x
        camera.position.y += delta.y
        clampCamera()
        lastDragViewPosition = current
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            lastDragViewPosition = nil
        }
        // 累计拖动超阈值视为平移，不当 tap
        guard totalDragDistance < tapThreshold,
              let touch = touches.first,
              let layout,
              let state = renderState?.gameState else {
            return
        }

        let point = touch.location(in: self)
        let coord = layout.pixelToHex(point)
        guard state.map.contains(coord) else {
            return
        }

        onHexTapped?(coord)
    }
    #endif

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        lastDragScenePosition = event.location(in: self)
        totalDragDistance = 0
    }

    override func mouseDragged(with event: NSEvent) {
        guard let prev = lastDragScenePosition,
              let camera = boardCamera else {
            return
        }
        let current = event.location(in: self)
        let delta = CGPoint(x: current.x - prev.x, y: current.y - prev.y)
        totalDragDistance += hypot(delta.x, delta.y)
        camera.position.x -= delta.x
        camera.position.y -= delta.y
        clampCamera()
        lastDragScenePosition = current
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            lastDragScenePosition = nil
        }
        guard totalDragDistance < tapThreshold,
              let layout,
              let state = renderState?.gameState else {
            return
        }

        let point = event.location(in: self)
        let coord = layout.pixelToHex(point)
        guard state.map.contains(coord) else {
            return
        }

        onHexTapped?(coord)
    }

    func handleScrollWheel(_ event: NSEvent, anchor: CGPoint) {
        guard let camera = boardCamera else { return }

        if event.modifierFlags.contains(.shift) || abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
            camera.position.x += event.scrollingDeltaX * camera.xScale
            camera.position.y -= event.scrollingDeltaY * camera.yScale
            clampCamera()
            return
        }

        let multiplier: CGFloat = event.scrollingDeltaY > 0 ? 0.92 : 1.08
        zoomCamera(multiplier: multiplier, anchor: anchor)
    }

    func handleMagnify(_ event: NSEvent, anchor: CGPoint) {
        let multiplier = max(0.5, min(1.5, 1 - event.magnification))
        zoomCamera(multiplier: multiplier, anchor: anchor)
    }
    #endif

    /// 限制 camera 在地图边界内，避免拖空。
    private func clampCamera() {
        guard let layout, let state = renderState?.gameState else { return }
        let mapWidth = state.map.width
        let mapHeight = state.map.height
        // 地图四角像素（fixed layout 下）
        let corners: [CGPoint] = [
            layout.hexToPixel(HexCoord(q: 0, r: 0)),
            layout.hexToPixel(HexCoord(q: mapWidth - 1, r: 0)),
            layout.hexToPixel(HexCoord(q: 0, r: mapHeight - 1)),
            layout.hexToPixel(HexCoord(q: mapWidth - 1, r: mapHeight - 1))
        ]
        let minX = corners.map(\.x).min() ?? 0
        let maxX = corners.map(\.x).max() ?? 0
        let minY = corners.map(\.y).min() ?? 0
        let maxY = corners.map(\.y).max() ?? 0
        let margin = layout.hexSize
        if let camera = boardCamera {
            camera.position.x = min(max(camera.position.x, minX - margin), maxX + margin)
            camera.position.y = min(max(camera.position.y, minY - margin), maxY + margin)
        }
    }

    private func zoomCamera(multiplier: CGFloat, anchor: CGPoint) {
        guard let camera = boardCamera else { return }
        let oldScale = camera.xScale
        let nextScale = max(0.45, min(2.4, oldScale * multiplier))
        guard nextScale != oldScale else { return }

        let ratio = nextScale / oldScale
        camera.position = CGPoint(
            x: anchor.x + (camera.position.x - anchor.x) * ratio,
            y: anchor.y + (camera.position.y - anchor.y) * ratio
        )
        camera.setScale(nextScale)
        clampCamera()
    }

    private func redraw() {
        // v0.21: 保 camera，只清内容节点
        let cameraRef = boardCamera
        removeAllChildren()
        if let cameraRef {
            addChild(cameraRef)
            self.camera = cameraRef
            self.boardCamera = cameraRef
        }

        guard let renderState else {
            drawEmptyState()
            return
        }

        let state = renderState.gameState
        // v0.21: 固定大 hexSize（~36），不再 fitted 塞满 scene。超出靠平移（任务 0.2）。
        let layout = HexLayout.fixed(mapWidth: state.map.width, mapHeight: state.map.height)
        self.layout = layout

        drawTiles(renderState: renderState, layout: layout)
        drawLayerOverlay(renderState: renderState, layout: layout)
        drawRegionOverlays(renderState: renderState, layout: layout)
        drawRoads(map: state.map, layout: layout)
        drawRivers(map: state.map, layout: layout)
        drawSupplyRoutes(renderState: renderState, layout: layout)
        drawPlannedOperations(renderState: renderState, layout: layout)
        drawFocusedObjective(renderState: renderState, layout: layout)
        drawUnits(renderState: renderState, layout: layout)
    }

    private func drawTiles(renderState: BoardRenderState, layout: HexLayout) {
        let state = renderState.gameState
        let supplyByCoord = Dictionary(uniqueKeysWithValues: state.map.supplySources.compactMap { source in
            state.map.controllingFaction(for: source).map { (source.coord, $0) }
        })
        let adapter = renderState.displayAdapter

        for tile in state.map.tiles.values.sorted(by: tileSort) {
            guard let displayState = adapter.hexDisplayState(for: tile.coord, viewerFaction: renderState.viewerFaction) else {
                continue
            }

            let node = HexNode(
                displayState: displayState,
                layout: layout,
                supplySourceFaction: supplyByCoord[tile.coord],
                isSelected: renderState.selectedHex == tile.coord,
                isMoveHighlighted: renderState.movementHighlights.contains(tile.coord),
                isAttackHighlighted: renderState.attackHighlights.contains(tile.coord)
            )
            addChild(node)
        }
    }

    private func drawRoads(map: MapState, layout: HexLayout) {
        let directions: [HexDirection] = [.east, .southEast, .southWest]

        for tile in map.tiles.values where tile.hasRoad {
            for direction in directions {
                let nextCoord = tile.coord.neighbor(in: direction)
                guard let nextTile = map.tile(at: nextCoord),
                      nextTile.hasRoad else {
                    continue
                }

                let start = layout.hexToPixel(tile.coord)
                let end = layout.hexToPixel(nextCoord)
                let path = CGMutablePath()
                path.move(to: start)
                path.addLine(to: end)

                let road = SKShapeNode(path: path)
                road.strokeColor = TerrainStyle.roadStroke
                road.lineWidth = max(2, layout.hexSize * 0.08)
                road.lineCap = .round
                road.zPosition = 15
                addChild(road)
            }
        }
    }

    private func drawRegionOverlays(renderState: BoardRenderState, layout: HexLayout) {
        guard renderState.mapDisplayLayer == .hex else {
            return
        }

        for region in renderState.gameState.map.regions.values {
            let node = RegionOverlayNode(
                region: region,
                layout: layout,
                isSelected: renderState.selectedRegionId == region.id
            )
            addChild(node)
        }
    }

    private func drawLayerOverlay(renderState: BoardRenderState, layout: HexLayout) {
        let node = MapLayerOverlayNode(
            state: renderState.gameState,
            layer: renderState.mapDisplayLayer,
            layout: layout
        )
        addChild(node)
    }

    private func drawRivers(map: MapState, layout: HexLayout) {
        for tile in map.tiles.values {
            let center = layout.hexToPixel(tile.coord)
            for direction in HexDirection.ordered where tile.riverEdges.contains(direction) {
                let edge = layout.edgePoints(center: center, direction: direction)
                let path = CGMutablePath()
                path.move(to: edge.0)
                path.addLine(to: edge.1)

                let river = SKShapeNode(path: path)
                river.strokeColor = TerrainStyle.riverStroke
                river.lineWidth = max(3, layout.hexSize * 0.10)
                river.lineCap = .round
                river.zPosition = 18
                addChild(river)
            }
        }
    }

    private func drawSupplyRoutes(renderState: BoardRenderState, layout: HexLayout) {
        guard renderState.showsSupplyRoutes,
              renderState.mapDisplayLayer == .hex else {
            return
        }

        let state = renderState.gameState
        let selectedUnitId = renderState.selectedUnitId
        let supplyRules = SupplyRules()
        let divisions = state.divisions
            .filter { $0.faction == renderState.viewerFaction && !$0.isDestroyed }
            .sorted { lhs, rhs in
                let lhsSelected = lhs.id == selectedUnitId
                let rhsSelected = rhs.id == selectedUnitId
                if lhsSelected != rhsSelected {
                    return lhsSelected
                }
                if lhs.supplyState != rhs.supplyState {
                    return lhs.supplyState.routePriority < rhs.supplyState.routePriority
                }
                if lhs.coord.r != rhs.coord.r {
                    return lhs.coord.r < rhs.coord.r
                }
                if lhs.coord.q != rhs.coord.q {
                    return lhs.coord.q < rhs.coord.q
                }
                return lhs.id < rhs.id
            }

        var drawnSegments: Set<String> = []
        for division in divisions.prefix(18) {
            guard let path = supplyRules.supplyPath(for: division, in: state),
                  path.count >= 2 else {
                continue
            }

            drawSupplyRoute(
                path: path,
                layout: layout,
                emphasized: division.id == selectedUnitId,
                drawnSegments: &drawnSegments
            )
        }
    }

    private func drawSupplyRoute(
        path: [HexCoord],
        layout: HexLayout,
        emphasized: Bool,
        drawnSegments: inout Set<String>
    ) {
        for pair in zip(path, path.dropFirst()) {
            let key = supplyRouteSegmentKey(pair.0, pair.1)
            guard emphasized || drawnSegments.insert(key).inserted else {
                continue
            }
            drawSupplyRouteSegment(
                from: layout.hexToPixel(pair.0),
                to: layout.hexToPixel(pair.1),
                emphasized: emphasized
            )
        }
    }

    private func drawSupplyRouteSegment(from start: CGPoint, to end: CGPoint, emphasized: Bool) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let dash: CGFloat = emphasized ? 11 : 8
        let gap: CGFloat = emphasized ? 5 : 7

        let glowPath = CGMutablePath()
        glowPath.move(to: start)
        glowPath.addLine(to: end)
        let glow = SKShapeNode(path: glowPath)
        glow.strokeColor = TerrainStyle.supplyRouteGlow
        glow.lineWidth = emphasized ? 6 : 4
        glow.lineCap = .round
        glow.zPosition = 18.6
        addChild(glow)

        var offset: CGFloat = 0
        while offset < length {
            let next = min(offset + dash, length)
            let startRatio = offset / length
            let endRatio = next / length
            let dashPath = CGMutablePath()
            dashPath.move(to: CGPoint(x: start.x + dx * startRatio, y: start.y + dy * startRatio))
            dashPath.addLine(to: CGPoint(x: start.x + dx * endRatio, y: start.y + dy * endRatio))

            let route = SKShapeNode(path: dashPath)
            route.strokeColor = TerrainStyle.supplyRouteStroke
            route.lineWidth = emphasized ? 3.2 : 2.2
            route.lineCap = .round
            route.zPosition = 19
            addChild(route)

            offset += dash + gap
        }
    }

    private func supplyRouteSegmentKey(_ lhs: HexCoord, _ rhs: HexCoord) -> String {
        let first: HexCoord
        let second: HexCoord
        if lhs.q == rhs.q {
            first = lhs.r <= rhs.r ? lhs : rhs
            second = lhs.r <= rhs.r ? rhs : lhs
        } else {
            first = lhs.q < rhs.q ? lhs : rhs
            second = lhs.q < rhs.q ? rhs : lhs
        }
        return "\(first.q),\(first.r)-\(second.q),\(second.r)"
    }

    private func drawPlannedOperations(renderState: BoardRenderState, layout: HexLayout) {
        guard renderState.mapDisplayLayer != .frontLine else {
            return
        }

        let operations = renderState.gameState.playerCommandState.plannedOperations.filter {
            $0.turn == renderState.gameState.turn && $0.faction == renderState.viewerFaction
        }
        guard !operations.isEmpty else {
            return
        }

        for operation in operations {
            guard let sourcePoint = operationPoint(
                regionId: operation.sourceRegionId,
                zoneId: operation.zoneId,
                state: renderState.gameState,
                layout: layout
            ) else {
                continue
            }

            if let targetRegionId = operation.targetRegionId,
               let targetPoint = operationPoint(
                regionId: targetRegionId,
                zoneId: operation.zoneId,
                state: renderState.gameState,
                layout: layout
               ) {
                drawOperationArrow(
                    from: sourcePoint,
                    to: targetPoint,
                    type: operation.directiveType
                )
            } else {
                drawOperationHoldMarker(at: sourcePoint)
            }
        }
    }

    private func operationPoint(
        regionId: RegionId?,
        zoneId: FrontZoneId,
        state: GameState,
        layout: HexLayout
    ) -> CGPoint? {
        if let regionId,
           let hex = state.map.representativeHex(for: regionId) {
            return layout.hexToPixel(hex)
        }

        guard let zone = state.warDeploymentState.frontZones[zoneId] else {
            return nil
        }
        let hqRegionId = zone.generalAssignment?.hqRegionId ?? zone.regionIds.first
        guard let hqRegionId,
              let hex = state.map.representativeHex(for: hqRegionId) else {
            return nil
        }
        return layout.hexToPixel(hex)
    }

    private func drawOperationArrow(from start: CGPoint, to end: CGPoint, type: DirectiveType) {
        let color = operationColor(for: type)
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let glow = SKShapeNode(path: path)
        glow.strokeColor = operationGlowColor(for: type)
        glow.lineWidth = 9
        glow.lineCap = .round
        glow.zPosition = 25.5
        addChild(glow)

        let line = SKShapeNode(path: path)
        line.strokeColor = color
        line.lineWidth = 3.4
        line.lineCap = .round
        line.lineJoin = .round
        line.zPosition = 26
        addChild(line)

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 16
        let spread: CGFloat = .pi / 7
        let left = CGPoint(
            x: end.x - cos(angle - spread) * arrowLength,
            y: end.y - sin(angle - spread) * arrowLength
        )
        let right = CGPoint(
            x: end.x - cos(angle + spread) * arrowLength,
            y: end.y - sin(angle + spread) * arrowLength
        )
        let headPath = CGMutablePath()
        headPath.move(to: end)
        headPath.addLine(to: left)
        headPath.move(to: end)
        headPath.addLine(to: right)

        let head = SKShapeNode(path: headPath)
        head.strokeColor = color
        head.lineWidth = 3.4
        head.lineCap = .round
        head.zPosition = 27
        addChild(head)

        drawOperationSeal(
            text: type == .attack ? "进" : "守",
            at: operationSealPoint(from: start, to: end),
            color: color
        )
    }

    private func drawOperationHoldMarker(at point: CGPoint) {
        let glow = SKShapeNode(circleOfRadius: 24)
        glow.position = point
        glow.strokeColor = operationGlowColor(for: .defend)
        glow.fillColor = operationGlowColor(for: .defend)
        glow.lineWidth = 2
        glow.zPosition = 25.5
        addChild(glow)

        let marker = SKShapeNode(circleOfRadius: 18)
        marker.position = point
        marker.strokeColor = operationColor(for: .defend)
        marker.fillColor = operationColor(for: .defend).withAlphaComponent(0.16)
        marker.lineWidth = 3.4
        marker.zPosition = 26
        addChild(marker)

        drawOperationSeal(text: "守", at: point, color: operationColor(for: .defend))
    }

    private func drawOperationSeal(text: String, at point: CGPoint, color: SKColor) {
        let seal = SKShapeNode(rectOf: CGSize(width: 24, height: 22), cornerRadius: 5)
        seal.position = point
        seal.fillColor = color.withAlphaComponent(0.92)
        seal.strokeColor = SKColor(red: 0.24, green: 0.12, blue: 0.06, alpha: 0.88)
        seal.lineWidth = 1.2
        seal.zPosition = 28
        addChild(seal)

        let label = SKLabelNode(text: text)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 13
        label.fontColor = SKColor(white: 0.98, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = point
        label.zPosition = 29
        addChild(label)
    }

    private func operationSealPoint(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let mid = CGPoint(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        return CGPoint(x: mid.x - dy / length * 14, y: mid.y + dx / length * 14)
    }

    private func operationColor(for type: DirectiveType) -> SKColor {
        switch type {
        case .attack:
            return SKColor(red: 0.86, green: 0.18, blue: 0.12, alpha: 0.92)
        case .defend:
            return SKColor(red: 0.16, green: 0.54, blue: 0.34, alpha: 0.92)
        }
    }

    private func operationGlowColor(for type: DirectiveType) -> SKColor {
        switch type {
        case .attack:
            return SKColor(red: 0.36, green: 0.08, blue: 0.04, alpha: 0.34)
        case .defend:
            return SKColor(red: 0.04, green: 0.18, blue: 0.12, alpha: 0.34)
        }
    }

    private func drawFocusedObjective(renderState: BoardRenderState, layout: HexLayout) {
        guard let objectiveId = renderState.focusedObjectiveId,
              let objective = renderState.gameState.map.objective(id: objectiveId) else {
            return
        }

        let summary = BattleObjectiveSummary.from(state: renderState.gameState)
        let track = summary.tracks.first { track in
            track.targets.contains { $0.objectiveId == objectiveId }
        }
        let tint = objectiveFocusColor(for: track)
        let targetIds = track?.targets.map(\.objectiveId) ?? [objectiveId]
        let center = layout.hexToPixel(objective.coord)

        for targetId in targetIds where targetId != objectiveId {
            guard let targetObjective = renderState.gameState.map.objective(id: targetId) else {
                continue
            }
            let targetPoint = layout.hexToPixel(targetObjective.coord)
            drawObjectiveLink(from: center, to: targetPoint, tint: tint)
            drawObjectiveCompanionMarker(
                at: targetPoint,
                objective: targetObjective,
                tint: tint
            )
        }

        drawFocusedObjectiveMarker(
            at: center,
            objective: objective,
            track: track,
            controller: renderState.gameState.map.tile(at: objective.coord)?.controller,
            tint: tint,
            layout: layout
        )
    }

    private func drawObjectiveLink(from start: CGPoint, to end: CGPoint, tint: SKColor) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let glow = SKShapeNode(path: path)
        glow.strokeColor = SKColor(red: 0.08, green: 0.04, blue: 0.02, alpha: 0.42)
        glow.lineWidth = 7
        glow.lineCap = .round
        glow.zPosition = 31
        addChild(glow)

        let line = SKShapeNode(path: path)
        line.strokeColor = tint.withAlphaComponent(0.78)
        line.lineWidth = 2.8
        line.lineCap = .round
        line.zPosition = 32
        addChild(line)
    }

    private func drawObjectiveCompanionMarker(at point: CGPoint, objective: Objective, tint: SKColor) {
        let marker = SKShapeNode(circleOfRadius: 9)
        marker.position = point
        marker.fillColor = tint.withAlphaComponent(0.30)
        marker.strokeColor = tint.withAlphaComponent(0.88)
        marker.lineWidth = 2
        marker.zPosition = 33
        addChild(marker)

        let dot = SKShapeNode(circleOfRadius: 3.5)
        dot.position = point
        dot.fillColor = SKColor(white: 0.98, alpha: 0.94)
        dot.strokeColor = tint
        dot.lineWidth = 0.8
        dot.zPosition = 34
        addChild(dot)

        let label = objectiveLabel(text: objective.name, point: CGPoint(x: point.x, y: point.y - 17), fontSize: 9)
        label.zPosition = 35
        addChild(label)
    }

    private func drawFocusedObjectiveMarker(
        at point: CGPoint,
        objective: Objective,
        track: BattleObjectiveSummary.Track?,
        controller: Faction?,
        tint: SKColor,
        layout: HexLayout
    ) {
        let pulse = SKShapeNode(circleOfRadius: layout.hexSize * 0.62)
        pulse.position = point
        pulse.fillColor = tint.withAlphaComponent(0.10)
        pulse.strokeColor = tint.withAlphaComponent(0.80)
        pulse.lineWidth = max(2.4, layout.hexSize * 0.06)
        pulse.zPosition = 36
        addChild(pulse)
        let pulseAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.20, duration: 0.72),
                SKAction.fadeAlpha(to: 0.38, duration: 0.72)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.00, duration: 0.72),
                SKAction.fadeAlpha(to: 1.00, duration: 0.72)
            ])
        ])
        pulse.run(SKAction.repeatForever(pulseAction))

        let ring = SKShapeNode(circleOfRadius: layout.hexSize * 0.42)
        ring.position = point
        ring.fillColor = SKColor(white: 0.02, alpha: 0.16)
        ring.strokeColor = tint
        ring.lineWidth = max(2.8, layout.hexSize * 0.07)
        ring.zPosition = 37
        addChild(ring)

        let seal = SKShapeNode(rectOf: CGSize(width: 30, height: 24), cornerRadius: 5)
        seal.position = CGPoint(x: point.x, y: point.y + layout.hexSize * 0.48)
        seal.fillColor = tint.withAlphaComponent(0.94)
        seal.strokeColor = SKColor(red: 0.22, green: 0.10, blue: 0.04, alpha: 0.92)
        seal.lineWidth = 1.2
        seal.zPosition = 46
        addChild(seal)

        let sealText = SKLabelNode(text: "标")
        sealText.fontName = "PingFangSC-Semibold"
        sealText.fontSize = 14
        sealText.fontColor = SKColor(white: 0.98, alpha: 1)
        sealText.horizontalAlignmentMode = .center
        sealText.verticalAlignmentMode = .center
        sealText.position = seal.position
        sealText.zPosition = 47
        addChild(sealText)

        let name = objectiveLabel(
            text: objective.name,
            point: CGPoint(x: point.x, y: point.y - layout.hexSize * 0.54),
            fontSize: max(10, layout.hexSize * 0.18)
        )
        name.zPosition = 47
        addChild(name)

        if let controller {
            let controllerLabel = objectiveLabel(
                text: controller.displayName,
                point: CGPoint(x: point.x, y: point.y - layout.hexSize * 0.78),
                fontSize: max(8, layout.hexSize * 0.14)
            )
            controllerLabel.fontColor = TerrainStyle.controllerColor(for: controller)
            controllerLabel.zPosition = 47
            addChild(controllerLabel)
        }

        if let track {
            let trackLabel = objectiveLabel(
                text: track.title,
                point: CGPoint(x: point.x, y: point.y + layout.hexSize * 0.78),
                fontSize: max(8, layout.hexSize * 0.14)
            )
            trackLabel.zPosition = 47
            addChild(trackLabel)
        }
    }

    private func objectiveLabel(text: String, point: CGPoint, fontSize: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = fontSize
        label.fontColor = SKColor(white: 0.98, alpha: 1)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = point
        let background = SKShapeNode(
            rectOf: CGSize(
                width: max(34, CGFloat(text.count) * fontSize * 0.92),
                height: fontSize + 8
            ),
            cornerRadius: 4
        )
        background.fillColor = SKColor(white: 0.04, alpha: 0.64)
        background.strokeColor = SKColor(white: 1, alpha: 0.18)
        background.lineWidth = 0.8
        background.position = CGPoint.zero
        background.zPosition = -1
        label.addChild(background)
        return label
    }

    private func objectiveFocusColor(for track: BattleObjectiveSummary.Track?) -> SKColor {
        guard let track else {
            return SKColor(red: 0.96, green: 0.72, blue: 0.24, alpha: 1)
        }
        return TerrainStyle.controllerColor(for: track.faction)
    }

    private func drawUnits(renderState: BoardRenderState, layout: HexLayout) {
        guard renderState.mapDisplayLayer != .frontLine else {
            return
        }
        let adapter = renderState.displayAdapter
        let placements = adapter.unitPlacements(viewerFaction: renderState.viewerFaction)
        let deploymentManager = WarDeploymentManager()

        let orderedDivisions = renderState.gameState.divisions
            .map { division in
                (division: division, displayHex: adapter.unitDisplayHex(for: division) ?? division.coord)
            }
            .sorted { lhs, rhs in
                let lhsHex = lhs.displayHex
                let rhsHex = rhs.displayHex
                if lhsHex.r == rhsHex.r {
                    return lhsHex.q < rhsHex.q
                }
                return lhsHex.r < rhsHex.r
            }

        for item in orderedDivisions {
            let division = item.division
            guard let placement = placements[division.id] else {
                continue
            }

            let node = UnitNode(
                division: division,
                layout: layout,
                placement: placement,
                isSelected: renderState.selectedUnitId == division.id,
                isPlayerManaged: renderState.gameState.playerCommandState.micromanagedDivisionIds.contains(division.id),
                fillColorOverride: deploymentColorOverride(
                    for: division,
                    renderState: renderState,
                    deploymentManager: deploymentManager
                )
            )
            addChild(node)
        }
    }

    private func deploymentColorOverride(
        for division: Division,
        renderState: BoardRenderState,
        deploymentManager: WarDeploymentManager
    ) -> SKColor? {
        guard renderState.mapDisplayLayer == .deployment else {
            return nil
        }
        let role = deploymentManager.deploymentRole(
            for: division,
            in: renderState.gameState.map,
            state: renderState.gameState.warDeploymentState
        )
        return TerrainStyle.deploymentUnitColor(for: division.faction, role: role)
    }

    private func drawEmptyState() {
        let field = SKShapeNode(
            rectOf: CGSize(width: max(size.width - 48, 120), height: max(size.height - 48, 120)),
            cornerRadius: 8
        )
        field.fillColor = SKColor(red: 0.24, green: 0.30, blue: 0.22, alpha: 1.0)
        field.strokeColor = SKColor(red: 0.55, green: 0.60, blue: 0.48, alpha: 1.0)
        field.lineWidth = 2
        field.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(field)

        let title = SKLabelNode(text: "明末棋策舆图")
        title.fontName = "PingFangSC-Semibold"
        title.fontSize = 24
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        addChild(title)
    }

    private func tileSort(_ lhs: HexTile, _ rhs: HexTile) -> Bool {
        if lhs.coord.r == rhs.coord.r {
            return lhs.coord.q < rhs.coord.q
        }
        return lhs.coord.r < rhs.coord.r
    }
}

private extension SupplyState {
    var routePriority: Int {
        switch self {
        case .supplied:
            return 0
        case .lowSupply:
            return 1
        case .encircled:
            return 2
        }
    }
}
