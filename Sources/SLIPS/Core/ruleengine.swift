// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Core Data Structures (from CLIPS C)

public struct PatternTest: Codable {
    public enum Kind: Codable {
        case constant(Value)
        case variable(String)
        case mfVariable(String)
        case predicate(ExpressionNode)
        case sequence([PatternTest])
    }
    public let kind: Kind
}

public struct Pattern: Codable {
    public let name: String
    public let slots: [String: PatternTest]
    public let negated: Bool
    public let exists: Bool
}

public struct Rule: Codable {
    public let name: String
    public let displayName: String
    public let patterns: [Pattern]
    public let rhs: [ExpressionNode]
    public let salience: Int
    public let tests: [ExpressionNode]
    public var moduleName: String? = nil
}

// MARK: - Rule Engine (RETE-based)
// Ref: engine.c, drive.c in CLIPS C

public enum RuleEngine {
    
    /// Aggiunge una regola alla rete RETE
    /// Ref: AddRule in rulebsc.c, ConstructJoins in rulebld.c
    public static func addRule(_ env: inout Environment, _ rule: Rule) {
        env.rules.append(rule)
        // Ref: Tracking memoria per regola (CLIPS usa genalloc)
        MemoryTracking.trackRule(&env, rule)
        
        // Costruisci rete con nodi espliciti (unico percorso, come in CLIPS C)
        _ = NetworkBuilder.buildNetwork(for: rule, env: &env)
        
        if env.watchRete {
            print("[RuleEngine] Rule '\(rule.name)' added to RETE network")
        }
    }

    /// Propaga asserzione di un fatto attraverso la rete RETE
    /// Ref: NetworkAssert in drive.c
    public static func onAssert(_ env: inout Environment, _ fact: Environment.FactRec) {
        env.rete.alpha.add(fact)
        Propagation.propagateAssert(fact: fact, env: &env)
        
        if env.watchRete {
            print("[RuleEngine] Fact \(fact.id) propagated through RETE network")
        }
    }

    /// Esegue regole dall'agenda
    /// Ref: RunCommand in engine.c
    public static func run(_ env: inout Environment, limit: Int?) -> Int {
        // FASE 3: Applica focus stack sorting se presente
        let focusStack = env.getFocusStackNames()
        if !focusStack.isEmpty {
            env.agendaQueue.applyFocusStackSorting(focusStack)
        }
        
        var fired = 0
        let max = limit ?? Int.max
        while fired < max, let act = env.agendaQueue.next() {
            guard let rule = env.rules.first(where: { $0.name == act.ruleName || $0.displayName == act.ruleName }) else { continue }
            let oldBindings = env.localBindings
            if let b = act.bindings { 
                for (k,v) in b { env.localBindings[k] = v } 
            }
            if env.watchRules {
                Router.Writeln(&env, "FIRE \(rule.displayName)")
            }
            for exp in rule.rhs { 
                _ = Evaluator.EvaluateExpression(&env, exp) 
            }
            env.localBindings = oldBindings
            fired += 1
        }
        return fired
    }
}
