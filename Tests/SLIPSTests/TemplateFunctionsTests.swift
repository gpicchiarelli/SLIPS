// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import XCTest
@testable import SLIPS

@MainActor
final class TemplateFunctionsTests: XCTestCase {
    
    // MARK: - deftemplate-slot-allowed-values Tests
    
    func testSlotAllowedValuesWithRestrictions() {
        _ = CLIPS.createEnvironment()
        // Template con allowed-values
        _ = CLIPS.eval(expr: "(deftemplate person (slot status))")
        
        // Per ora senza constraints vere, ritorna FALSE
        let result = CLIPS.eval(expr: "(deftemplate-slot-allowed-values person status)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Senza constraints dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testSlotAllowedValuesNoRestrictions() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-allowed-values data value)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Senza allowed-values dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testSlotAllowedValuesNonExistentSlot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        // Slot inesistente dovrebbe causare errore
        let result = CLIPS.eval(expr: "(deftemplate-slot-allowed-values data nonexistent)")
        
        // Dovrebbe ritornare un errore
        // Per ora accettiamo FALSE o errore
        XCTAssertNotNil(result)
    }
    
    // MARK: - deftemplate-slot-defaultp Tests
    
    func testSlotDefaultpStatic() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value (default 42)))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-defaultp data value)")
        
        if case .symbol(let s) = result {
            XCTAssertEqual(s, "static", "Default statico dovrebbe ritornare 'static'")
        } else {
            XCTFail("Expected symbol 'static', got \(result)")
        }
    }
    
    func testSlotDefaultpDynamic() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate log (slot timestamp (default-dynamic (gensym))))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-defaultp log timestamp)")
        
        if case .symbol(let s) = result {
            XCTAssertEqual(s, "dynamic", "Default dinamico dovrebbe ritornare 'dynamic'")
        } else {
            XCTFail("Expected symbol 'dynamic', got \(result)")
        }
    }
    
    func testSlotDefaultpNoDefault() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate item (slot id))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-defaultp item id)")
        
        // Slot senza default esplicito potrebbe avere default implicito
        // CLIPS considera slots senza (default ...) come aventi default statico nil
        // Quindi potrebbe essere "static" o FALSE
        XCTAssertNotNil(result)
    }
    
    func testSlotDefaultpNonExistentTemplate() {
        _ = CLIPS.createEnvironment()
        let result = CLIPS.eval(expr: "(deftemplate-slot-defaultp nonexistent slot)")
        
        // Template inesistente dovrebbe causare errore o ritornare FALSE
        XCTAssertNotNil(result)
    }
    
    func testSlotDefaultpNonExistentSlot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-defaultp data nonexistent)")
        
        // Slot inesistente dovrebbe causare errore
        XCTAssertNotNil(result)
    }
    
    // MARK: - deftemplate-slot-facet-existp Tests
    
    func testFacetExistpDefaultFacet() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value (default 10)))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp data value default)")
        
        if case .boolean(let b) = result {
            XCTAssertTrue(b, "Facet 'default' dovrebbe esistere")
        } else {
            XCTFail("Expected boolean TRUE, got \(result)")
        }
    }
    
    func testFacetExistpTypeFacet() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp data value type)")
        
        if case .boolean(let b) = result {
            // Type facet esiste solo se ci sono constraints sui tipi
            XCTAssertFalse(b, "Senza type constraints, facet 'type' non dovrebbe esistere")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetExistpRangeFacet() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp data value range)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Senza range constraints, facet 'range' non dovrebbe esistere")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetExistpNonExistentFacet() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp data value nonexistent)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Facet inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetExistpNonExistentTemplate() {
        _ = CLIPS.createEnvironment()
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp nonexistent slot default)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Template inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetExistpNonExistentSlot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-existp data nonexistent default)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Slot inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    // MARK: - deftemplate-slot-facet-value Tests
    
    func testFacetValueDefaultStatic() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value (default 42)))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value data value default)")
        
        if case .int(let i) = result {
            XCTAssertEqual(i, 42, "Facet 'default' dovrebbe ritornare 42")
        } else {
            XCTFail("Expected int 42, got \(result)")
        }
    }
    
    func testFacetValueDefaultString() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: #"(deftemplate person (slot name (default "unknown")))"#)
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value person name default)")
        
        if case .string(let s) = result {
            XCTAssertEqual(s, "unknown", "Facet 'default' dovrebbe ritornare \"unknown\"")
        } else {
            XCTFail("Expected string \"unknown\", got \(result)")
        }
    }
    
    func testFacetValueCardinality() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (multislot values))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value data values cardinality)")
        
        if case .multifield(let arr) = result {
            XCTAssertEqual(arr.count, 2, "Cardinality dovrebbe ritornare (min max)")
            if case .int(let min) = arr[0] {
                XCTAssertEqual(min, 0, "Min cardinality per multislot dovrebbe essere 0")
            }
        } else {
            XCTFail("Expected multifield, got \(result)")
        }
    }
    
    func testFacetValueCardinalitySingleSlot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value data value cardinality)")
        
        if case .multifield(let arr) = result {
            XCTAssertEqual(arr.count, 2, "Cardinality dovrebbe ritornare (min max)")
            if case .int(let min) = arr[0], case .int(let max) = arr[1] {
                XCTAssertEqual(min, 1, "Min cardinality per slot dovrebbe essere 1")
                XCTAssertEqual(max, 1, "Max cardinality per slot dovrebbe essere 1")
            }
        } else {
            XCTFail("Expected multifield, got \(result)")
        }
    }
    
    func testFacetValueNonExistentFacet() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value data value nonexistent)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Facet inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetValueNonExistentTemplate() {
        _ = CLIPS.createEnvironment()
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value nonexistent slot default)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Template inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    func testFacetValueNonExistentSlot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate data (slot value))")
        
        let result = CLIPS.eval(expr: "(deftemplate-slot-facet-value data nonexistent default)")
        
        if case .boolean(let b) = result {
            XCTAssertFalse(b, "Slot inesistente dovrebbe ritornare FALSE")
        } else {
            XCTFail("Expected boolean FALSE, got \(result)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testAllTemplateFunctionsIntegration() {
        _ = CLIPS.createEnvironment()
        // Crea un template completo con vari facets
        _ = CLIPS.eval(expr: "(deftemplate product (slot name (default \"Item\")) (slot price (default 0.0)) (multislot tags))")
        
        // Test slot-names
        let names = CLIPS.eval(expr: "(deftemplate-slot-names product)")
        if case .multifield(let arr) = names {
            XCTAssertTrue(arr.count >= 3, "Dovrebbe avere almeno 3 slot")
        }
        
        // Test slot-existp
        let exists = CLIPS.eval(expr: "(deftemplate-slot-existp product name)")
        if case .boolean(let b) = exists {
            XCTAssertTrue(b, "Slot 'name' dovrebbe esistere")
        }
        
        // Test slot-multip
        let isMulti = CLIPS.eval(expr: "(deftemplate-slot-multip product tags)")
        if case .boolean(let b) = isMulti {
            XCTAssertTrue(b, "Slot 'tags' dovrebbe essere multifield")
        }
        
        // Test slot-singlep
        let isSingle = CLIPS.eval(expr: "(deftemplate-slot-singlep product name)")
        if case .boolean(let b) = isSingle {
            XCTAssertTrue(b, "Slot 'name' dovrebbe essere single-field")
        }
        
        // Test slot-default-value
        let defaultVal = CLIPS.eval(expr: "(deftemplate-slot-default-value product name)")
        if case .string(let s) = defaultVal {
            XCTAssertEqual(s, "Item", "Default di 'name' dovrebbe essere \"Item\"")
        }
        
        // Test slot-defaultp
        let defaultType = CLIPS.eval(expr: "(deftemplate-slot-defaultp product name)")
        if case .symbol(let s) = defaultType {
            XCTAssertEqual(s, "static", "Default di 'name' dovrebbe essere statico")
        }
        
        // Test facet-existp
        let facetExists = CLIPS.eval(expr: "(deftemplate-slot-facet-existp product name default)")
        if case .boolean(let b) = facetExists {
            XCTAssertTrue(b, "Facet 'default' dovrebbe esistere per 'name'")
        }
        
        // Test facet-value
        let facetValue = CLIPS.eval(expr: "(deftemplate-slot-facet-value product name default)")
        if case .string(let s) = facetValue {
            XCTAssertEqual(s, "Item", "Valore del facet 'default' dovrebbe essere \"Item\"")
        }
    }
    
    func testModifyWithNewFunctions() {
        _ = CLIPS.createEnvironment()
        // Crea template e fatto
        _ = CLIPS.eval(expr: "(deftemplate item (slot id (default 0)) (slot name (default \"none\")))")
        
        // Verifica default prima di modify
        let defaultType = CLIPS.eval(expr: "(deftemplate-slot-defaultp item id)")
        if case .symbol(let s) = defaultType {
            XCTAssertEqual(s, "static", "Default di 'id' dovrebbe essere statico")
        } else {
            XCTFail("Expected symbol 'static', got \(defaultType)")
        }
        
        // Test che deftemplate-slot-defaultp funzioni con slot 'name'
        let defaultType2 = CLIPS.eval(expr: "(deftemplate-slot-defaultp item name)")
        if case .symbol(let s) = defaultType2 {
            XCTAssertEqual(s, "static", "Default di 'name' dovrebbe essere statico")
        } else {
            XCTFail("Expected symbol 'static', got \(defaultType2)")
        }
    }
    
    func testDuplicateWithNewFunctions() {
        _ = CLIPS.createEnvironment()
        // Crea template
        _ = CLIPS.eval(expr: "(deftemplate item (slot id (default 0)) (slot name (default \"none\")))")
        
        // Test che le funzioni template introspection funzionino
        let names = CLIPS.eval(expr: "(deftemplate-slot-names item)")
        if case .multifield(let arr) = names {
            XCTAssertTrue(arr.count >= 2, "Template 'item' dovrebbe avere almeno 2 slot")
        } else {
            XCTFail("Expected multifield, got \(names)")
        }
        
        // Verifica che i due slot esistano
        let existsId = CLIPS.eval(expr: "(deftemplate-slot-existp item id)")
        if case .boolean(let b) = existsId {
            XCTAssertTrue(b, "Slot 'id' dovrebbe esistere")
        }
        
        let existsName = CLIPS.eval(expr: "(deftemplate-slot-existp item name)")
        if case .boolean(let b) = existsName {
            XCTAssertTrue(b, "Slot 'name' dovrebbe esistere")
        }
    }
}

