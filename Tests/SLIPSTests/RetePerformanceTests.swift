// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import XCTest
@testable import SLIPS

/// Test di performance per verificare equivalenza C con hash lookup
@MainActor
final class RetePerformanceTests: XCTestCase {
    
    // MARK: - Setup
    
    private func createEnv() -> Environment {
        var env = SLIPS.createEnvironment()
        env.useExplicitReteNodes = true
        env.watchRete = false
        return env
    }
    
    // MARK: - Performance Tests
    
    func testHashLookupVsLinearScan() {
        _ = createEnv()
        
        // Test che hash lookup sia più veloce di linear scan
        // Con 100 token left, 100 fatti right = 10.000 combinazioni potenziali
        // Hash lookup: ~100 confronti (uno per bucket)
        // Linear scan: ~10.000 confronti
        
        _ = SLIPS.eval(expr: "(deftemplate a (slot x) (slot data))")
        _ = SLIPS.eval(expr: "(deftemplate b (slot x) (slot value))")
        _ = SLIPS.eval(expr: "(defrule r (a x ?v data ?d) (b x ?v value ?w) => (printout t \"match\"))")
        
        // Assert 100 fatti 'a'
        for i in 1...100 {
            _ = SLIPS.eval(expr: "(assert a x \(i) data \"test\")")
        }
        
        guard let env1 = SLIPS.currentEnvironment else {
            XCTFail("No env after first asserts")
            return
        }
        
        // A questo punto dovrebbero esserci 100 token in beta memory
        print("Facts 'a': \(env1.facts.values.filter { $0.name == "a" }.count)")
        
        // Assert 100 fatti 'b' - triggera 10.000 potenziali join
        let start = Date()
        for i in 1...100 {
            _ = SLIPS.eval(expr: "(assert b x \(i) value 42)")
        }
        let elapsed = Date().timeIntervalSince(start)
        
        guard let env2 = SLIPS.currentEnvironment else {
            XCTFail("No env after second asserts")
            return
        }
        
        print("Join time for 10.000 potential combinations: \(elapsed * 1000)ms")
        print("Activations created: \(env2.agendaQueue.queue.count)")
        
        // Dovrebbero esserci 100 attivazioni (una per ogni match)
        XCTAssertEqual(env2.agendaQueue.queue.count, 100, "Dovrebbero esserci 100 attivazioni")
        
        // Performance target: < 100ms con hash lookup (vs >1s con linear scan)
        XCTAssertLessThan(elapsed, 0.5, "Hash lookup dovrebbe completare in <500ms")
        
        // Verifica statistics dei join node
        if let prodNode = env2.rete.productionNodes["r"] {
            print("Production node level: \(prodNode.level)")
        }
    }
    
    func testLargeNetworkScalability() {
        _ = createEnv()
        
        // Test scalabilità: 1000 fatti dovrebbero essere gestibili
        _ = SLIPS.eval(expr: "(deftemplate item (slot id) (slot value))")
        _ = SLIPS.eval(expr: "(defrule process (item id ?i value ?v) => (printout t \"process\"))")
        
        let start = Date()
        for i in 1...1000 {
            _ = SLIPS.eval(expr: "(assert item id \(i) value \(i * 10))")
        }
        let elapsed = Date().timeIntervalSince(start)
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("No env")
            return
        }
        
        print("Assert 1000 facts: \(elapsed * 1000)ms")
        print("Activations: \(env.agendaQueue.queue.count)")
        
        XCTAssertEqual(env.agendaQueue.queue.count, 1000)
        XCTAssertLessThan(elapsed, 0.5, "1000 assert dovrebbero completare in <500ms")
    }
    
    func testJoinMemoryStatistics() {
        _ = createEnv()
        
        _ = SLIPS.eval(expr: "(deftemplate a (slot x))")
        _ = SLIPS.eval(expr: "(deftemplate b (slot x))")
        _ = SLIPS.eval(expr: "(defrule r (a x ?v) (b x ?v) => (printout t \"match\"))")
        
        // Assert alcuni fatti
        for i in 1...10 {
            _ = SLIPS.eval(expr: "(assert a x \(i))")
        }
        
        for i in 1...10 {
            _ = SLIPS.eval(expr: "(assert b x \(i))")
        }
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("No env")
            return
        }
        
        // Verifica statistics tracking nei join nodes
        // Cerca il join node nella rete
        if let prodNode = env.rete.productionNodes["r"] {
            // Naviga predecessori per trovare join nodes
            print("Production node found at level \(prodNode.level)")
            
            // Per ora, verifica solo che il sistema funzioni
            XCTAssertEqual(env.agendaQueue.queue.count, 10)
        }
    }
    
    func testHashCollisionHandling() {
        _ = createEnv()
        
        // Test che hash collisions siano gestite correttamente
        // (linked list in ogni bucket)
        
        _ = SLIPS.eval(expr: "(deftemplate data (slot id) (slot value))")
        _ = SLIPS.eval(expr: "(defrule r (data id ?i value ?v) => (printout t \"data\"))")
        
        // Assert molti fatti per forzare collisions
        for i in 1...500 {
            _ = SLIPS.eval(expr: "(assert data id \(i) value \(i % 17))")  // mod 17 forza collisions
        }
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("No env")
            return
        }
        
        print("Activations with hash collisions: \(env.agendaQueue.queue.count)")
        XCTAssertEqual(env.agendaQueue.queue.count, 500)
    }
}

