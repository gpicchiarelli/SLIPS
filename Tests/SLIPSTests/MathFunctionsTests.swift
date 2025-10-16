// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import XCTest
@testable import SLIPS

/// Test suite per funzioni matematiche SLIPS
/// Ref: clips_core_source_642/core/emathfun.c
@MainActor
final class MathFunctionsTests: XCTestCase {
    override func setUp() async throws {
        CLIPS.reset()
        CLIPS.createEnvironment()
    }
    
    // MARK: - Trigonometriche Base
    
    func testCos() throws {
        let result = CLIPS.eval(expr: "(cos 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSin() throws {
        let result = CLIPS.eval(expr: "(sin 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testTan() throws {
        let result = CLIPS.eval(expr: "(tan 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testCosPi() throws {
        let result = CLIPS.eval(expr: "(cos (pi))")
        if case .float(let val) = result {
            XCTAssertEqual(val, -1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSinPiHalf() throws {
        let result = CLIPS.eval(expr: "(sin (/ (pi) 2))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Trigonometriche Inverse
    
    func testAcos() throws {
        let result = CLIPS.eval(expr: "(acos 1)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAsin() throws {
        let result = CLIPS.eval(expr: "(asin 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAtan() throws {
        let result = CLIPS.eval(expr: "(atan 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAtan2() throws {
        let result = CLIPS.eval(expr: "(atan2 1 1)")
        if case .float(let val) = result {
            XCTAssertEqual(val, Double.pi / 4, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Iperboliche
    
    func testCosh() throws {
        let result = CLIPS.eval(expr: "(cosh 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSinh() throws {
        let result = CLIPS.eval(expr: "(sinh 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testTanh() throws {
        let result = CLIPS.eval(expr: "(tanh 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAcosh() throws {
        let result = CLIPS.eval(expr: "(acosh 1)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAsinh() throws {
        let result = CLIPS.eval(expr: "(asinh 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testAtanh() throws {
        let result = CLIPS.eval(expr: "(atanh 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Esponenziali e Logaritmi
    
    func testExp() throws {
        let result = CLIPS.eval(expr: "(exp 0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testExpOne() throws {
        let result = CLIPS.eval(expr: "(exp 1)")
        if case .float(let val) = result {
            XCTAssertEqual(val, Double(M_E), accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testLog() throws {
        let result = CLIPS.eval(expr: "(log (exp 1))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testLog10() throws {
        let result = CLIPS.eval(expr: "(log10 100)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 2.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSqrt() throws {
        let result = CLIPS.eval(expr: "(sqrt 16)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 4.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSqrt2() throws {
        let result = CLIPS.eval(expr: "(sqrt 2)")
        if case .float(let val) = result {
            XCTAssertEqual(val, sqrt(2.0), accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testPow() throws {
        let result = CLIPS.eval(expr: "(** 2 3)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 8.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testPowNegative() throws {
        let result = CLIPS.eval(expr: "(** 2 -1)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 0.5, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testPowFractional() throws {
        let result = CLIPS.eval(expr: "(** 4 0.5)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 2.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Utilità
    
    func testAbsPositive() throws {
        let result = CLIPS.eval(expr: "(abs 42)")
        XCTAssertEqual(result, .int(42))
    }
    
    func testAbsNegative() throws {
        let result = CLIPS.eval(expr: "(abs -42)")
        XCTAssertEqual(result, .int(42))
    }
    
    func testAbsFloat() throws {
        let result = CLIPS.eval(expr: "(abs -3.14)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 3.14, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testModPositive() throws {
        let result = CLIPS.eval(expr: "(mod 10 3)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testModNegative() throws {
        let result = CLIPS.eval(expr: "(mod -10 3)")
        if case .float(let val) = result {
            XCTAssertEqual(val, -1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testModFloat() throws {
        let result = CLIPS.eval(expr: "(mod 5.5 2.0)")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.5, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testRoundUp() throws {
        let result = CLIPS.eval(expr: "(round 3.7)")
        XCTAssertEqual(result, .int(4))
    }
    
    func testRoundDown() throws {
        let result = CLIPS.eval(expr: "(round 3.2)")
        XCTAssertEqual(result, .int(3))
    }
    
    func testRoundHalfPositive() throws {
        // CLIPS 6.40+: arrotonda lontano da zero
        let result = CLIPS.eval(expr: "(round 3.5)")
        XCTAssertEqual(result, .int(4))
    }
    
    func testRoundHalfNegative() throws {
        // CLIPS 6.40+: arrotonda lontano da zero
        let result = CLIPS.eval(expr: "(round -3.5)")
        XCTAssertEqual(result, .int(-4))
    }
    
    func testPi() throws {
        let result = CLIPS.eval(expr: "(pi)")
        if case .float(let val) = result {
            XCTAssertEqual(val, Double.pi, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Conversioni Angoli
    
    func testDegRad() throws {
        let result = CLIPS.eval(expr: "(deg-rad 180)")
        if case .float(let val) = result {
            XCTAssertEqual(val, Double.pi, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testDegRad90() throws {
        let result = CLIPS.eval(expr: "(deg-rad 90)")
        if case .float(let val) = result {
            XCTAssertEqual(val, Double.pi / 2, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testRadDeg() throws {
        let result = CLIPS.eval(expr: "(rad-deg (pi))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 180.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testRadDegPiHalf() throws {
        let result = CLIPS.eval(expr: "(rad-deg (/ (pi) 2))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 90.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Integration Tests
    
    func testPythagorean() throws {
        // sqrt(3^2 + 4^2) = 5
        let result = CLIPS.eval(expr: "(sqrt (+ (** 3 2) (** 4 2)))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 5.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testCircleArea() throws {
        // Area cerchio: π * r^2
        let result = CLIPS.eval(expr: "(* (pi) (** 2 2))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 4 * Double.pi, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testLogExpInverse() throws {
        // log(exp(x)) = x
        let result = CLIPS.eval(expr: "(log (exp 5))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 5.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testSinCosIdentity() throws {
        // sin^2(x) + cos^2(x) = 1
        let result = CLIPS.eval(expr: "(+ (** (sin 1) 2) (** (cos 1) 2))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 1.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    func testDegRadRoundtrip() throws {
        // rad-deg(deg-rad(x)) = x
        let result = CLIPS.eval(expr: "(rad-deg (deg-rad 45))")
        if case .float(let val) = result {
            XCTAssertEqual(val, 45.0, accuracy: 1e-10)
        } else {
            XCTFail("Expected float")
        }
    }
    
    // MARK: - Domain Error Tests
    
    func testAcosDomainError() throws {
        // acos richiede [-1, 1]
        let result = CLIPS.eval(expr: "(acos 2)")
        // Dovrebbe generare errore o gestirlo gracefully
        _ = result
    }
    
    func testLogDomainError() throws {
        // log richiede > 0
        let result = CLIPS.eval(expr: "(log -1)")
        _ = result
    }
    
    func testSqrtDomainError() throws {
        // sqrt richiede >= 0
        let result = CLIPS.eval(expr: "(sqrt -1)")
        _ = result
    }
    
    func testModDivisionByZero() throws {
        let result = CLIPS.eval(expr: "(mod 10 0)")
        _ = result
    }
}

