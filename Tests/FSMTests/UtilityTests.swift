import XCTest
@testable import FSM

final class UtilityTests: XCTestCase {

    func testStringExtensions() {
        // Test trimmed
        XCTAssertEqual("  hello  ".trimmed, "hello")
        XCTAssertEqual("hello".trimmed, "hello")
        XCTAssertEqual("".trimmed, "")

        // Test lines
        let multiLine = "line1\nline2\nline3"
        XCTAssertEqual(multiLine.lines.count, 3)
        XCTAssertEqual(multiLine.lines[0], "line1")
        XCTAssertEqual(multiLine.lines[1], "line2")
        XCTAssertEqual(multiLine.lines[2], "line3")

        // Test sansExtension
        XCTAssertEqual("file.txt".sansExtension, "file")
        XCTAssertEqual("file.name.ext".sansExtension, "file.name")
        XCTAssertEqual("file".sansExtension, "file")

        // Test dottedExtension
        XCTAssertEqual("file.txt".dottedExtension, ".txt")
        XCTAssertEqual("file.name.ext".dottedExtension, ".ext")
        XCTAssertEqual("file".dottedExtension, "file")

        // Test empty string
        XCTAssertEqual("".lines.count, 0)
        XCTAssertEqual("".sansExtension, "")

        // Test helper functions
        XCTAssertEqual(trimmed("  test  "), "test")
        XCTAssertTrue(nonempty("test"))
        XCTAssertFalse(nonempty(""))
    }

    func testDictionaryExtensions() {
        // Test with NSDictionary
        let nsDict = NSDictionary(dictionary: [
            StateLayoutKey.width.rawValue: 100,
            StateLayoutKey.height.rawValue: 50,
            StateLayoutKey.expanded.rawValue: true
        ])

        XCTAssertEqual(nsDict.value(.width, default: 0), 100)
        XCTAssertEqual(nsDict.value(.height, default: 0), 50)
        XCTAssertEqual(nsDict.value(.expanded, default: false), true)
        XCTAssertEqual(nsDict.value(.positionX, default: 20), 20) // Default value used

        // Test with Dictionary<AnyHashable, Any>
        var dict: [AnyHashable: Any] = [
            TransitionLayoutKey.srcPointX.rawValue: 10.0,
            TransitionLayoutKey.srcPointY.rawValue: 20.0
        ]

        XCTAssertEqual(dict.transitionValue(.srcPointX, default: 0.0), 10.0)
        XCTAssertEqual(dict.transitionValue(.srcPointY, default: 0.0), 20.0)
        XCTAssertEqual(dict.transitionValue(.dstPointX, default: 50.0), 50.0) // Default value used

        // Test optional value accessor
        XCTAssertEqual(dict.transitionValue(.srcPointX) as Double?, 10.0)
        XCTAssertNil(dict.transitionValue(.dstPointX) as Double?)

        // Test set value
        dict.set(value: 30.0, forTransition: .dstPointX)
        XCTAssertEqual(dict.transitionValue(.dstPointX, default: 0.0), 30.0)

        dict.set(value: 100, for: .width)
        XCTAssertEqual(dict.value(.width, default: 0), 100)
    }

    func testRegexUtils() throws {
        let content = "Number is 123 and another number is 456"

        // Test string extraction with regex
        let regex = try Regex<(Substring, Substring)>("Number is ([0-9]+)")
        let match = string(containedIn: content, matching: regex)
        XCTAssertEqual(match, "123")

        let noMatchRegex = try Regex<(Substring, Substring)>("XYZ is ([0-9]+)")
        let noMatch = string(containedIn: content, matching: noMatchRegex)
        XCTAssertNil(noMatch)
    }

    func testFileNameHandling() {
        // Test filename constants
        XCTAssertEqual(Filename.language, "Language")
        XCTAssertEqual(Filename.states, "States")
        XCTAssertEqual(Filename.layout, "Layout.plist")
        XCTAssertEqual(Filename.windowLayout, "WindowLayout.plist")
        XCTAssertEqual(Filename.includePath, "IncludePath")

        // Test file extension handling
        let fileName = "test.machine"
        XCTAssertEqual(fileName.sansExtension, "test")
        XCTAssertEqual(String(fileName.dottedExtension), MachineWrapper.dottedSuffix)
    }

    func testFormatHandling() {
        // Test format enum
        XCTAssertEqual(Format.c.rawValue, "c")
        XCTAssertEqual(Format.cx.rawValue, "c++")
        XCTAssertEqual(Format.cpp.rawValue, "cpp")

        // Test output language lookup
        let cLang = outputLanguage(for: .c)
        XCTAssertNotNil(cLang)
        XCTAssertEqual(cLang?.name, "c")

//        let cppLang = outputLanguage(for: .cpp)
//        XCTAssertNotNil(cppLang)

        // Test with default value
        let defaultBinding = CBinding()
        let unknownFormat: Format? = nil
        let lang = outputLanguage(for: unknownFormat, default: defaultBinding)
        XCTAssertNotNil(lang)
        XCTAssertEqual(lang?.name, "c")
    }

    func testLanguageBindingEquality() {
        let binding1 = CBinding()
        let binding2 = CBinding()
        let binding3 = ObjCPPBinding()

        XCTAssertEqual(binding1, binding2)
        XCTAssertNotEqual(binding1.name, binding3.name)

        let opt1: (any LanguageBinding)? = binding1
        let opt2: (any LanguageBinding)? = binding2
        let opt3: (any LanguageBinding)? = binding3
        let opt4: (any LanguageBinding)? = nil

        XCTAssertTrue(opt1 == opt2)
        XCTAssertFalse(opt1 == opt3)
        XCTAssertFalse(opt1 == opt4)
        XCTAssertFalse(opt2 == opt3)
        XCTAssertFalse(opt2 == opt4)
        XCTAssertFalse(opt3 == opt4)

        XCTAssertFalse(opt1 != opt2)
        XCTAssertTrue(opt1 != opt3)
        XCTAssertTrue(opt1 != opt4)
        XCTAssertTrue(opt2 != opt3)
        XCTAssertTrue(opt2 != opt4)
        XCTAssertTrue(opt3 != opt4)
    }
}
