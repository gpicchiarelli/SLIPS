import Foundation

// MARK: - Helper per tracking memoria completo (non approssimato)

/// Helper per tracciare memoria utilizzata da strutture Swift
/// Ref: CLIPS usa genalloc per tutte le allocazioni, Swift usa strutture native
/// Questo modulo traccia TUTTE le allocazioni come in CLIPS C per compatibilità con mem-used
public enum MemoryTracking {
    
    // MARK: - Stime dimensioni strutture (basate su sizeof in CLIPS C)
    
    /// Stima dimensione di un Template
    /// Ref: CLIPS alloca struct deftemplate con genalloc
    /// Ref: tmpltdef.h - struct deftemplate
    static func estimateTemplateSize(_ template: Environment.Template) -> Int {
        var size = 320  // Base struct deftemplate (approssimativo basato su C struct)
        size += template.name.utf8.count + 32  // Name string + pointer overhead
        size += template.slots.count * 200  // Per slot: struct templateSlot + overhead
        for (_, slotDef) in template.slots {
            size += slotDef.name.utf8.count + 16
            if let constraints = slotDef.constraints {
                size += constraints.allowed.count * 8
                if constraints.range != nil { size += 16 }
            }
            if slotDef.defaultDynamicExpr != nil { size += 64 }  // Expression overhead
            if slotDef.defaultStatic != nil { size += estimateValueSize(slotDef.defaultStatic!) }
        }
        return size
    }
    
    /// Stima dimensione di un FactRec
    /// Ref: CLIPS alloca struct fact con genalloc
    /// Ref: factmngr.h - struct fact
    static func estimateFactSize(_ fact: Environment.FactRec) -> Int {
        var size = 160  // Base struct fact
        size += fact.name.utf8.count + 32  // Name string + pointer
        size += fact.slots.count * 80  // Per slot: CLIPSValue + overhead
        for (key, value) in fact.slots {
            size += key.utf8.count + 16
            size += estimateValueSize(value)
        }
        // Overhead per factPartialMatches tracking
        size += 32
        return size
    }
    
    /// Stima dimensione di un Value
    static func estimateValueSize(_ value: Value) -> Int {
        switch value {
        case .int(_): return 16  // CLIPSValue header + int
        case .float(_): return 16  // CLIPSValue header + double
        case .string(let s): return 32 + s.utf8.count  // CLIPSValue + string + overhead
        case .symbol(let s): return 32 + s.utf8.count  // CLIPSValue + lexeme + overhead
        case .boolean(_): return 16  // CLIPSValue header + bool
        case .multifield(let arr): 
            return 48 + arr.reduce(0) { $0 + estimateValueSize($1) }  // Multifield header + array overhead + elements
        case .none: return 16  // CLIPSValue header
        }
    }
    
    /// Stima dimensione di un Rule
    /// Ref: CLIPS alloca struct defrule con genalloc
    /// Ref: ruledef.h - struct defrule
    static func estimateRuleSize(_ rule: Rule) -> Int {
        var size = 640  // Base struct defrule
        size += rule.name.utf8.count + 32
        size += rule.displayName.utf8.count + 32
        size += rule.patterns.count * 320  // Per pattern: struct defrulePattern + overhead
        size += rule.rhs.count * 128  // Per RHS action: Expression node overhead
        size += rule.tests.count * 128  // Per test: Expression node overhead
        // Stima dimensioni patterns (più dettagliata)
        for pattern in rule.patterns {
            size += pattern.name.utf8.count + 16
            size += pattern.slots.count * 96  // PatternTest overhead
        }
        return size
    }
    
    /// Stima dimensione di un AlphaNodeClass
    /// Ref: CLIPS alloca struct patternNodeHeader/objectAlphaNode con genalloc
    /// Ref: network.h - struct patternNodeHeader
    static func estimateAlphaNodeSize(_ alphaNode: AlphaNodeClass) -> Int {
        var size = 200  // Base struct patternNodeHeader
        size += alphaNode.pattern.name.utf8.count + 32
        size += alphaNode.pattern.slots.count * 64
        size += alphaNode.memory.count * 8  // Fact IDs in memory (Set overhead)
        size += alphaNode.rightJoinListeners.count * 16  // Weak references overhead
        return size
    }
    
    /// Stima dimensione di un JoinNodeClass
    /// Ref: CLIPS alloca struct joinNode con genalloc
    /// Ref: network.h:108 - struct joinNode (circa 200+ bytes)
    static func estimateJoinNodeSize(_ join: JoinNodeClass) -> Int {
        var size = 280  // Base struct joinNode (include flags, pointers, stats)
        size += join.joinKeys.count * 16  // Join keys overhead
        size += join.tests.count * 128  // Expression nodes overhead
        size += join.nextLinks.count * 48  // JoinLink structures
        size += join.linkStorage.count * 48
        // Beta memory overhead (left/right)
        if join.leftMemory != nil {
            size += 128  // BetaMemoryNode overhead
            size += (join.leftMemory?.count ?? 0) * 8  // PartialMatch pointers
        }
        if join.rightMemory != nil {
            size += 128  // BetaMemoryNode overhead
            size += (join.rightMemory?.count ?? 0) * 8  // PartialMatch pointers
        }
        return size
    }
    
    /// Stima dimensione di un ProductionNode
    /// Ref: CLIPS alloca struct defrule con ruleToActivate pointer
    static func estimateProductionNodeSize(_ prod: ProductionNode) -> Int {
        var size = 200  // Base struct defrule reference
        size += prod.ruleName.utf8.count + 32
        size += prod.rhs.count * 128  // Expression nodes overhead
        return size
    }
    
    /// Stima dimensione di un PartialMatch
    /// Ref: CLIPS alloca struct partialMatch con genalloc
    /// Ref: match.h:74 - struct partialMatch (circa 100+ bytes base + flexible array)
    static func estimatePartialMatchSize(_ pm: PartialMatch) -> Int {
        var size = 160  // Base struct partialMatch (flags, pointers, links)
        size += Int(pm.bcount) * 48  // GenericMatch array (binds)
        // Overhead per links (nextInMemory, prevInMemory, children, etc.)
        size += 128
        return size
    }
    
    /// Stima dimensione di un AlphaMatch
    /// Ref: CLIPS alloca struct alphaMatch con genalloc
    /// Ref: match.h:103 - struct alphaMatch
    static func estimateAlphaMatchSize(_ am: AlphaMatch) -> Int {
        var size = 80  // Base struct alphaMatch
        size += 32  // PatternEntity overhead
        return size
    }
    
    /// Stima dimensione di un ExpressionNode
    /// Ref: CLIPS alloca struct expr con genalloc
    /// Ref: expressn.h:61 - struct expr
    static func estimateExpressionNodeSize(_ node: ExpressionNode?) -> Int {
        guard let node = node else { return 0 }
        var size = 48  // Base struct expr (type + union + pointers)
        // Valore
        if let value = node.value?.value {
            if let s = value as? String { size += s.utf8.count + 16 }
            else if value is Int64 { size += 8 }
            else if value is Double { size += 8 }
            else if value is Bool { size += 1 }
            else { size += 16 }
        }
        // Argomenti ricorsivi
        size += estimateExpressionNodeSize(node.argList)
        size += estimateExpressionNodeSize(node.nextArg)
        return size
    }
    
    /// Stima dimensione di un BetaMemoryNode
    /// Ref: CLIPS alloca struct betaMemory con genalloc
    /// Ref: network.h:92 - struct betaMemory
    static func estimateBetaMemoryNodeSize(_ beta: BetaMemoryNode) -> Int {
        var size = 96  // Base struct betaMemory
        size += beta.memory.tokens.count * 200  // BetaToken overhead (includes bindings)
        return size
    }
    
    /// Stima dimensione di un JoinLink
    /// Ref: CLIPS alloca struct joinLink con genalloc
    /// Ref: network.h:100 - struct joinLink
    static func estimateJoinLinkSize(_ link: JoinLink) -> Int {
        return 64  // Base struct joinLink
    }
    
    // MARK: - Tracking pubblico
    
    /// Registra memoria utilizzata da un template
    public static func trackTemplate(_ env: inout Environment, _ template: Environment.Template) {
        let size = estimateTemplateSize(template)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un template
    public static func untrackTemplate(_ env: inout Environment, _ template: Environment.Template) {
        let size = estimateTemplateSize(template)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un fatto
    public static func trackFact(_ env: inout Environment, _ fact: Environment.FactRec) {
        let size = estimateFactSize(fact)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un fatto
    public static func untrackFact(_ env: inout Environment, _ fact: Environment.FactRec) {
        let size = estimateFactSize(fact)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da una regola
    public static func trackRule(_ env: inout Environment, _ rule: Rule) {
        let size = estimateRuleSize(rule)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per una regola
    public static func untrackRule(_ env: inout Environment, _ rule: Rule) {
        let size = estimateRuleSize(rule)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un alpha node
    public static func trackAlphaNode(_ env: inout Environment, _ alphaNode: AlphaNodeClass) {
        let size = estimateAlphaNodeSize(alphaNode)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un alpha node
    public static func untrackAlphaNode(_ env: inout Environment, _ alphaNode: AlphaNodeClass) {
        let size = estimateAlphaNodeSize(alphaNode)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un join node
    public static func trackJoinNode(_ env: inout Environment, _ join: JoinNodeClass) {
        let size = estimateJoinNodeSize(join)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un join node
    public static func untrackJoinNode(_ env: inout Environment, _ join: JoinNodeClass) {
        let size = estimateJoinNodeSize(join)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un production node
    public static func trackProductionNode(_ env: inout Environment, _ prod: ProductionNode) {
        let size = estimateProductionNodeSize(prod)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un production node
    public static func untrackProductionNode(_ env: inout Environment, _ prod: ProductionNode) {
        let size = estimateProductionNodeSize(prod)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un PartialMatch
    public static func trackPartialMatch(_ env: inout Environment, _ pm: PartialMatch) {
        let size = estimatePartialMatchSize(pm)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un PartialMatch
    public static func untrackPartialMatch(_ env: inout Environment, _ pm: PartialMatch) {
        let size = estimatePartialMatchSize(pm)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un AlphaMatch
    public static func trackAlphaMatch(_ env: inout Environment, _ am: AlphaMatch) {
        let size = estimateAlphaMatchSize(am)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un AlphaMatch
    public static func untrackAlphaMatch(_ env: inout Environment, _ am: AlphaMatch) {
        let size = estimateAlphaMatchSize(am)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un ExpressionNode
    public static func trackExpressionNode(_ env: inout Environment, _ node: ExpressionNode?) {
        let size = estimateExpressionNodeSize(node)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un ExpressionNode
    public static func untrackExpressionNode(_ env: inout Environment, _ node: ExpressionNode?) {
        let size = estimateExpressionNodeSize(node)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un BetaMemoryNode
    public static func trackBetaMemoryNode(_ env: inout Environment, _ beta: BetaMemoryNode) {
        let size = estimateBetaMemoryNodeSize(beta)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un BetaMemoryNode
    public static func untrackBetaMemoryNode(_ env: inout Environment, _ beta: BetaMemoryNode) {
        let size = estimateBetaMemoryNodeSize(beta)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Registra memoria utilizzata da un JoinLink
    public static func trackJoinLink(_ env: inout Environment, _ link: JoinLink) {
        let size = estimateJoinLinkSize(link)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Rimuove tracking memoria per un JoinLink
    public static func untrackJoinLink(_ env: inout Environment, _ link: JoinLink) {
        let size = estimateJoinLinkSize(link)
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }
    
    /// Stima dimensione di un file caricato (per tracking durante load)
    static func estimateFileSize(_ content: String) -> Int {
        return content.utf8.count
    }
    
    /// Registra memoria utilizzata durante il load di un file
    public static func trackFileLoad(_ env: inout Environment, _ fileContent: String) {
        let size = estimateFileSize(fileContent)
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
    
    /// Stima dimensione ExpressionHashTable (quando viene inizializzata)
    /// Ref: expressn.c:94-95 - ExpressionHashTable allocation
    public static func trackExpressionHashTable(_ env: inout Environment) {
        let size = Int(ExpressionDataSwift.EXPRESSION_HASH_SIZE) * 16  // Pointer array
        _ = Memalloc.UpdateMemoryUsed(&env, Int64(size))
    }
}

