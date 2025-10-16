// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Module System (Fase 3, Task 3.1)
// Traduzione fedele da moduldef.h, moduldef.c (CLIPS 6.4.2)
// Riferimenti C:
// - struct defmodule (moduldef.h linee 138-145)
// - struct portItem (moduldef.h linee 147-153)
// - struct moduleItem (moduldef.h linee 188-198)
// - struct moduleStackItem (moduldef.h linee 200-205)

/// Tipo di costrutto (enum ConstructType in moduldef.h linee 80-93)
public enum ConstructType {
    case defmodule
    case defrule
    case deftemplate
    case deffacts
    case defglobal
    case deffunction
    case defgeneric
    case defmethod
    case defclass
    case defmessageHandler
    case definstances
}

/// Header di un costrutto (struct constructHeader in moduldef.h linee 99-109)
public class ConstructHeader {
    public var constructType: ConstructType
    public var name: String
    public var ppForm: String?  // Pretty-print form
    public var whichModule: DefmoduleItemHeader?
    public var bsaveID: UInt = 0
    public var next: ConstructHeader?
    // userData: omesso per ora (non essenziale)
    
    public init(type: ConstructType, name: String, ppForm: String? = nil) {
        self.constructType = type
        self.name = name
        self.ppForm = ppForm
    }
}

/// Header di item specifico per modulo (struct defmoduleItemHeader in moduldef.h linee 111-116)
public class DefmoduleItemHeader {
    public var theModule: Defmodule?
    public var firstItem: ConstructHeader?
    public var lastItem: ConstructHeader?
    
    public init() {}
}

/// Port item per import/export (struct portItem in moduldef.h linee 147-153)
/// Gestisce import/export di costrutti tra moduli
public class PortItem {
    public var moduleName: String
    public var constructType: String?  // nil = tutti i tipi
    public var constructName: String?  // nil = tutti i nomi
    public var next: PortItem?
    
    public init(moduleName: String, constructType: String? = nil, constructName: String? = nil) {
        self.moduleName = moduleName
        self.constructType = constructType
        self.constructName = constructName
    }
}

/// Defmodule - modulo CLIPS (struct defmodule in moduldef.h linee 138-145)
/// Rappresenta un namespace per i costrutti
public class Defmodule {
    public var header: ConstructHeader
    public var itemsArray: [DefmoduleItemHeader?] = []  // Array di item per tipo costrutto
    public var importList: PortItem?  // Lista import
    public var exportList: PortItem?  // Lista export
    public var visitedFlag: Bool = false  // Per algoritmi di attraversamento
    
    /// Riferimento al modulo successivo nella lista globale
    public var next: Defmodule?
    
    public init(name: String, ppForm: String? = nil) {
        self.header = ConstructHeader(type: .defmodule, name: name, ppForm: ppForm)
    }
    
    /// Nome del modulo
    public var name: String {
        return header.name
    }
}

/// Module item - registrazione tipo costrutto (struct moduleItem in moduldef.h linee 188-198)
/// Definisce come un tipo di costrutto è gestito nei moduli
public class ModuleItem {
    public var name: String  // "defrule", "deftemplate", ecc.
    public var moduleIndex: UInt  // Indice nell'itemsArray
    public var next: ModuleItem?
    
    // Funzioni allocazione/deallocazione (per ora callback semplici)
    public var allocateFunction: (() -> DefmoduleItemHeader?)?
    public var freeFunction: ((DefmoduleItemHeader?) -> Void)?
    
    public init(name: String, moduleIndex: UInt) {
        self.name = name
        self.moduleIndex = moduleIndex
    }
}

/// Module stack item - per focus stack (struct moduleStackItem in moduldef.h linee 200-205)
/// Gestisce lo stack di moduli per il focus
public class ModuleStackItem {
    public var changeFlag: Bool = false
    public var theModule: Defmodule?
    public var next: ModuleStackItem?
    
    public init(module: Defmodule?, changeFlag: Bool = false) {
        self.theModule = module
        self.changeFlag = changeFlag
    }
}

// MARK: - Module Management Functions

/// Gestione dei moduli nell'Environment
extension Environment {
    
    /// Inizializza il sistema di moduli (ref: InitializeDefmodules in moduldef.c linee 183-200)
    public func initializeModules() {
        // Prima registra i tipi di item
        registerModuleItems()
        
        // Poi crea modulo MAIN di default
        createMainModule()
    }
    
    /// Crea modulo MAIN (ref: CreateMainModule in moduldef.c)
    private func createMainModule() {
        let mainModule = Defmodule(name: "MAIN", ppForm: "(defmodule MAIN)")
        
        // Alloca array di item headers per tutti i tipi registrati
        mainModule.itemsArray = Array(repeating: nil, count: Int(numberOfModuleItems))
        
        // Inizializza item headers per ogni tipo
        for i in 0..<Int(numberOfModuleItems) {
            let header = DefmoduleItemHeader()
            header.theModule = mainModule
            mainModule.itemsArray[i] = header
        }
        
        // Aggiungi alla lista globale
        if listOfDefmodules == nil {
            listOfDefmodules = mainModule
            lastDefmodule = mainModule
        }
        
        // Imposta come modulo corrente
        currentModule = mainModule
    }
    
    /// Registra i tipi di item supportati (ref: RegisterModuleItem in moduldef.c)
    private func registerModuleItems() {
        // Registra "defrule"
        let _ = registerModuleItem(name: "defrule")
        
        // Registra "deftemplate"
        let _ = registerModuleItem(name: "deftemplate")
        
        // Registra "deffacts"
        let _ = registerModuleItem(name: "deffacts")
        
        // Altri tipi possono essere aggiunti dopo
    }
    
    /// Registra un nuovo tipo di item per moduli
    /// (ref: RegisterModuleItem in moduldef.c linee 366-403)
    @discardableResult
    private func registerModuleItem(name: String) -> UInt {
        let newItem = ModuleItem(name: name, moduleIndex: numberOfModuleItems)
        
        // Aggiungi alla lista
        if let last = lastModuleItem {
            last.next = newItem
        } else {
            listOfModuleItems = newItem
        }
        lastModuleItem = newItem
        
        // Incrementa contatore
        numberOfModuleItems += 1
        
        return newItem.moduleIndex
    }
    
    /// Trova un modulo per nome (ref: FindDefmodule in moduldef.c linee 258-273)
    public func findDefmodule(name: String) -> Defmodule? {
        var current = listOfDefmodules
        while let module = current {
            if module.name == name {
                return module
            }
            current = module.next
        }
        return nil
    }
    
    /// Ottiene il modulo corrente (ref: GetCurrentModule in moduldef.c linee 612-616)
    public func getCurrentModule() -> Defmodule? {
        return currentModule
    }
    
    /// Imposta il modulo corrente (ref: SetCurrentModule in moduldef.c linee 625-660)
    @discardableResult
    public func setCurrentModule(_ module: Defmodule?) -> Defmodule? {
        let previousModule = currentModule
        currentModule = module
        
        // Callback per notifica cambio modulo (omesso per ora)
        
        return previousModule
    }
    
    /// Crea un nuovo modulo (ref: ParseDefmodule in modulpsr.c)
    public func createDefmodule(name: String, importList: PortItem? = nil, exportList: PortItem? = nil) -> Defmodule? {
        // Verifica che non esista già
        if findDefmodule(name: name) != nil {
            print("[ERROR] Defmodule \(name) already exists")
            return nil
        }
        
        let newModule = Defmodule(name: name, ppForm: "(defmodule \(name))")
        
        // Alloca array di item headers
        newModule.itemsArray = Array(repeating: nil, count: Int(numberOfModuleItems))
        for i in 0..<Int(numberOfModuleItems) {
            let header = DefmoduleItemHeader()
            header.theModule = newModule
            newModule.itemsArray[i] = header
        }
        
        // Imposta import/export
        newModule.importList = importList
        newModule.exportList = exportList
        
        // Aggiungi alla lista
        if let last = lastDefmodule {
            last.next = newModule
        } else {
            listOfDefmodules = newModule
        }
        lastDefmodule = newModule
        
        return newModule
    }
    
    /// Lista tutti i moduli (per debug/testing)
    public func listDefmodules() -> [String] {
        var names: [String] = []
        var current = listOfDefmodules
        while let module = current {
            names.append(module.name)
            current = module.next
        }
        return names
    }
}

// MARK: - Focus Stack Management

/// Gestione dello stack di focus (ref: ModuleStack in moduldef.h)
extension Environment {
    
    /// Inizializza focus stack
    public func initializeFocusStack() {
        // Il focus stack parte vuoto
        // Quando si chiama (focus <module>), il modulo viene pushato
        moduleStack = nil
    }
    
    /// Push di un modulo nello stack di focus (ref: Focus in agenda.c)
    public func focusPush(module: Defmodule) {
        let stackItem = ModuleStackItem(module: module, changeFlag: true)
        stackItem.next = moduleStack
        moduleStack = stackItem
    }
    
    /// Pop dallo stack di focus
    @discardableResult
    public func focusPop() -> Defmodule? {
        guard let top = moduleStack else { return nil }
        moduleStack = top.next
        return top.theModule
    }
    
    /// Peek del modulo in cima allo stack
    public func focusPeek() -> Defmodule? {
        return moduleStack?.theModule
    }
    
    /// Verifica se lo stack è vuoto
    public func isFocusStackEmpty() -> Bool {
        return moduleStack == nil
    }
    
    /// Ottiene il modulo di focus corrente (top dello stack o currentModule)
    public func getCurrentFocusModule() -> Defmodule? {
        return focusPeek() ?? currentModule
    }
    
    /// Ritorna i nomi dei moduli nello stack di focus (dall'alto verso il basso)
    /// FASE 3 - Module-aware agenda
    /// Ref: agenda.c - focus stack traversal
    public func getFocusStackNames() -> [String] {
        var names: [String] = []
        var current = moduleStack
        while let item = current {
            if let mod = item.theModule {
                names.append(mod.name)
            }
            current = item.next
        }
        return names
    }
}

// MARK: - Environment Extensions for Modules

extension Environment {
    
    /// Variabili per gestione moduli (ref: struct defmoduleData in moduldef.h linee 209-236)
    /// Queste dovrebbero essere aggiunte a Environment in envrnmnt.swift
    
    // Per ora le definiamo come computed properties che accedono a campi esistenti
    // TODO: Aggiungere questi campi direttamente a Environment
    
    /// Lista di tutti i moduli
    public var listOfDefmodules: Defmodule? {
        get { return self._listOfDefmodules }
        set { self._listOfDefmodules = newValue }
    }
    
    /// Modulo corrente
    public var currentModule: Defmodule? {
        get { return self._currentModule }
        set { self._currentModule = newValue }
    }
    
    /// Ultimo modulo creato
    public var lastDefmodule: Defmodule? {
        get { return self._lastDefmodule }
        set { self._lastDefmodule = newValue }
    }
    
    /// Lista di tipi di item registrati
    public var listOfModuleItems: ModuleItem? {
        get { return self._listOfModuleItems }
        set { self._listOfModuleItems = newValue }
    }
    
    /// Ultimo module item registrato
    public var lastModuleItem: ModuleItem? {
        get { return self._lastModuleItem }
        set { self._lastModuleItem = newValue }
    }
    
    /// Numero di tipi di item registrati
    public var numberOfModuleItems: UInt {
        get { return self._numberOfModuleItems }
        set { self._numberOfModuleItems = newValue }
    }
    
    /// Stack di focus
    public var moduleStack: ModuleStackItem? {
        get { return self._moduleStack }
        set { self._moduleStack = newValue }
    }
}

