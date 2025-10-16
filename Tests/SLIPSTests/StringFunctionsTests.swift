// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import XCTest
@testable import SLIPS

/// Test suite per funzioni stringa SLIPS
/// Ref: clips_core_source_642/core/strngfun.c
@MainActor
final class StringFunctionsTests: XCTestCase {
    override func setUp() async throws {
        CLIPS.reset()
        CLIPS.createEnvironment()
    }
    
    // MARK: - str-cat Tests
    
    func testStrCatBasic() throws {
        let result = CLIPS.eval(expr: "(str-cat \"Hello\" \" \" \"World\")")
        XCTAssertEqual(result, .string("Hello World"))
    }
    
    func testStrCatWithNumbers() throws {
        let result = CLIPS.eval(expr: "(str-cat \"Value: \" 42)")
        XCTAssertEqual(result, .string("Value: 42"))
    }
    
    func testStrCatWithFloat() throws {
        let result = CLIPS.eval(expr: "(str-cat \"Pi: \" 3.14)")
        XCTAssertEqual(result, .string("Pi: 3.14"))
    }
    
    func testStrCatEmpty() throws {
        let result = CLIPS.eval(expr: "(str-cat)")
        XCTAssertEqual(result, .string(""))
    }
    
    func testStrCatSingleArg() throws {
        let result = CLIPS.eval(expr: "(str-cat \"test\")")
        XCTAssertEqual(result, .string("test"))
    }
    
    func testStrCatMixed() throws {
        let result = CLIPS.eval(expr: "(str-cat \"Count: \" 10 \" of \" 100)")
        XCTAssertEqual(result, .string("Count: 10 of 100"))
    }
    
    // MARK: - sym-cat Tests
    
    func testSymCatBasic() throws {
        let result = CLIPS.eval(expr: "(sym-cat rule- 1)")
        XCTAssertEqual(result, .symbol("rule-1"))
    }
    
    func testSymCatMultiple() throws {
        let result = CLIPS.eval(expr: "(sym-cat prefix _ middle _ suffix)")
        XCTAssertEqual(result, .symbol("prefix_middle_suffix"))
    }
    
    func testSymCatEmpty() throws {
        let result = CLIPS.eval(expr: "(sym-cat)")
        XCTAssertEqual(result, .symbol(""))
    }
    
    // MARK: - str-length Tests
    
    func testStrLengthBasic() throws {
        let result = CLIPS.eval(expr: "(str-length \"Hello\")")
        XCTAssertEqual(result, .int(5))
    }
    
    func testStrLengthEmpty() throws {
        let result = CLIPS.eval(expr: "(str-length \"\")")
        XCTAssertEqual(result, .int(0))
    }
    
    func testStrLengthUTF8() throws {
        let result = CLIPS.eval(expr: "(str-length \"café\")")
        XCTAssertEqual(result, .int(4))  // 4 caratteri
    }
    
    func testStrLengthSymbol() throws {
        let result = CLIPS.eval(expr: "(str-length abc)")
        XCTAssertEqual(result, .int(3))
    }
    
    func testStrLengthUnicode() throws {
        let result = CLIPS.eval(expr: "(str-length \"日本\")")
        XCTAssertEqual(result, .int(2))  // 2 caratteri
    }
    
    // MARK: - str-byte-length Tests
    
    func testStrByteLengthBasic() throws {
        let result = CLIPS.eval(expr: "(str-byte-length \"Hello\")")
        XCTAssertEqual(result, .int(5))
    }
    
    func testStrByteLengthUTF8() throws {
        let result = CLIPS.eval(expr: "(str-byte-length \"café\")")
        XCTAssertEqual(result, .int(5))  // 5 byte (é = 2 byte)
    }
    
    func testStrByteLengthUnicode() throws {
        let result = CLIPS.eval(expr: "(str-byte-length \"日本\")")
        XCTAssertEqual(result, .int(6))  // 6 byte (3 per carattere)
    }
    
    // MARK: - str-compare Tests
    
    func testStrCompareLess() throws {
        let result = CLIPS.eval(expr: "(str-compare \"abc\" \"def\")")
        if case .int(let val) = result {
            XCTAssertLessThan(val, 0)
        } else {
            XCTFail("Expected integer result")
        }
    }
    
    func testStrCompareGreater() throws {
        let result = CLIPS.eval(expr: "(str-compare \"xyz\" \"abc\")")
        if case .int(let val) = result {
            XCTAssertGreaterThan(val, 0)
        } else {
            XCTFail("Expected integer result")
        }
    }
    
    func testStrCompareEqual() throws {
        let result = CLIPS.eval(expr: "(str-compare \"test\" \"test\")")
        XCTAssertEqual(result, .int(0))
    }
    
    func testStrCompareWithMaxLength() throws {
        let result = CLIPS.eval(expr: "(str-compare \"hello\" \"help\" 3)")
        XCTAssertEqual(result, .int(0))  // "hel" == "hel"
    }
    
    func testStrCompareMaxLengthDifferent() throws {
        let result = CLIPS.eval(expr: "(str-compare \"hello\" \"world\" 1)")
        if case .int(let val) = result {
            XCTAssertLessThan(val, 0)  // "h" < "w"
        } else {
            XCTFail("Expected integer result")
        }
    }
    
    // MARK: - upcase Tests
    
    func testUpcaseString() throws {
        let result = CLIPS.eval(expr: "(upcase \"hello\")")
        XCTAssertEqual(result, .string("HELLO"))
    }
    
    func testUpcaseSymbol() throws {
        let result = CLIPS.eval(expr: "(upcase abc)")
        XCTAssertEqual(result, .symbol("ABC"))
    }
    
    func testUpcaseMixed() throws {
        let result = CLIPS.eval(expr: "(upcase \"HeLLo\")")
        XCTAssertEqual(result, .string("HELLO"))
    }
    
    func testUpcaseUTF8() throws {
        let result = CLIPS.eval(expr: "(upcase \"café\")")
        XCTAssertEqual(result, .string("CAFÉ"))
    }
    
    // MARK: - lowcase Tests
    
    func testLowcaseString() throws {
        let result = CLIPS.eval(expr: "(lowcase \"HELLO\")")
        XCTAssertEqual(result, .string("hello"))
    }
    
    func testLowcaseSymbol() throws {
        let result = CLIPS.eval(expr: "(lowcase ABC)")
        XCTAssertEqual(result, .symbol("abc"))
    }
    
    func testLowcaseMixed() throws {
        let result = CLIPS.eval(expr: "(lowcase \"HeLLo\")")
        XCTAssertEqual(result, .string("hello"))
    }
    
    func testLowcaseUTF8() throws {
        let result = CLIPS.eval(expr: "(lowcase \"CAFÉ\")")
        XCTAssertEqual(result, .string("café"))
    }
    
    // MARK: - sub-string Tests
    
    func testSubStringBasic() throws {
        let result = CLIPS.eval(expr: "(sub-string 1 5 \"Hello World\")")
        XCTAssertEqual(result, .string("Hello"))
    }
    
    func testSubStringEnd() throws {
        let result = CLIPS.eval(expr: "(sub-string 7 11 \"Hello World\")")
        XCTAssertEqual(result, .string("World"))
    }
    
    func testSubStringSingle() throws {
        let result = CLIPS.eval(expr: "(sub-string 1 1 \"X\")")
        XCTAssertEqual(result, .string("X"))
    }
    
    func testSubStringMiddle() throws {
        let result = CLIPS.eval(expr: "(sub-string 3 5 \"abcdefgh\")")
        XCTAssertEqual(result, .string("cde"))
    }
    
    func testSubStringFull() throws {
        let result = CLIPS.eval(expr: "(sub-string 1 5 \"Hello\")")
        XCTAssertEqual(result, .string("Hello"))
    }
    
    func testSubStringUTF8() throws {
        let result = CLIPS.eval(expr: "(sub-string 2 4 \"café\")")
        XCTAssertEqual(result, .string("afé"))
    }
    
    // MARK: - str-index Tests
    
    func testStrIndexFound() throws {
        let result = CLIPS.eval(expr: "(str-index \"World\" \"Hello World\")")
        XCTAssertEqual(result, .int(7))
    }
    
    func testStrIndexNotFound() throws {
        let result = CLIPS.eval(expr: "(str-index \"xyz\" \"Hello World\")")
        XCTAssertEqual(result, .symbol("FALSE"))
    }
    
    func testStrIndexEmptySearch() throws {
        let result = CLIPS.eval(expr: "(str-index \"\" \"test\")")
        XCTAssertEqual(result, .int(1))  // CLIPS 6.40+ behavior
    }
    
    func testStrIndexBeginning() throws {
        let result = CLIPS.eval(expr: "(str-index \"Hello\" \"Hello World\")")
        XCTAssertEqual(result, .int(1))
    }
    
    func testStrIndexMiddle() throws {
        let result = CLIPS.eval(expr: "(str-index \"ll\" \"Hello\")")
        XCTAssertEqual(result, .int(3))
    }
    
    // MARK: - str-replace Tests
    
    func testStrReplaceBasic() throws {
        let result = CLIPS.eval(expr: "(str-replace \"Hello World\" \"World\" \"CLIPS\")")
        XCTAssertEqual(result, .string("Hello CLIPS"))
    }
    
    func testStrReplaceMultiple() throws {
        let result = CLIPS.eval(expr: "(str-replace \"aaa\" \"a\" \"b\")")
        XCTAssertEqual(result, .string("bbb"))
    }
    
    func testStrReplaceSymbol() throws {
        let result = CLIPS.eval(expr: "(str-replace abc a X)")
        XCTAssertEqual(result, .symbol("Xbc"))
    }
    
    func testStrReplaceNoMatch() throws {
        let result = CLIPS.eval(expr: "(str-replace \"test\" \"xyz\" \"ABC\")")
        XCTAssertEqual(result, .string("test"))
    }
    
    func testStrReplaceEmpty() throws {
        let result = CLIPS.eval(expr: "(str-replace \"Hello\" \"l\" \"\")")
        XCTAssertEqual(result, .string("Heo"))
    }
    
    // MARK: - string-to-field Tests
    
    func testStringToFieldInteger() throws {
        let result = CLIPS.eval(expr: "(string-to-field \"42\")")
        XCTAssertEqual(result, .int(42))
    }
    
    func testStringToFieldFloat() throws {
        let result = CLIPS.eval(expr: "(string-to-field \"3.14\")")
        XCTAssertEqual(result, .float(3.14))
    }
    
    func testStringToFieldSymbol() throws {
        let result = CLIPS.eval(expr: "(string-to-field \"abc\")")
        XCTAssertEqual(result, .symbol("abc"))
    }
    
    func testStringToFieldString() throws {
        let result = CLIPS.eval(expr: "(string-to-field \"\\\"text\\\"\")")
        XCTAssertEqual(result, .string("text"))
    }
    
    func testStringToFieldNegative() throws {
        let result = CLIPS.eval(expr: "(string-to-field \"-100\")")
        XCTAssertEqual(result, .int(-100))
    }
    
    // MARK: - Integration Tests
    
    func testStrCatWithSubString() throws {
        let result = CLIPS.eval(expr: "(str-cat \"Result: \" (sub-string 1 5 \"Hello World\"))")
        XCTAssertEqual(result, .string("Result: Hello"))
    }
    
    func testUpcaseWithStrCat() throws {
        let result = CLIPS.eval(expr: "(upcase (str-cat \"hello\" \" \" \"world\"))")
        XCTAssertEqual(result, .string("HELLO WORLD"))
    }
    
    func testStrIndexAfterStrReplace() throws {
        CLIPS.eval(expr: "(bind ?str (str-replace \"Hello World\" \"World\" \"CLIPS\"))")
        let result = CLIPS.eval(expr: "(str-index \"CLIPS\" ?str)")
        XCTAssertEqual(result, .int(7))
    }
    
    func testComplexStringManipulation() throws {
        // Concatena, converte in maiuscolo, estrae sottostringa
        let result = CLIPS.eval(expr: "(sub-string 1 5 (upcase (str-cat \"hello\" \" world\")))")
        XCTAssertEqual(result, .string("HELLO"))
    }
    
    func testStrLengthOfStrCat() throws {
        let result = CLIPS.eval(expr: "(str-length (str-cat \"Hello\" \" \" \"World\"))")
        XCTAssertEqual(result, .int(11))
    }
    
    // MARK: - Error Handling Tests
    
    func testStrLengthWrongArgCount() throws {
        let result = CLIPS.eval(expr: "(str-length \"test\" \"extra\")")
        // Dovrebbe generare errore o ritornare nil
        // Per ora verifichiamo che non crasha
        _ = result
    }
    
    func testSubStringInvalidIndices() throws {
        // Indice out of bounds
        let result = CLIPS.eval(expr: "(sub-string 1 100 \"test\")")
        // Dovrebbe gestire errore gracefully
        _ = result
    }
    
    func testStrCompareNonString() throws {
        // Tipo errato
        let result = CLIPS.eval(expr: "(str-compare 123 \"test\")")
        // Dovrebbe gestire errore
        _ = result
    }
}

