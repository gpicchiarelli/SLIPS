import XCTest
@testable import SLIPS

@MainActor
final class ModulesTests: XCTestCase {
    
    override func setUp() async throws {
        _ = CLIPS.createEnvironment()
    }
    
    // MARK: - Basic Module Creation and Management
    
    func testMainModuleCreatedByDefault() {
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Verifica che il modulo MAIN sia creato di default
        let mainModule = env.findDefmodule(name: "MAIN")
        XCTAssertNotNil(mainModule, "Modulo MAIN dovrebbe essere creato di default")
        XCTAssertEqual(mainModule?.name, "MAIN")
    }
    
    func testGetCurrentModule() {
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Il modulo corrente di default dovrebbe essere MAIN
        let currentModule = env.getCurrentModule()
        XCTAssertNotNil(currentModule)
        XCTAssertEqual(currentModule?.name, "MAIN")
    }
    
    func testCreateNewModule() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea un nuovo modulo
        let myModule = env.createDefmodule(name: "MY-MODULE")
        XCTAssertNotNil(myModule)
        XCTAssertEqual(myModule?.name, "MY-MODULE")
        
        // Verifica che sia stato aggiunto alla lista
        let found = env.findDefmodule(name: "MY-MODULE")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "MY-MODULE")
    }
    
    func testCannotCreateDuplicateModule() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea modulo
        let first = env.createDefmodule(name: "TEST-MODULE")
        XCTAssertNotNil(first)
        
        // Tentativo di creare lo stesso modulo dovrebbe fallire
        let duplicate = env.createDefmodule(name: "TEST-MODULE")
        XCTAssertNil(duplicate, "Non dovrebbe essere possibile creare moduli duplicati")
    }
    
    func testSetCurrentModule() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea nuovo modulo
        let myModule = env.createDefmodule(name: "MY-MODULE")
        XCTAssertNotNil(myModule)
        
        // Cambia modulo corrente
        let previousModule = env.setCurrentModule(myModule)
        XCTAssertEqual(previousModule?.name, "MAIN")
        
        // Verifica che il modulo corrente sia cambiato
        let currentModule = env.getCurrentModule()
        XCTAssertEqual(currentModule?.name, "MY-MODULE")
    }
    
    func testListDefmodules() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Lista dovrebbe contenere solo MAIN inizialmente
        var modules = env.listDefmodules()
        XCTAssertEqual(modules.count, 1)
        XCTAssertTrue(modules.contains("MAIN"))
        
        // Crea alcuni moduli
        _ = env.createDefmodule(name: "MODULE-A")
        _ = env.createDefmodule(name: "MODULE-B")
        
        // Lista dovrebbe contenere tutti i moduli
        modules = env.listDefmodules()
        XCTAssertEqual(modules.count, 3)
        XCTAssertTrue(modules.contains("MAIN"))
        XCTAssertTrue(modules.contains("MODULE-A"))
        XCTAssertTrue(modules.contains("MODULE-B"))
    }
    
    // MARK: - Focus Stack Tests
    
    func testFocusStackInitiallyEmpty() {
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Lo stack di focus dovrebbe essere vuoto inizialmente
        XCTAssertTrue(env.isFocusStackEmpty())
    }
    
    func testFocusPushAndPop() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea modulo
        guard let myModule = env.createDefmodule(name: "MY-MODULE") else {
            XCTFail("Impossibile creare modulo")
            return
        }
        
        // Push nello stack
        env.focusPush(module: myModule)
        XCTAssertFalse(env.isFocusStackEmpty())
        
        // Peek dovrebbe restituire il modulo pushato
        let topModule = env.focusPeek()
        XCTAssertEqual(topModule?.name, "MY-MODULE")
        
        // Pop dovrebbe rimuovere e restituire il modulo
        let poppedModule = env.focusPop()
        XCTAssertEqual(poppedModule?.name, "MY-MODULE")
        XCTAssertTrue(env.isFocusStackEmpty())
    }
    
    func testFocusStackMultiplePushes() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea moduli
        guard let moduleA = env.createDefmodule(name: "MODULE-A") else {
            XCTFail("Impossibile creare modulo A")
            return
        }
        guard let moduleB = env.createDefmodule(name: "MODULE-B") else {
            XCTFail("Impossibile creare modulo B")
            return
        }
        
        // Push moduli in ordine
        env.focusPush(module: moduleA)
        env.focusPush(module: moduleB)
        
        // Peek dovrebbe restituire l'ultimo pushato (LIFO)
        XCTAssertEqual(env.focusPeek()?.name, "MODULE-B")
        
        // Pop in ordine inverso
        XCTAssertEqual(env.focusPop()?.name, "MODULE-B")
        XCTAssertEqual(env.focusPop()?.name, "MODULE-A")
        XCTAssertTrue(env.isFocusStackEmpty())
    }
    
    func testGetCurrentFocusModule() {
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Senza focus stack, dovrebbe restituire currentModule
        let defaultFocus = env.getCurrentFocusModule()
        XCTAssertEqual(defaultFocus?.name, "MAIN")
        
        // Con focus stack, dovrebbe restituire il top dello stack
        guard let myModule = env.createDefmodule(name: "MY-MODULE") else {
            XCTFail("Impossibile creare modulo")
            return
        }
        env.focusPush(module: myModule)
        
        let currentFocus = env.getCurrentFocusModule()
        XCTAssertEqual(currentFocus?.name, "MY-MODULE")
    }
    
    // MARK: - Module Item Registration Tests
    
    func testModuleItemsRegistered() {
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Verifica che i tipi di base siano registrati
        XCTAssertGreaterThan(env.numberOfModuleItems, 0, "Dovrebbero esserci tipi di item registrati")
        
        // I tipi base dovrebbero essere defrule, deftemplate, deffacts
        // (verificare indirettamente attraverso itemsArray del modulo MAIN)
        guard let mainModule = env.findDefmodule(name: "MAIN") else {
            XCTFail("Modulo MAIN non trovato")
            return
        }
        
        XCTAssertGreaterThan(mainModule.itemsArray.count, 0, "MAIN dovrebbe avere item headers allocati")
    }
    
    // MARK: - Integration Tests
    
    func testModuleWithRules() {
        // Test che le regole siano associate al modulo corrente
        // (Per ora è solo un placeholder - sarà implementato dopo il parsing defmodule)
        guard var env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Crea modulo
        guard let myModule = env.createDefmodule(name: "MY-MODULE") else {
            XCTFail("Impossibile creare modulo")
            return
        }
        
        // Cambia modulo corrente
        _ = env.setCurrentModule(myModule)
        
        // Verifica che il modulo corrente sia effettivamente cambiato
        XCTAssertEqual(env.getCurrentModule()?.name, "MY-MODULE")
        
        // TODO: Quando implementeremo il parsing defmodule, testeremo che le regole
        // vengano aggiunte al modulo corrente
    }
    
    // MARK: - Defmodule Parsing Tests
    
    func testDefmoduleParsing() {
        _ = CLIPS.createEnvironment()
        
        // Definisci un nuovo modulo con parsing
        let result = CLIPS.eval(expr: "(defmodule TEST-MODULE)")
        
        // Verifica che il modulo sia stato creato
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        let module = env.findDefmodule(name: "TEST-MODULE")
        XCTAssertNotNil(module)
        XCTAssertEqual(module?.name, "TEST-MODULE")
        
        // Verifica che sia diventato il modulo corrente
        XCTAssertEqual(env.getCurrentModule()?.name, "TEST-MODULE")
        
        // Verifica il valore di ritorno
        if case .symbol(let s) = result {
            XCTAssertEqual(s, "TEST-MODULE")
        } else {
            XCTFail("defmodule dovrebbe ritornare il nome del modulo")
        }
    }
    
    func testDefmoduleWithExport() {
        _ = CLIPS.createEnvironment()
        
        // Definisci modulo con export
        _ = CLIPS.eval(expr: "(defmodule EXPORT-MODULE (export defrule my-rule))")
        
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        let module = env.findDefmodule(name: "EXPORT-MODULE")
        XCTAssertNotNil(module)
        
        // Verifica che export list sia impostata
        XCTAssertNotNil(module?.exportList)
    }
    
    func testDefmoduleWithImport() {
        _ = CLIPS.createEnvironment()
        
        // Crea modulo source
        _ = CLIPS.eval(expr: "(defmodule SOURCE)")
        
        // Crea modulo con import da SOURCE
        _ = CLIPS.eval(expr: "(defmodule IMPORT-MODULE (import SOURCE deftemplate person))")
        
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        let module = env.findDefmodule(name: "IMPORT-MODULE")
        XCTAssertNotNil(module)
        
        // Verifica che import list sia impostata
        XCTAssertNotNil(module?.importList)
    }
    
    // MARK: - Command Tests
    
    func testFocusCommand() {
        _ = CLIPS.createEnvironment()
        
        // Crea modulo
        _ = CLIPS.eval(expr: "(defmodule MOD-A)")
        
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Stack dovrebbe essere vuoto
        XCTAssertTrue(env.isFocusStackEmpty())
        
        // Esegui focus
        let result = CLIPS.eval(expr: "(focus MOD-A)")
        
        // Verifica che sia riuscito
        if case .boolean(let b) = result {
            XCTAssertTrue(b)
        } else {
            XCTFail("focus dovrebbe ritornare TRUE")
        }
        
        // Verifica che lo stack contenga il modulo
        guard let env2 = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        XCTAssertFalse(env2.isFocusStackEmpty())
        XCTAssertEqual(env2.focusPeek()?.name, "MOD-A")
    }
    
    func testFocusMultipleModules() {
        _ = CLIPS.createEnvironment()
        
        // Crea moduli
        _ = CLIPS.eval(expr: "(defmodule MOD-A)")
        _ = CLIPS.eval(expr: "(defmodule MOD-B)")
        _ = CLIPS.eval(expr: "(defmodule MOD-C)")
        
        // Focus su più moduli
        _ = CLIPS.eval(expr: "(focus MOD-A MOD-B MOD-C)")
        
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        // Il top dello stack dovrebbe essere MOD-C (ultimo argomento)
        XCTAssertEqual(env.focusPeek()?.name, "MOD-C")
    }
    
    func testGetCurrentModuleCommand() {
        _ = CLIPS.createEnvironment()
        
        // Get current module (dovrebbe essere MAIN)
        let result = CLIPS.eval(expr: "(get-current-module)")
        
        if case .symbol(let s) = result {
            XCTAssertEqual(s, "MAIN")
        } else {
            XCTFail("get-current-module dovrebbe ritornare il nome del modulo")
        }
    }
    
    func testSetCurrentModuleCommand() {
        _ = CLIPS.createEnvironment()
        
        // Crea modulo (defmodule lo imposta come corrente automaticamente)
        _ = CLIPS.eval(expr: "(defmodule MY-MODULE)")
        
        // Ritorna a MAIN
        _ = CLIPS.eval(expr: "(set-current-module MAIN)")
        
        // Ora set current module a MY-MODULE dovrebbe ritornare MAIN
        let result = CLIPS.eval(expr: "(set-current-module MY-MODULE)")
        
        // Dovrebbe ritornare il modulo precedente (MAIN)
        if case .symbol(let s) = result {
            XCTAssertEqual(s, "MAIN")
        } else {
            XCTFail("set-current-module dovrebbe ritornare il modulo precedente")
        }
        
        // Verifica che il modulo corrente sia cambiato
        guard let env = CLIPS.currentEnvironment else {
            XCTFail("Environment non disponibile")
            return
        }
        
        XCTAssertEqual(env.getCurrentModule()?.name, "MY-MODULE")
    }
    
    func testListDefmodulesCommand() {
        _ = CLIPS.createEnvironment()
        
        // Crea alcuni moduli
        _ = CLIPS.eval(expr: "(defmodule MOD-A)")
        _ = CLIPS.eval(expr: "(defmodule MOD-B)")
        
        // Lista moduli (dovrebbe stampare)
        let result = CLIPS.eval(expr: "(list-defmodules)")
        
        if case .boolean(let b) = result {
            XCTAssertTrue(b)
        } else {
            XCTFail("list-defmodules dovrebbe ritornare TRUE")
        }
    }
    
    func testGetDefmoduleListCommand() {
        _ = CLIPS.createEnvironment()
        
        // Crea alcuni moduli
        _ = CLIPS.eval(expr: "(defmodule MOD-A)")
        _ = CLIPS.eval(expr: "(defmodule MOD-B)")
        
        // Get defmodule list
        let result = CLIPS.eval(expr: "(get-defmodule-list)")
        
        // Dovrebbe ritornare un multifield
        if case .multifield(let modules) = result {
            let names = modules.compactMap { if case .symbol(let s) = $0 { return s } else { return nil } }
            XCTAssertTrue(names.contains("MAIN"))
            XCTAssertTrue(names.contains("MOD-A"))
            XCTAssertTrue(names.contains("MOD-B"))
            XCTAssertEqual(names.count, 3)
        } else {
            XCTFail("get-defmodule-list dovrebbe ritornare un multifield")
        }
    }
    
    func testAgendaWithModule() {
        _ = CLIPS.createEnvironment()
        
        // Test comando agenda con parametro modulo
        // Per ora non filtra realmente, ma accetta il parametro
        _ = CLIPS.eval(expr: "(defmodule TEST-MOD)")
        let result = CLIPS.eval(expr: "(agenda TEST-MOD)")
        
        if case .int(let count) = result {
            XCTAssertEqual(count, 0)  // Agenda vuota
        } else {
            XCTFail("agenda dovrebbe ritornare il numero di attivazioni")
        }
    }
}

