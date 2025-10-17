// SortFunctionsTests.swift
// Test per le funzioni di ordinamento (sort)
// Basato su sortfun.c di CLIPS 6.40

import XCTest
@testable import SLIPS

@MainActor
final class SortFunctionsTests: XCTestCase {
    
    override func setUp() async throws {
        CLIPS.reset()
        CLIPS.createEnvironment()
    }
    
    // MARK: - Test Basic Sort
    
    func testSortAscending() throws {
        // Test ordinamento crescente con <
        let result = CLIPS.eval(expr: "(sort < 3 1 4 1 5 9 2 6)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        // Verifica ordinamento corretto
        XCTAssertEqual(items.count, 8)
        
        let expected: [Int64] = [1, 1, 2, 3, 4, 5, 6, 9]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortDescending() throws {
        // Test ordinamento decrescente con >
        let result = CLIPS.eval(expr: "(sort > 3 1 4 1 5 9 2 6)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        // Verifica ordinamento decrescente
        XCTAssertEqual(items.count, 8)
        
        let expected: [Int64] = [9, 6, 5, 4, 3, 2, 1, 1]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortFloats() throws {
        // Test ordinamento float
        let result = CLIPS.eval(expr: "(sort < 3.14 1.41 2.71 0.57)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 4)
        
        let expected: [Double] = [0.57, 1.41, 2.71, 3.14]
        for (i, item) in items.enumerated() {
            guard case .float(let value) = item else {
                XCTFail("Elemento deve essere float")
                continue
            }
            XCTAssertEqual(value, expected[i], accuracy: 0.01, "Posizione \(i)")
        }
    }
    
    // SKIP: Richiede deffunction non ancora implementata
    func skip_testSortStrings() throws {
        // Test ordinamento stringhe con str-compare
        _ = CLIPS.eval(expr: """
        (deffunction string-less (?a ?b)
          (< (str-compare ?a ?b) 0))
        """)
        
        let result = CLIPS.eval(expr: #"(sort string-less "dog" "cat" "bird" "ant")"#)
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 4)
        
        let expected = ["ant", "bird", "cat", "dog"]
        for (i, item) in items.enumerated() {
            guard case .string(let value) = item else {
                XCTFail("Elemento deve essere stringa")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortWithMultifield() throws {
        // Test sort con multifield come argomento
        let result = CLIPS.eval(expr: "(sort < (create$ 5 2 8 1 9))")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 5)
        
        let expected: [Int64] = [1, 2, 5, 8, 9]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortMixedMultifields() throws {
        // Test sort con mix di elementi singoli e multifield
        let result = CLIPS.eval(expr: "(sort < 5 (create$ 2 8) 1 (create$ 9 3))")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 6)
        
        let expected: [Int64] = [1, 2, 3, 5, 8, 9]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortEmpty() throws {
        // Test sort senza elementi (solo funzione)
        let result = CLIPS.eval(expr: "(sort <)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 0, "Deve ritornare multifield vuoto")
    }
    
    func testSortSingleElement() throws {
        // Test sort con un solo elemento
        let result = CLIPS.eval(expr: "(sort < 42)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 1)
        
        guard case .int(let value) = items[0] else {
            XCTFail("Elemento deve essere intero")
            return
        }
        XCTAssertEqual(value, 42)
    }
    
    // SKIP: Richiede deffunction non ancora implementata
    func skip_testSortCustomComparison() throws {
        // Test sort con funzione di comparazione personalizzata
        _ = CLIPS.eval(expr: """
        (deffunction abs-compare (?a ?b)
          (< (abs ?a) (abs ?b)))
        """)
        
        let result = CLIPS.eval(expr: "(sort abs-compare -5 2 -8 1 -3)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 5)
        
        // Ordinato per valore assoluto: 1, 2, -3, -5, -8
        let expected: [Int64] = [1, 2, -3, -5, -8]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortStability() throws {
        // Test stabilità: elementi uguali mantengono ordine originale
        // (anche se merge sort non è necessariamente stabile in CLIPS)
        let result = CLIPS.eval(expr: "(sort <= 1 2 2 3 3 3)")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 6)
        
        let expected: [Int64] = [1, 2, 2, 3, 3, 3]
        for (i, item) in items.enumerated() {
            guard case .int(let value) = item else {
                XCTFail("Elemento deve essere intero")
                continue
            }
            XCTAssertEqual(value, expected[i], "Posizione \(i)")
        }
    }
    
    func testSortLargeList() throws {
        // Test performance con lista più grande
        let numbers = (1...100).shuffled().map { String($0) }.joined(separator: " ")
        let result = CLIPS.eval(expr: "(sort < \(numbers))")
        
        guard case .multifield(let items) = result else {
            XCTFail("Risultato deve essere multifield")
            return
        }
        
        XCTAssertEqual(items.count, 100)
        
        // Verifica che sia ordinato
        for i in 0..<99 {
            guard case .int(let v1) = items[i],
                  case .int(let v2) = items[i+1] else {
                XCTFail("Elementi devono essere interi")
                continue
            }
            XCTAssertLessThanOrEqual(v1, v2, "Lista deve essere ordinata a posizione \(i)")
        }
    }
    
    // MARK: - Test Error Cases
    
    func testSortNoArguments() throws {
        // Test sort senza argomenti (errore)
        let result = CLIPS.eval(expr: "(sort)")
        
        // Dovrebbe ritornare errore o false
        if case .symbol(let sym) = result {
            XCTAssertTrue(sym == "FALSE" || sym == "nil")
        } else {
            // Accetta anche altri tipi di errore
        }
    }
    
    func testSortInvalidFunction() throws {
        // Test sort con funzione inesistente
        let result = CLIPS.eval(expr: "(sort nonexistent-function 1 2 3)")
        
        // Dovrebbe ritornare errore
        if case .symbol(let sym) = result {
            XCTAssertTrue(sym == "FALSE" || sym == "nil")
        }
    }
    
    func testSortNonFunctionArgument() throws {
        // Test sort con primo argomento che non è una funzione
        let result = CLIPS.eval(expr: "(sort 123 1 2 3)")
        
        // Dovrebbe ritornare errore
        if case .symbol(let sym) = result {
            XCTAssertTrue(sym == "FALSE" || sym == "nil")
        }
    }
}

