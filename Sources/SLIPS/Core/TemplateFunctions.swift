// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni Template CLIPS
/// Traduzione semantica da clips_core_source_642/core/tmpltfun.c
///
/// Funzioni implementate (ref: DeftemplateFunctions, line 153):
/// - deftemplate-slot-names: Lista slot di un template
/// - deftemplate-slot-default-value: Valore default di uno slot
/// - deftemplate-slot-cardinality: Cardinalità slot multifield
/// - deftemplate-slot-allowed-values: Valori consentiti per slot
/// - deftemplate-slot-range: Range valori numerici
/// - deftemplate-slot-types: Tipi consentiti per slot
/// - deftemplate-slot-multip: Check se slot è multifield
/// - deftemplate-slot-singlep: Check se slot è single-field
/// - deftemplate-slot-existp: Check se slot esiste
/// - deftemplate-slot-defaultp: Tipo di default (static/dynamic)
/// - deftemplate-slot-facet-existp: Check esistenza facet
/// - deftemplate-slot-facet-value: Valore di un facet
/// - modify: Modifica fatto esistente
/// - duplicate: Duplica fatto con modifiche
public enum TemplateFunctions {
    /// Registra tutte le funzioni template nell'environment
    /// Ref: DeftemplateFunctions (tmpltfun.c, line 153)
    public static func registerAll(_ env: inout Environment) {
        // Introspection functions
        env.functionTable["deftemplate-slot-names"] = FunctionDefinitionSwift(name: "deftemplate-slot-names", impl: builtin_deftemplate_slot_names)
        env.functionTable["deftemplate-slot-default-value"] = FunctionDefinitionSwift(name: "deftemplate-slot-default-value", impl: builtin_deftemplate_slot_default_value)
        env.functionTable["deftemplate-slot-cardinality"] = FunctionDefinitionSwift(name: "deftemplate-slot-cardinality", impl: builtin_deftemplate_slot_cardinality)
        env.functionTable["deftemplate-slot-allowed-values"] = FunctionDefinitionSwift(name: "deftemplate-slot-allowed-values", impl: builtin_deftemplate_slot_allowed_values)
        env.functionTable["deftemplate-slot-range"] = FunctionDefinitionSwift(name: "deftemplate-slot-range", impl: builtin_deftemplate_slot_range)
        env.functionTable["deftemplate-slot-types"] = FunctionDefinitionSwift(name: "deftemplate-slot-types", impl: builtin_deftemplate_slot_types)
        env.functionTable["deftemplate-slot-multip"] = FunctionDefinitionSwift(name: "deftemplate-slot-multip", impl: builtin_deftemplate_slot_multip)
        env.functionTable["deftemplate-slot-singlep"] = FunctionDefinitionSwift(name: "deftemplate-slot-singlep", impl: builtin_deftemplate_slot_singlep)
        env.functionTable["deftemplate-slot-existp"] = FunctionDefinitionSwift(name: "deftemplate-slot-existp", impl: builtin_deftemplate_slot_existp)
        env.functionTable["deftemplate-slot-defaultp"] = FunctionDefinitionSwift(name: "deftemplate-slot-defaultp", impl: builtin_deftemplate_slot_defaultp)
        
        // Facet functions
        env.functionTable["deftemplate-slot-facet-existp"] = FunctionDefinitionSwift(name: "deftemplate-slot-facet-existp", impl: builtin_deftemplate_slot_facet_existp)
        env.functionTable["deftemplate-slot-facet-value"] = FunctionDefinitionSwift(name: "deftemplate-slot-facet-value", impl: builtin_deftemplate_slot_facet_value)
        
        // Manipulation functions
        env.functionTable["modify"] = FunctionDefinitionSwift(name: "modify", impl: builtin_modify)
        env.functionTable["duplicate"] = FunctionDefinitionSwift(name: "duplicate", impl: builtin_duplicate)
    }
}

// MARK: - deftemplate-slot-names

/// (deftemplate-slot-names <deftemplate-name>) - Ritorna lista nomi slot
/// Ref: DeftemplateSlotNamesFunction (tmpltfun.c, line 901)
///
/// Esempi:
/// ```
/// (deftemplate person (slot name) (slot age))
/// (deftemplate-slot-names person)  → (create$ name age)
/// ```
public func builtin_deftemplate_slot_names(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("deftemplate-slot-names", expected: 1, got: args.count)
    }
    
    let templateName: String
    switch args[0] {
    case .symbol(let s): templateName = s
    case .string(let s): templateName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-names", expected: "symbol", got: String(describing: args[0]))
    }
    
    guard let template = env.templates[templateName] else {
        throw EvalError.runtime("deftemplate-slot-names: template '\(templateName)' does not exist")
    }
    
    let slotNames = template.slots.keys.sorted().map { Value.symbol($0) }
    return .multifield(slotNames)
}

// MARK: - deftemplate-slot-default-value

/// (deftemplate-slot-default-value <deftemplate-name> <slot-name>) - Valore default slot
/// Ref: DeftemplateSlotDefaultValueFunction (tmpltfun.c, line 1090)
///
/// Esempi:
/// ```
/// (deftemplate person (slot name (default "unknown")) (slot age (default 0)))
/// (deftemplate-slot-default-value person name)  → "unknown"
/// (deftemplate-slot-default-value person age)   → 0
/// ```
public func builtin_deftemplate_slot_default_value(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-default-value", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-default-value")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-default-value: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    // Ritorna valore default statico se presente
    if case .static = slot.defaultType, let defaultValue = slot.defaultStatic {
        return defaultValue
    }
    
    // Default dinamico non supportato completamente in questa versione
    return .none
}

// MARK: - deftemplate-slot-cardinality

/// (deftemplate-slot-cardinality <deftemplate-name> <slot-name>) - Cardinalità slot
/// Ref: DeftemplateSlotCardinalityFunction (tmpltfun.c, line 1192)
///
/// Ritorna (create$ <min> <max>) per slot multifield
///
/// Esempi:
/// ```
/// (deftemplate data (multislot values))
/// (deftemplate-slot-cardinality data values)  → (create$ 0 +00)  ; illimitato
/// ```
public func builtin_deftemplate_slot_cardinality(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-cardinality", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-cardinality")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-cardinality: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    if slot.isMultifield {
        // Per ora ritorniamo cardinalità illimitata
        return .multifield([.int(0), .symbol("+00")])  // 0 to infinity
    } else {
        return .multifield([.int(1), .int(1)])  // Single field: exactly 1
    }
}

// MARK: - deftemplate-slot-types

/// (deftemplate-slot-types <deftemplate-name> <slot-name>) - Tipi consentiti
/// Ref: DeftemplateSlotTypesFunction (tmpltfun.c, line 1508)
///
/// Esempi:
/// ```
/// (deftemplate person (slot age (type INTEGER)))
/// (deftemplate-slot-types person age)  → (create$ INTEGER)
/// ```
public func builtin_deftemplate_slot_types(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-types", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-types")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-types: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    // Se ci sono constraints sui tipi, ritornarli
    if let constraints = slot.constraints, !constraints.allowed.isEmpty {
        let types = constraints.allowed.map { Value.symbol($0.rawValue.uppercased()) }
        return .multifield(types)
    }
    
    // Altrimenti tutti i tipi sono consentiti
    return .symbol("?VARIABLE")  // CLIPS convention per "any type"
}

// MARK: - deftemplate-slot-range

/// (deftemplate-slot-range <deftemplate-name> <slot-name>) - Range valori
/// Ref: DeftemplateSlotRangeFunction (tmpltfun.c, line 1406)
///
/// Esempi:
/// ```
/// (deftemplate data (slot value (range 0 100)))
/// (deftemplate-slot-range data value)  → (create$ 0 100)
/// ```
public func builtin_deftemplate_slot_range(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-range", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-range")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-range: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    // Se c'è un range definito, ritornarlo
    if let constraints = slot.constraints, let range = constraints.range {
        return .multifield([.float(range.lowerBound), .float(range.upperBound)])
    }
    
    // Nessun range specificato
    return .symbol("?VARIABLE")
}

// MARK: - deftemplate-slot-multip

/// (deftemplate-slot-multip <deftemplate-name> <slot-name>) - Check multifield
/// Ref: DeftemplateSlotMultiPFunction (tmpltfun.c, line 1671)
///
/// Esempi:
/// ```
/// (deftemplate data (multislot values))
/// (deftemplate-slot-multip data values)  → TRUE
/// ```
public func builtin_deftemplate_slot_multip(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-multip", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-multip")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-multip: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    return .boolean(slot.isMultifield)
}

// MARK: - deftemplate-slot-singlep

/// (deftemplate-slot-singlep <deftemplate-name> <slot-name>) - Check single-field
/// Ref: DeftemplateSlotSinglePFunction (tmpltfun.c, line 1750)
///
/// Esempi:
/// ```
/// (deftemplate person (slot name))
/// (deftemplate-slot-singlep person name)  → TRUE
/// ```
public func builtin_deftemplate_slot_singlep(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-singlep", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-singlep")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-singlep: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    return .boolean(!slot.isMultifield)
}

// MARK: - deftemplate-slot-existp

/// (deftemplate-slot-existp <deftemplate-name> <slot-name>) - Check esistenza slot
/// Ref: DeftemplateSlotExistPFunction (tmpltfun.c, line 1829)
///
/// Esempi:
/// ```
/// (deftemplate person (slot name) (slot age))
/// (deftemplate-slot-existp person name)     → TRUE
/// (deftemplate-slot-existp person salary)   → FALSE
/// ```
public func builtin_deftemplate_slot_existp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-existp", expected: 2, got: args.count)
    }
    
    let templateName: String
    switch args[0] {
    case .symbol(let s): templateName = s
    case .string(let s): templateName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-existp", expected: "symbol", got: String(describing: args[0]))
    }
    
    let slotName: String
    switch args[1] {
    case .symbol(let s): slotName = s
    case .string(let s): slotName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-existp", expected: "symbol", got: String(describing: args[1]))
    }
    
    guard let template = env.templates[templateName] else {
        return .boolean(false)  // Template non esiste
    }
    
    return .boolean(template.slots[slotName] != nil)
}

// MARK: - deftemplate-slot-allowed-values

/// (deftemplate-slot-allowed-values <deftemplate-name> <slot-name>) - Valori consentiti
/// Ref: DeftemplateSlotAllowedValuesFunction (tmpltfun.c, line 1300)
///
/// Ritorna i valori consentiti per uno slot, o FALSE se non ci sono restrizioni
///
/// Esempi:
/// ```
/// (deftemplate person (slot age (allowed-values 18 21 65)))
/// (deftemplate-slot-allowed-values person age)  → (create$ 18 21 65)
/// ```
public func builtin_deftemplate_slot_allowed_values(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-allowed-values", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-allowed-values")
    
    guard template.slots[slotName] != nil else {
        throw EvalError.runtime("deftemplate-slot-allowed-values: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    // TODO: Il facet allowed-values non è ancora implementato nel parsing
    // Per ora ritorniamo sempre FALSE
    // Ref: DeftemplateSlotAllowedValues (tmpltfun.c, line 1382-1399)
    // In futuro: se ci sono valori consentiti nelle constraints, ritornarli
    // if let constraints = slot.constraints, let allowedValues = constraints.allowedValues, !allowedValues.isEmpty {
    //     return .multifield(allowedValues)
    // }
    
    // Nessuna restrizione sui valori (allowed-values facet non ancora supportato)
    return .boolean(false)
}

// MARK: - deftemplate-slot-defaultp

/// (deftemplate-slot-defaultp <deftemplate-name> <slot-name>) - Tipo di default
/// Ref: DeftemplateSlotDefaultPFunction (tmpltfun.c, line 996)
///
/// Ritorna il tipo di default: "static", "dynamic" o FALSE
///
/// Esempi:
/// ```
/// (deftemplate data (slot value (default 10)))
/// (deftemplate-slot-defaultp data value)  → static
/// 
/// (deftemplate log (slot timestamp (default-dynamic (time))))
/// (deftemplate-slot-defaultp log timestamp)  → dynamic
/// ```
public func builtin_deftemplate_slot_defaultp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("deftemplate-slot-defaultp", expected: 2, got: args.count)
    }
    
    let (template, slotName) = try extractTemplateAndSlot(args, env: env, function: "deftemplate-slot-defaultp")
    
    guard let slot = template.slots[slotName] else {
        throw EvalError.runtime("deftemplate-slot-defaultp: slot '\(slotName)' does not exist in template '\(template.name)'")
    }
    
    // Check tipo di default
    switch slot.defaultType {
    case .none:
        return .boolean(false)
    case .static:
        return .symbol("static")
    case .dynamic:
        return .symbol("dynamic")
    }
}

// MARK: - deftemplate-slot-facet-existp

/// (deftemplate-slot-facet-existp <deftemplate-name> <slot-name> <facet-name>) - Check esistenza facet
/// Ref: DeftemplateSlotFacetExistPFunction (tmpltfun.c, line 1897)
///
/// Ritorna TRUE se il facet esiste per lo slot specificato
///
/// Esempi:
/// ```
/// (deftemplate data (slot value (range 0 100)))
/// (deftemplate-slot-facet-existp data value range)  → TRUE
/// (deftemplate-slot-facet-existp data value type)   → FALSE
/// ```
public func builtin_deftemplate_slot_facet_existp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("deftemplate-slot-facet-existp", expected: 3, got: args.count)
    }
    
    let templateName: String
    switch args[0] {
    case .symbol(let s): templateName = s
    case .string(let s): templateName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-existp", expected: "symbol", got: String(describing: args[0]))
    }
    
    let slotName: String
    switch args[1] {
    case .symbol(let s): slotName = s
    case .string(let s): slotName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-existp", expected: "symbol", got: String(describing: args[1]))
    }
    
    let facetName: String
    switch args[2] {
    case .symbol(let s): facetName = s
    case .string(let s): facetName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-existp", expected: "symbol", got: String(describing: args[2]))
    }
    
    guard let template = env.templates[templateName] else {
        return .boolean(false)
    }
    
    guard let slot = template.slots[slotName] else {
        return .boolean(false)
    }
    
    // Check se il facet esiste
    // I facets comuni sono: default, type, allowed-values, range, cardinality
    if let constraints = slot.constraints {
        switch facetName.lowercased() {
        case "type", "types":
            return .boolean(!constraints.allowed.isEmpty)
        case "range":
            return .boolean(constraints.range != nil)
        case "allowed-values":
            // TODO: allowed-values facet non ancora supportato nel parsing
            return .boolean(false)
        case "cardinality":
            return .boolean(slot.isMultifield)
        case "default":
            return .boolean(slot.defaultType != .none)
        default:
            return .boolean(false)
        }
    }
    
    // Check default anche senza constraints
    if facetName.lowercased() == "default" {
        return .boolean(slot.defaultType != .none)
    }
    
    return .boolean(false)
}

// MARK: - deftemplate-slot-facet-value

/// (deftemplate-slot-facet-value <deftemplate-name> <slot-name> <facet-name>) - Valore facet
/// Ref: DeftemplateSlotFacetValueFunction (tmpltfun.c, line 1987)
///
/// Ritorna il valore del facet specificato, o FALSE se non esiste
///
/// Esempi:
/// ```
/// (deftemplate data (slot value (default 42)))
/// (deftemplate-slot-facet-value data value default)  → 42
/// ```
public func builtin_deftemplate_slot_facet_value(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("deftemplate-slot-facet-value", expected: 3, got: args.count)
    }
    
    let templateName: String
    switch args[0] {
    case .symbol(let s): templateName = s
    case .string(let s): templateName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-value", expected: "symbol", got: String(describing: args[0]))
    }
    
    let slotName: String
    switch args[1] {
    case .symbol(let s): slotName = s
    case .string(let s): slotName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-value", expected: "symbol", got: String(describing: args[1]))
    }
    
    let facetName: String
    switch args[2] {
    case .symbol(let s): facetName = s
    case .string(let s): facetName = s
    default:
        throw EvalError.typeMismatch("deftemplate-slot-facet-value", expected: "symbol", got: String(describing: args[2]))
    }
    
    guard let template = env.templates[templateName] else {
        return .boolean(false)
    }
    
    guard let slot = template.slots[slotName] else {
        return .boolean(false)
    }
    
    // Ritorna il valore del facet
    switch facetName.lowercased() {
    case "default":
        if case .static = slot.defaultType, let defaultValue = slot.defaultStatic {
            return defaultValue
        }
        return .boolean(false)
        
    case "type", "types":
        if let constraints = slot.constraints, !constraints.allowed.isEmpty {
            let types = constraints.allowed.map { Value.symbol($0.rawValue.uppercased()) }
            return .multifield(types)
        }
        return .boolean(false)
        
    case "range":
        if let constraints = slot.constraints, let range = constraints.range {
            return .multifield([.float(range.lowerBound), .float(range.upperBound)])
        }
        return .boolean(false)
        
    case "allowed-values":
        // TODO: allowed-values facet non ancora supportato nel parsing
        // In futuro: if let constraints = slot.constraints, let allowedValues = constraints.allowedValues {
        //     return .multifield(allowedValues)
        // }
        return .boolean(false)
        
    case "cardinality":
        if slot.isMultifield {
            return .multifield([.int(0), .symbol("+00")])  // 0 to infinity
        }
        return .multifield([.int(1), .int(1)])
        
    default:
        return .boolean(false)
    }
}

// MARK: - modify

/// (modify <fact-id> <slot-modifications>*) - Modifica fatto esistente
/// Ref: ModifyCommand (tmpltfun.c, line 157)
///
/// Comportamento:
/// - Retract fatto esistente
/// - Assert nuovo fatto con modifiche
/// - Preserva fact-id se possibile (CLIPS 6.40+)
///
/// Esempi:
/// ```
/// (assert (person (name "John") (age 30)))  ; fact-1
/// (modify 1 (age 31))                       ; Aggiorna età
/// ```
public func builtin_modify(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("modify", expected: "1+", got: args.count)
    }
    
    // Estrai fact ID
    guard case .int(let factId) = args[0] else {
        throw EvalError.typeMismatch("modify", expected: "integer fact-id", got: String(describing: args[0]))
    }
    
    // Trova il fatto
    guard let fact = env.facts[Int(factId)] else {
        throw EvalError.runtime("modify: fact f-\(factId) does not exist")
    }
    
    // Copia slots esistenti
    var newSlots = fact.slots
    
    // Applica modifiche (args[1..])
    // Formato: (slot-name value) coppie
    var i = 1
    while i < args.count {
        guard case .symbol(let slotName) = args[i] else {
            throw EvalError.runtime("modify: expected slot name, got \(args[i])")
        }
        
        guard i + 1 < args.count else {
            throw EvalError.runtime("modify: missing value for slot '\(slotName)'")
        }
        
        newSlots[slotName] = args[i + 1]
        i += 2
    }
    
    // Retract fatto vecchio
    env.facts.removeValue(forKey: Int(factId))
    
    // Assert nuovo fatto (CLIPS 6.40+ preserva fact-id)
    let newFact = Environment.FactRec(id: Int(factId), name: fact.name, slots: newSlots)
    env.facts[Int(factId)] = newFact
    
    // Trigger RETE propagation
    RuleEngine.onAssert(&env, newFact)
    
    if env.watchFacts {
        Router.Writeln(&env, "==> f-\(factId) (\(fact.name) \(formatSlots(newSlots)))")
    }
    
    return .int(factId)
}

// MARK: - duplicate

/// (duplicate <fact-id> [to <new-template>] <slot-modifications>*) - Duplica fatto
/// Ref: DuplicateCommand (tmpltfun.c, line 157)
///
/// Comportamento:
/// - Copia fatto esistente
/// - Applica modifiche
/// - Assert come nuovo fatto
///
/// Esempi:
/// ```
/// (assert (person (name "John") (age 30)))  ; fact-1
/// (duplicate 1 (name "Jane"))               ; fact-2 con name="Jane", age=30
/// ```
public func builtin_duplicate(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("duplicate", expected: "1+", got: args.count)
    }
    
    // Estrai fact ID
    guard case .int(let factId) = args[0] else {
        throw EvalError.typeMismatch("duplicate", expected: "integer fact-id", got: String(describing: args[0]))
    }
    
    // Trova il fatto
    guard let fact = env.facts[Int(factId)] else {
        throw EvalError.runtime("duplicate: fact f-\(factId) does not exist")
    }
    
    // Copia slots esistenti
    var newSlots = fact.slots
    var templateName = fact.name
    
    // Applica modifiche (args[1..])
    var i = 1
    
    // Check per "to <new-template>"
    if i < args.count, case .symbol(let keyword) = args[i], keyword == "to" {
        i += 1
        if i < args.count, case .symbol(let newTemplate) = args[i] {
            templateName = newTemplate
            i += 1
        }
    }
    
    // Applica modifiche slot
    while i < args.count {
        guard case .symbol(let slotName) = args[i] else {
            throw EvalError.runtime("duplicate: expected slot name, got \(args[i])")
        }
        
        guard i + 1 < args.count else {
            throw EvalError.runtime("duplicate: missing value for slot '\(slotName)'")
        }
        
        newSlots[slotName] = args[i + 1]
        i += 2
    }
    
    // Assert nuovo fatto
    let newFactId = env.nextFactId
    env.nextFactId += 1
    
    let newFact = Environment.FactRec(id: newFactId, name: templateName, slots: newSlots)
    env.facts[newFactId] = newFact
    
    // Trigger RETE propagation
    RuleEngine.onAssert(&env, newFact)
    
    if env.watchFacts {
        Router.Writeln(&env, "==> f-\(newFactId) (\(templateName) \(formatSlots(newSlots)))")
    }
    
    return .int(Int64(newFactId))
}

// MARK: - Helper Functions

/// Estrae template e slot name dagli argomenti
private func extractTemplateAndSlot(_ args: [Value], env: Environment, function: String) throws -> (Environment.Template, String) {
    let templateName: String
    switch args[0] {
    case .symbol(let s): templateName = s
    case .string(let s): templateName = s
    default:
        throw EvalError.typeMismatch(function, expected: "symbol", got: String(describing: args[0]))
    }
    
    let slotName: String
    switch args[1] {
    case .symbol(let s): slotName = s
    case .string(let s): slotName = s
    default:
        throw EvalError.typeMismatch(function, expected: "symbol", got: String(describing: args[1]))
    }
    
    guard let template = env.templates[templateName] else {
        throw EvalError.runtime("\(function): template '\(templateName)' does not exist")
    }
    
    return (template, slotName)
}

/// Formatta slots per output
private func formatSlots(_ slots: [String: Value]) -> String {
    return slots.sorted(by: { $0.key < $1.key })
        .map { "(\($0.key) \(formatValue($0.value)))" }
        .joined(separator: " ")
}

/// Formatta value per output
private func formatValue(_ value: Value) -> String {
    switch value {
    case .none: return "nil"
    case .int(let i): return String(i)
    case .float(let d): return String(d)
    case .string(let s): return "\"\(s)\""
    case .symbol(let s): return s
    case .boolean(let b): return b ? "TRUE" : "FALSE"
    case .multifield(let arr): return arr.map { formatValue($0) }.joined(separator: " ")
    }
}

