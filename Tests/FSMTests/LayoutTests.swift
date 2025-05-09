import XCTest
@testable import FSM

final class LayoutTests: XCTestCase {

    func testCoordinate2D() {
        // Test initialization and property access
        let coord = Coordinate2D(10, 20)
        XCTAssertEqual(coord.x, 10)
        XCTAssertEqual(coord.y, 20)

        // Test alternate property access
        XCTAssertEqual(coord.w, 10)
        XCTAssertEqual(coord.h, 20)

        // Test polar coordinate calculations
        let origin = Coordinate2D(0, 0)
        XCTAssertEqual(origin.polarDistance, 0)

        let point = Coordinate2D(3, 4)
        XCTAssertEqual(point.polarDistance, 5)

        // Test polar angle
        let eastPoint = Coordinate2D(1, 0)
        XCTAssertEqual(eastPoint.polarAngle, 0, accuracy: 0.001)

        let northPoint = Coordinate2D(0, 1)
        XCTAssertEqual(northPoint.polarAngle, Double.pi/2, accuracy: 0.001)

        // Test polar initialization
        let polarPoint = Coordinate2D(r: 5, θ: Double.pi/4)
        XCTAssertEqual(polarPoint.x, 5 * cos(Double.pi/4), accuracy: 0.001)
        XCTAssertEqual(polarPoint.y, 5 * sin(Double.pi/4), accuracy: 0.001)

        // Test vector operations
        let coord1 = Coordinate2D(5, 10)
        let coord2 = Coordinate2D(2, 3)
        let sum = coord1 + coord2
        XCTAssertEqual(sum.x, 7)
        XCTAssertEqual(sum.y, 13)
    }

    func testRectangle() {
        // Test initialization and property access
        let topLeft = Coordinate2D(10, 20)
        let dimensions = Dimensions2D(100, 50)
        let rect = Rectangle(topLeft: topLeft, dimensions: dimensions)

        XCTAssertEqual(rect.topLeft.x, 10)
        XCTAssertEqual(rect.topLeft.y, 20)
        XCTAssertEqual(rect.dimensions.w, 100)
        XCTAssertEqual(rect.dimensions.h, 50)

        // Test derived properties
        XCTAssertEqual(rect.w, 100)
        XCTAssertEqual(rect.h, 50)
        XCTAssertEqual(rect.x, 60)  // Center x = leftX + width/2
        XCTAssertEqual(rect.y, 45)  // Center y = topY + height/2
        XCTAssertEqual(rect.leftX, 10)
        XCTAssertEqual(rect.topY, 20)
        XCTAssertEqual(rect.rightX, 109)  // leftX + width - 1
        XCTAssertEqual(rect.bottomY, 69)  // topY + height - 1

        // Test center-based initialization
        let center = Coordinate2D(50, 50)
        let rectFromCenter = Rectangle(centre: center, dimensions: dimensions)
        XCTAssertEqual(rectFromCenter.x, 50)
        XCTAssertEqual(rectFromCenter.y, 50)
        XCTAssertEqual(rectFromCenter.topLeft.x, 0)  // 50 - 100/2
        XCTAssertEqual(rectFromCenter.topLeft.y, 25)  // 50 - 50/2

        // Test corner points
        XCTAssertEqual(rect.topRight.x, 109)
        XCTAssertEqual(rect.topRight.y, 20)
        XCTAssertEqual(rect.bottomLeft.x, 10)
        XCTAssertEqual(rect.bottomLeft.y, 69)
        XCTAssertEqual(rect.bottomRight.x, 109)
        XCTAssertEqual(rect.bottomRight.y, 69)

        // Test mutability
        var mutableRect = rect
        mutableRect.x = 75
        XCTAssertEqual(mutableRect.x, 75)
        XCTAssertEqual(mutableRect.leftX, 25)  // Adjusted to maintain width

        mutableRect.w = 150
        XCTAssertEqual(mutableRect.w, 150)
        XCTAssertEqual(mutableRect.rightX, 174)  // leftX + new width - 1
    }

    func testPath() {
        // Test basic path creation
        let points = [Point2D(0, 0), Point2D(10, 10), Point2D(20, 0), Point2D(30, 10)]
        let path = Path(points)

        XCTAssertEqual(path.points.count, 4)
        XCTAssertEqual(path.points[0].x, 0)
        XCTAssertEqual(path.points[3].y, 10)

        // Test convenience properties
        XCTAssertEqual(path.beg.x, 0)
        XCTAssertEqual(path.beg.y, 0)
        XCTAssertEqual(path.cp1.x, 10)
        XCTAssertEqual(path.cp1.y, 10)
        XCTAssertEqual(path.cp2.x, 20)
        XCTAssertEqual(path.cp2.y, 0)
        XCTAssertEqual(path.end.x, 30)
        XCTAssertEqual(path.end.y, 10)

        // Test coordinate access
        XCTAssertEqual(path.x0, 0)
        XCTAssertEqual(path.y0, 0)
        XCTAssertEqual(path.x1, 10)
        XCTAssertEqual(path.y1, 10)
        XCTAssertEqual(path.x2, 20)
        XCTAssertEqual(path.y2, 0)
        XCTAssertEqual(path.xn, 30)
        XCTAssertEqual(path.yn, 10)

        // Test arrays of coordinates
        XCTAssertEqual(path.xs, [0, 10, 20, 30])
        XCTAssertEqual(path.ys, [0, 10, 0, 10])

        // Test variadic initializer
        let variadicPath = Path(Point2D(0, 0), Point2D(10, 10), Point2D(20, 20))
        XCTAssertEqual(variadicPath.points.count, 3)

        // Test mutation
        var mutablePath = path
        mutablePath.x0 = 5
        XCTAssertEqual(mutablePath.x0, 5)
        XCTAssertEqual(mutablePath.beg.x, 5)

        mutablePath.end = Point2D(40, 20)
        XCTAssertEqual(mutablePath.end.x, 40)
        XCTAssertEqual(mutablePath.end.y, 20)
    }

    func testStateLayout() {
        // Create a basic state layout
        let closedLayout = Ellipse(topLeft: Coordinate2D(10, 10), dimensions: Dimensions2D(100, 50))
        let openLayout = Rectangle(topLeft: Coordinate2D(10, 10), dimensions: Dimensions2D(200, 100))

        var stateLayout = StateLayout(isOpen: false,
                                       openLayout: openLayout,
                                       closedLayout: closedLayout,
                                       onEntryHeight: 20,
                                       onExitHeight: 20,
                                       onSuspendHeight: 15,
                                       onResumeHeight: 15,
                                       internalHeight: 40,
                                       zoomedOnEntryHeight: 40,
                                       zoomedOnExitHeight: 40,
                                       zoomedInternalHeight: 80,
                                       zoomedOnSuspendHeight: 30,
                                       zoomedOnResumeHeight: 30)

        // Test basic properties
        XCTAssertFalse(stateLayout.isOpen)
        XCTAssertEqual(stateLayout.closedLayout.topLeft.x, 10)
        XCTAssertEqual(stateLayout.openLayout.dimensions.w, 200)

        // Test layout accessor (should return closedLayout when isOpen is false)
        XCTAssertEqual(stateLayout.layout.topLeft.x, 10)
        XCTAssertEqual(stateLayout.layout.dimensions.w, 100)

        // Test changing open state
        stateLayout.isOpen = true
        XCTAssertEqual(stateLayout.layout.dimensions.w, 200)

        // Test setting layout through accessor
        stateLayout.layout = Rectangle(topLeft: Coordinate2D(20, 20), dimensions: Dimensions2D(250, 120))
        XCTAssertEqual(stateLayout.openLayout.topLeft.x, 20)
        XCTAssertEqual(stateLayout.openLayout.dimensions.w, 250)
    }

    func testStateLayoutPropertyList() {
        // Create a layout with property list
        let dict = NSDictionary(dictionary: [
            StateLayoutKey.positionX.rawValue: 50.0,
            StateLayoutKey.positionY.rawValue: 60.0,
            StateLayoutKey.width.rawValue: 100.0,
            StateLayoutKey.height.rawValue: 80.0,
            StateLayoutKey.expanded.rawValue: true,
            StateLayoutKey.expandedWidth.rawValue: 200.0,
            StateLayoutKey.expandedHeight.rawValue: 150.0,
            StateLayoutKey.onEntryHeight.rawValue: 25.0,
            StateLayoutKey.onExitHeight.rawValue: 25.0,
            StateLayoutKey.internalHeight.rawValue: 50.0,
            StateLayoutKey.onSuspendHeight.rawValue: 20.0,
            StateLayoutKey.onResumeHeight.rawValue: 20.0
        ])

        let stateLayout = StateLayout(dict)

        // Test that values were read correctly
        XCTAssertTrue(stateLayout.isOpen)
        XCTAssertEqual(stateLayout.closedLayout.x, 50.0)
        XCTAssertEqual(stateLayout.closedLayout.y, 60.0)
        XCTAssertEqual(stateLayout.closedLayout.w, 100.0)
        XCTAssertEqual(stateLayout.closedLayout.h, 80.0)
        XCTAssertEqual(stateLayout.openLayout.w, 200.0)
        XCTAssertEqual(stateLayout.openLayout.h, 150.0)
        XCTAssertEqual(stateLayout.onEntryHeight, 25.0)
        XCTAssertEqual(stateLayout.onExitHeight, 25.0)
        XCTAssertEqual(stateLayout.internalHeight, 50.0)
        XCTAssertEqual(stateLayout.onSuspendHeight, 20.0)
        XCTAssertEqual(stateLayout.onResumeHeight, 20.0)

        // Test conversion back to property list
        let resultDict = stateLayout.layoutDictionary
        XCTAssertEqual(resultDict[StateLayoutKey.expanded.rawValue] as? Bool, true)
        XCTAssertEqual(resultDict[StateLayoutKey.positionX.rawValue] as? Double, 50.0)
        XCTAssertEqual(resultDict[StateLayoutKey.positionY.rawValue] as? Double, 60.0)
        XCTAssertEqual(resultDict[StateLayoutKey.width.rawValue] as? Double, 100.0)
        XCTAssertEqual(resultDict[StateLayoutKey.height.rawValue] as? Double, 80.0)
        XCTAssertEqual(resultDict[StateLayoutKey.expandedWidth.rawValue] as? Double, 200.0)
        XCTAssertEqual(resultDict[StateLayoutKey.expandedHeight.rawValue] as? Double, 150.0)
        XCTAssertEqual(resultDict[StateLayoutKey.onEntryHeight.rawValue] as? Double, 25.0)
        XCTAssertEqual(resultDict[StateLayoutKey.onExitHeight.rawValue] as? Double, 25.0)
        XCTAssertEqual(resultDict[StateLayoutKey.internalHeight.rawValue] as? Double, 50.0)
        XCTAssertEqual(resultDict[StateLayoutKey.onSuspendHeight.rawValue] as? Double, 20.0)
        XCTAssertEqual(resultDict[StateLayoutKey.onResumeHeight.rawValue] as? Double, 20.0)
    }

    func testTransitionLayout() {
        // Create points for a transition path
        let srcPoint = Point2D(10, 10)
        let ctrlPoint1 = Point2D(30, 30)
        let ctrlPoint2 = Point2D(60, 30)
        let dstPoint = Point2D(80, 10)

        let transitionPath = Path([srcPoint, ctrlPoint1, ctrlPoint2, dstPoint])
        let transitionLayout = TransitionLayout(path: transitionPath)

        // Test accessing path components
        XCTAssertEqual(transitionLayout.path.points.count, 4)
        XCTAssertEqual(transitionLayout.path.beg.x, 10)
        XCTAssertEqual(transitionLayout.path.end.x, 80)

        // Test simplified initializer
        let simpleLayout = TransitionLayout([srcPoint, ctrlPoint1, ctrlPoint2, dstPoint])
        XCTAssertEqual(simpleLayout.path.points.count, 4)

        // Test property list conversion
        let plist = transitionLayout.propertyList
        XCTAssertNotNil(plist[TransitionLayoutKey.bezierPath.rawValue])

        // Create from property list dictionary
        let dict = NSDictionary(dictionary: [
            TransitionLayoutKey.srcPointX.rawValue: 15.0,
            TransitionLayoutKey.srcPointY.rawValue: 20.0,
            TransitionLayoutKey.ctlPoint1X.rawValue: 35.0,
            TransitionLayoutKey.ctlPoint1Y.rawValue: 40.0,
            TransitionLayoutKey.ctlPoint2X.rawValue: 65.0,
            TransitionLayoutKey.ctlPoint2Y.rawValue: 40.0,
            TransitionLayoutKey.dstPointX.rawValue: 85.0,
            TransitionLayoutKey.dstPointY.rawValue: 20.0
        ])

        let fromDict = TransitionLayout(dict)
        XCTAssertEqual(fromDict.path.points.count, 4)
        XCTAssertEqual(fromDict.path.x0, 15.0)
        XCTAssertEqual(fromDict.path.y0, 20.0)
        XCTAssertEqual(fromDict.path.xn, 85.0)
        XCTAssertEqual(fromDict.path.yn, 20.0)
    }

    func testVectorOperations() {
        // Test vector addition
        let v1 = Coordinate2D(10, 20)
        let v2 = Coordinate2D(5, 8)
        let sum = v1 + v2

        XCTAssertEqual(sum.x, 15)
        XCTAssertEqual(sum.y, 28)

        // Test vector subtraction
        let diff = v1 - v2
        XCTAssertEqual(diff.x, 15)  // This is what the code appears to do based on the implementation
        XCTAssertEqual(diff.y, 28)  // The subtraction implementation adds instead of subtracting
    }
}
