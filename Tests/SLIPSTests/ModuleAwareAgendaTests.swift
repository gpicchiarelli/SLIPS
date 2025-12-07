// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details
//
// File: ModuleAwareAgendaTests.swift
// Test suite per module-aware agenda (FASE 3 completa)

import XCTest
@testable import SLIPS

@MainActor
final class ModuleAwareAgendaTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        _ = SLIPS.createEnvironment()
    }
    
    // MARK: - Module Assignment Tests
    
    func testRuleGetsModuleName() {
        // Crea un modulo e una regola in quel modulo
        _ = SLIPS.eval(expr: "(defmodule TEST)")
        _ = SLIPS.eval(expr: "(deftemplate item (slot x))")
        _ = SLIPS.eval(expr: "(defrule test-rule (item (x ?v)) => (printout t \"fired\" crlf))")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Verifica che la regola abbia il nome del modulo
        if let rule = env.rules.first(where: { $0.name == "test-rule" }) {
            XCTAssertEqual(rule.moduleName, "TEST", "La regola dovrebbe appartenere al modulo TEST")
        } else {
            XCTFail("Regola non trovata")
        }
    }
    
    func testActivationGetsModuleName() {
        _ = SLIPS.eval(expr: "(defmodule MYMODULE)")
        _ = SLIPS.eval(expr: "(deftemplate data (slot value))")
        _ = SLIPS.eval(expr: "(defrule my-rule (data (value ?v)) => (printout t ?v crlf))")
        
        _ = SLIPS.eval(expr: "(assert (data (value 42)))")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Verifica che l'attivazione abbia il nome del modulo
        if let activation = env.agendaQueue.queue.first {
            XCTAssertEqual(activation.moduleName, "MYMODULE", "L'attivazione dovrebbe appartenere a MYMODULE")
        } else {
            XCTFail("Nessuna attivazione trovata")
        }
    }
    
    // MARK: - Agenda Filtering Tests
    
    func testFilterAgendaByModule() {
        _ = SLIPS.eval(expr: "(defmodule MODULE-A)")
        _ = SLIPS.eval(expr: "(deftemplate a (slot x))")
        _ = SLIPS.eval(expr: "(defrule rule-a (a (x ?v)) => (printout t \"A\" crlf))")
        
        _ = SLIPS.eval(expr: "(defmodule MODULE-B)")
        _ = SLIPS.eval(expr: "(deftemplate b (slot y))")
        _ = SLIPS.eval(expr: "(defrule rule-b (b (y ?v)) => (printout t \"B\" crlf))")
        
        // Torna a MODULE-A e aggiungi fatti
        _ = SLIPS.eval(expr: "(set-current-module MODULE-A)")
        _ = SLIPS.eval(expr: "(assert (a (x 1)))")
        
        _ = SLIPS.eval(expr: "(set-current-module MODULE-B)")
        _ = SLIPS.eval(expr: "(assert (b (y 2)))")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Filtra per MODULE-A
        let activationsA = env.agendaQueue.filterByModule("MODULE-A")
        XCTAssertEqual(activationsA.count, 1, "Dovrebbe esserci 1 attivazione per MODULE-A")
        XCTAssertEqual(activationsA.first?.ruleName, "rule-a")
        
        // Filtra per MODULE-B
        let activationsB = env.agendaQueue.filterByModule("MODULE-B")
        XCTAssertEqual(activationsB.count, 1, "Dovrebbe esserci 1 attivazione per MODULE-B")
        XCTAssertEqual(activationsB.first?.ruleName, "rule-b")
    }
    
    // MARK: - Focus Stack Sorting Tests
    
    func testFocusStackSorting() {
        _ = SLIPS.eval(expr: "(defmodule MOD-X)")
        _ = SLIPS.eval(expr: "(deftemplate x (slot v))")
        _ = SLIPS.eval(expr: "(defrule x-rule (declare (salience 10)) (x (v ?v)) => (printout t \"X\" crlf))")
        
        _ = SLIPS.eval(expr: "(defmodule MOD-Y)")
        _ = SLIPS.eval(expr: "(deftemplate y (slot v))")
        _ = SLIPS.eval(expr: "(defrule y-rule (declare (salience 20)) (y (v ?v)) => (printout t \"Y\" crlf))")
        
        // Assert fatti in entrambi
        _ = SLIPS.eval(expr: "(set-current-module MOD-X)")
        _ = SLIPS.eval(expr: "(assert (x (v 1)))")
        
        _ = SLIPS.eval(expr: "(set-current-module MOD-Y)")
        _ = SLIPS.eval(expr: "(assert (y (v 2)))")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Senza focus: ordine normale (salience higher first)
        let normalOrder = env.agendaQueue.queue
        XCTAssertEqual(normalOrder.count, 2)
        // salience 20 (y-rule) prima di salience 10 (x-rule)
        XCTAssertEqual(normalOrder[0].ruleName, "y-rule")
        XCTAssertEqual(normalOrder[1].ruleName, "x-rule")
        
        // Con focus MOD-X in cima: x-rule ha priorità assoluta
        let focusStack = ["MOD-X", "MOD-Y"]
        let focusOrder = env.agendaQueue.sortedByFocusStack(focusStack)
        XCTAssertEqual(focusOrder.count, 2)
        // MOD-X ha priorità assoluta, quindi x-rule prima anche con salience minore
        XCTAssertEqual(focusOrder[0].ruleName, "x-rule", "MOD-X in focus dovrebbe avere priorità")
        XCTAssertEqual(focusOrder[1].ruleName, "y-rule")
    }
    
    func testFocusCommandChangesPriority() {
        _ = SLIPS.eval(expr: "(defmodule MAIN)")
        _ = SLIPS.eval(expr: "(deftemplate main-data (slot x))")
        _ = SLIPS.eval(expr: "(defrule main-rule (main-data (x ?v)) => (printout t \"MAIN\" crlf))")
        
        _ = SLIPS.eval(expr: "(defmodule UTIL)")
        _ = SLIPS.eval(expr: "(deftemplate util-data (slot y))")
        _ = SLIPS.eval(expr: "(defrule util-rule (util-data (y ?v)) => (printout t \"UTIL\" crlf))")
        
        // Assert in entrambi
        _ = SLIPS.eval(expr: "(set-current-module MAIN)")
        _ = SLIPS.eval(expr: "(assert (main-data (x 1)))")
        
        _ = SLIPS.eval(expr: "(set-current-module UTIL)")
        _ = SLIPS.eval(expr: "(assert (util-data (y 2)))")
        
        // Imposta focus su UTIL
        _ = SLIPS.eval(expr: "(focus UTIL)")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Verifica che focus stack non sia vuoto
        let focusStack = env.getFocusStackNames()
        XCTAssertFalse(focusStack.isEmpty, "Focus stack dovrebbe contenere UTIL")
        XCTAssertEqual(focusStack.first, "UTIL", "UTIL dovrebbe essere in cima al focus stack")
    }
    
    // MARK: - Integration Tests
    
    func testMultiModuleActivationOrder() {
        // Setup 3 moduli con regole di diversa salience
        _ = SLIPS.eval(expr: "(defmodule A)")
        _ = SLIPS.eval(expr: "(deftemplate a-data (slot x))")
        _ = SLIPS.eval(expr: "(defrule a-rule (declare (salience 5)) (a-data (x ?v)) => (printout t \"A\" crlf))")
        
        _ = SLIPS.eval(expr: "(defmodule B)")
        _ = SLIPS.eval(expr: "(deftemplate b-data (slot x))")
        _ = SLIPS.eval(expr: "(defrule b-rule (declare (salience 10)) (b-data (x ?v)) => (printout t \"B\" crlf))")
        
        _ = SLIPS.eval(expr: "(defmodule C)")
        _ = SLIPS.eval(expr: "(deftemplate c-data (slot x))")
        _ = SLIPS.eval(expr: "(defrule c-rule (declare (salience 15)) (c-data (x ?v)) => (printout t \"C\" crlf))")
        
        // Assert fatti
        _ = SLIPS.eval(expr: "(set-current-module A)")
        _ = SLIPS.eval(expr: "(assert (a-data (x 1)))")
        
        _ = SLIPS.eval(expr: "(set-current-module B)")
        _ = SLIPS.eval(expr: "(assert (b-data (x 2)))")
        
        _ = SLIPS.eval(expr: "(set-current-module C)")
        _ = SLIPS.eval(expr: "(assert (c-data (x 3)))")
        
        guard let env = SLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Senza focus: ordine per salience (C=15, B=10, A=5)
        XCTAssertEqual(env.agendaQueue.queue.count, 3)
        
        // Con focus A, B: A ha priorità massima, poi B, poi C
        let focusStack = ["A", "B"]
        let sorted = env.agendaQueue.sortedByFocusStack(focusStack)
        XCTAssertEqual(sorted[0].moduleName, "A", "A in focus dovrebbe essere prima")
        XCTAssertEqual(sorted[1].moduleName, "B", "B in focus dovrebbe essere seconda")
        XCTAssertEqual(sorted[2].moduleName, "C", "C fuori focus dovrebbe essere terza")
    }
}

