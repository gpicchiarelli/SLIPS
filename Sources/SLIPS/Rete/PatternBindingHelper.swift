// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Utility condivise per normalizzare i nomi delle variabili e per il matching delle sequenze
/// multifield (port diretto da factrete.c). Estratto da Propagation per poter riutilizzare
/// la stessa logica anche nel join-check naive.
enum PatternBindingHelper {
    /// Rimuove i prefissi CLIPS (`?`, `$?`) dai nomi delle variabili.
    static func cleanVariableName(_ name: String) -> String {
        var cleaned = name
        if cleaned.hasPrefix("$?") {
            cleaned.removeFirst(2)
        }
        if cleaned.hasPrefix("?") {
            cleaned.removeFirst()
        }
        return cleaned
    }
    
    /// Effettua il match di una sequenza multifield con backtracking.
    /// - Parameters:
    ///   - items: pattern test (sequenza normalizzata da parseSimplePattern)
    ///   - values: valori presenti nello slot multifield del fatto
    ///   - initialBindings: eventuali binding già esistenti da rispettare
    /// - Returns: bindings aggiornati (inclusi quelli iniziali) oppure `nil` se il match fallisce.
    static func matchSequence(
        items: [PatternTest],
        values: [Value],
        initialBindings: [String: Value] = [:]
    ) -> [String: Value]? {
        var bindings = initialBindings
        let success = backtrack(
            itemIndex: 0,
            valueIndex: 0,
            items: items,
            values: values,
            bindings: &bindings
        )
        return success ? bindings : nil
    }
    
    /// Algoritmo di backtracking portato da factrete.c per gestire le variabili multifield.
    private static func backtrack(
        itemIndex: Int,
        valueIndex: Int,
        items: [PatternTest],
        values: [Value],
        bindings: inout [String: Value]
    ) -> Bool {
        // Caso base: tutti gli item processati -> successo se abbiamo consumato tutti i valori
        if itemIndex >= items.count {
            return valueIndex >= values.count
        }
        
        // Se finiscono i valori ma restano item, ok solo se restano solo mfVariable
        if valueIndex >= values.count {
            for i in itemIndex..<items.count {
                if case .mfVariable(let name) = items[i].kind {
                    bindings[cleanVariableName(name)] = .multifield([])
                } else {
                    return false
                }
            }
            return true
        }
        
        let currentItem = items[itemIndex]
        
        switch currentItem.kind {
        case .constant(let expectedValue):
            guard valueIndex < values.count,
                  values[valueIndex] == expectedValue else {
                return false
            }
            return backtrack(
                itemIndex: itemIndex + 1,
                valueIndex: valueIndex + 1,
                items: items,
                values: values,
                bindings: &bindings
            )
            
        case .variable(let name):
            guard valueIndex < values.count else {
                return false
            }
            let cleanName = cleanVariableName(name)
            let oldBinding = bindings[cleanName]
            // Se la variabile è già bound, il valore deve coincidere
            if let existing = oldBinding, existing != values[valueIndex] {
                return false
            }
            bindings[cleanName] = values[valueIndex]
            
            if backtrack(
                itemIndex: itemIndex + 1,
                valueIndex: valueIndex + 1,
                items: items,
                values: values,
                bindings: &bindings
            ) {
                return true
            }
            
            if let old = oldBinding {
                bindings[cleanName] = old
            } else {
                bindings.removeValue(forKey: cleanName)
            }
            return false
            
        case .mfVariable(let name):
            var minToLeave = 0
            for i in (itemIndex + 1)..<items.count {
                if case .mfVariable = items[i].kind {
                    continue
                } else {
                    minToLeave += 1
                }
            }
            
            let valuesRemaining = values.count - valueIndex
            let maxCanTake = valuesRemaining - minToLeave
            
            for length in stride(from: maxCanTake, through: 0, by: -1) {
                let cleanName = cleanVariableName(name)
                let oldBinding = bindings[cleanName]
                let endIndex = valueIndex + length
                let taken = Array(values[valueIndex..<endIndex])
                let newValue: Value = .multifield(taken)
                
                if let existing = oldBinding, existing != newValue {
                    continue
                }
                
                bindings[cleanName] = newValue
                
                if backtrack(
                    itemIndex: itemIndex + 1,
                    valueIndex: endIndex,
                    items: items,
                    values: values,
                    bindings: &bindings
                ) {
                    return true
                }
                
                if let old = oldBinding {
                    bindings[cleanName] = old
                } else {
                    bindings.removeValue(forKey: cleanName)
                }
            }
            return false
            
        default:
            return false
        }
    }
}
