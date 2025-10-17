// SortFunctions.swift
// Traduzione di clips_core_source_642/core/sortfun.c
//
// Funzioni di ordinamento (sort) con merge sort
// File originale: sortfun.c (CLIPS 6.40)
// Programmatore principale: Gary D. Riley
//
// Funzioni tradotte:
// - sort          → builtin_sort
// - MergeSort     → mergeSort
// - DoMergeSort   → doMergeSort

import Foundation

// MARK: - Sort Functions

/// Tipo per funzione di confronto personalizzata
/// Ritorna true se i due elementi devono essere scambiati
typealias SwapFunction = (inout Environment, Value, Value) throws -> Bool

/// Implementazione della funzione sort
/// Sintassi CLIPS: (sort <funzione-confronto> <arg1> <arg2> ... <argN>)
///
/// Esempio:
/// ```
/// (sort > 3 1 4 1 5 9 2 6)  ; → (9 6 5 4 3 2 1 1)
/// (sort < 3 1 4 1 5 9 2 6)  ; → (1 1 2 3 4 5 6 9)
/// ```
///
/// - Parameters:
///   - env: Environment corrente
///   - args: Lista di argomenti - primo è nome funzione di confronto, resto sono elementi da ordinare
/// - Returns: Multifield con elementi ordinati
func builtin_sort(_ env: inout Environment, args: [Value]) throws -> Value {
    guard args.count >= 1 else {
        throw EvalError.runtime("sort richiede almeno 1 argomento (funzione di confronto)")
    }
    
    // Primo argomento: nome funzione di confronto
    guard case .symbol(let functionName) = args[0] else {
        throw EvalError.runtime("Il primo argomento di sort deve essere un nome di funzione")
    }
    
    // Verifica che la funzione esista
    guard env.functionTable.keys.contains(functionName) else {
        throw EvalError.runtime("Funzione '\(functionName)' non trovata")
    }
    
    // Se non ci sono elementi da ordinare, ritorna multifield vuoto
    if args.count == 1 {
        return .multifield([])
    }
    
    // Estrai tutti gli elementi da ordinare (argomenti 2+)
    var itemsToSort: [Value] = []
    
    for i in 1..<args.count {
        let arg = args[i]
        if case .multifield(let items) = arg {
            // Se è un multifield, espandi i suoi elementi
            itemsToSort.append(contentsOf: items)
        } else {
            // Altrimenti aggiungi l'elemento singolo
            itemsToSort.append(arg)
        }
    }
    
    // Se non ci sono elementi, ritorna multifield vuoto
    if itemsToSort.isEmpty {
        return .multifield([])
    }
    
    // Crea la funzione di confronto che usa la funzione CLIPS specificata
    // NOTA: In CLIPS sort, la funzione di confronto ritorna TRUE se i due elementi
    // sono nell'ordine CORRETTO (non necessitano di scambio), contrariamente alla
    // convenzione C dove swapFunction indica se scambiare.
    let swapFunction: SwapFunction = { env, item1, item2 in
        // Chiama la funzione di confronto CLIPS con i due elementi
        let result = try evaluateFunction(
            name: functionName,
            args: [item1, item2],
            env: &env
        )
        
        // Se la funzione ritorna FALSE, significa che item1 va DOPO item2,
        // quindi scambiare (prendi item2)
        // Se ritorna TRUE, significa che item1 va PRIMA di item2,
        // quindi NON scambiare (prendi item1)
        
        switch result {
        case .boolean(let b):
            return !b  // Inverti: TRUE -> non scambiare, FALSE -> scambia
        case .symbol(let sym):
            // FALSE/nil -> scambia, TRUE -> non scambiare
            return sym == "FALSE" || sym == "nil"
        case .none:
            return true  // nil -> scambia
        default:
            return false  // Per sicurezza, non scambiare
        }
    }
    
    // Esegui merge sort
    let sorted = try mergeSort(
        env: &env,
        items: itemsToSort,
        swapFunction: swapFunction
    )
    
    return .multifield(sorted)
}

/// Merge Sort: ordina una lista usando un algoritmo merge sort
///
/// - Parameters:
///   - env: Environment corrente
///   - items: Array di Value da ordinare
///   - swapFunction: Funzione che determina se due elementi vanno scambiati
/// - Returns: Array ordinato di Value
func mergeSort(
    env: inout Environment,
    items: [Value],
    swapFunction: SwapFunction
) throws -> [Value] {
    let listSize = items.count
    
    // Caso base: lista vuota o con 1 elemento
    if listSize <= 1 {
        return items
    }
    
    // Crea una copia mutabile per l'ordinamento
    var theList = items
    
    // Crea storage temporaneo per il merge
    var tempList = Array(repeating: Value.symbol("nil"), count: listSize)
    
    // Dividi in due metà e ordina
    let middle = (listSize + 1) / 2
    
    try doMergeSort(
        env: &env,
        theList: &theList,
        tempList: &tempList,
        s1: 0,
        e1: middle - 1,
        s2: middle,
        e2: listSize - 1,
        swapFunction: swapFunction
    )
    
    return theList
}

/// Driver ricorsivo per merge sort
///
/// Ordina due sottoaree [s1...e1] e [s2...e2] e poi le fonde insieme
///
/// - Parameters:
///   - env: Environment corrente
///   - theList: Array da ordinare (modificato in-place)
///   - tempList: Array temporaneo per il merge
///   - s1: Inizio prima sottoarea
///   - e1: Fine prima sottoarea
///   - s2: Inizio seconda sottoarea
///   - e2: Fine seconda sottoarea
///   - swapFunction: Funzione di confronto
private func doMergeSort(
    env: inout Environment,
    theList: inout [Value],
    tempList: inout [Value],
    s1: Int,
    e1: Int,
    s2: Int,
    e2: Int,
    swapFunction: SwapFunction
) throws {
    
    // ===================================
    // Ordina la prima sottoarea ricorsivamente
    // ===================================
    
    if s1 == e1 {
        // Un solo elemento, già ordinato
    }
    else if s1 + 1 == e1 {
        // Due elementi: confronta e scambia se necessario
        if try swapFunction(&env, theList[s1], theList[e1]) {
            theList.swapAt(s1, e1)
        }
    }
    else {
        // Più di due elementi: dividi e ordina ricorsivamente
        let size = e1 - s1 + 1
        let middle = s1 + (size + 1) / 2
        try doMergeSort(
            env: &env,
            theList: &theList,
            tempList: &tempList,
            s1: s1,
            e1: middle - 1,
            s2: middle,
            e2: e1,
            swapFunction: swapFunction
        )
    }
    
    // ===================================
    // Ordina la seconda sottoarea ricorsivamente
    // ===================================
    
    if s2 == e2 {
        // Un solo elemento, già ordinato
    }
    else if s2 + 1 == e2 {
        // Due elementi: confronta e scambia se necessario
        if try swapFunction(&env, theList[s2], theList[e2]) {
            theList.swapAt(s2, e2)
        }
    }
    else {
        // Più di due elementi: dividi e ordina ricorsivamente
        let size = e2 - s2 + 1
        let middle = s2 + (size + 1) / 2
        try doMergeSort(
            env: &env,
            theList: &theList,
            tempList: &tempList,
            s1: s2,
            e1: middle - 1,
            s2: middle,
            e2: e2,
            swapFunction: swapFunction
        )
    }
    
    // ===================================
    // Fondi le due sottoaree ordinate
    // ===================================
    
    var c1 = s1  // cursore prima area
    var c2 = s2  // cursore seconda area
    var mergePoint = s1
    
    while mergePoint <= e2 {
        if c1 > e1 {
            // Prima area esaurita, copia dalla seconda
            tempList[mergePoint] = theList[c2]
            c2 += 1
            mergePoint += 1
        }
        else if c2 > e2 {
            // Seconda area esaurita, copia dalla prima
            tempList[mergePoint] = theList[c1]
            c1 += 1
            mergePoint += 1
        }
        else if try swapFunction(&env, theList[c1], theList[c2]) {
            // L'elemento di c1 va dopo c2, prendi c2
            tempList[mergePoint] = theList[c2]
            c2 += 1
            mergePoint += 1
        }
        else {
            // L'elemento di c1 va prima (o uguale) di c2, prendi c1
            tempList[mergePoint] = theList[c1]
            c1 += 1
            mergePoint += 1
        }
    }
    
    // ===================================
    // Copia il risultato fuso nell'array originale
    // ===================================
    
    for i in s1...e2 {
        theList[i] = tempList[i]
    }
}

// MARK: - Helper per Valutazione Funzioni

/// Valuta una funzione CLIPS con argomenti dati
///
/// - Parameters:
///   - name: Nome della funzione
///   - args: Argomenti da passare
///   - env: Environment
/// - Returns: Risultato della funzione
private func evaluateFunction(
    name: String,
    args: [Value],
    env: inout Environment
) throws -> Value {
    // Cerca la funzione
    guard let functionDef = env.functionTable[name] else {
        throw EvalError.runtime("Funzione '\(name)' non trovata")
    }
    
    // Valuta la funzione con gli argomenti
    return try functionDef.impl(&env, args)
}

