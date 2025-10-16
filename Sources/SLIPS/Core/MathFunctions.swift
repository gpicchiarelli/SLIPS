// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni matematiche estese CLIPS
/// Traduzione semantica da clips_core_source_642/core/emathfun.c
///
/// Funzioni implementate (ref: ExtendedMathFunctionDefinitions, line 111-153):
/// - Trigonometriche: cos, sin, tan, acos, asin, atan, atan2
/// - Iperboliche: cosh, sinh, tanh, acosh, asinh, atanh
/// - Esponenziali: exp, log, log10, sqrt, pow (**)
/// - Utilità: abs, mod, round, pi
/// - Conversioni: deg-rad, rad-deg
public enum MathFunctions {
    /// Registra tutte le funzioni matematiche nell'environment
    /// Ref: ExtendedMathFunctionDefinitions (emathfun.c, line 111)
    public static func registerAll(_ env: inout Environment) {
        // Trigonometriche
        env.functionTable["cos"] = FunctionDefinitionSwift(name: "cos", impl: builtin_cos)
        env.functionTable["sin"] = FunctionDefinitionSwift(name: "sin", impl: builtin_sin)
        env.functionTable["tan"] = FunctionDefinitionSwift(name: "tan", impl: builtin_tan)
        env.functionTable["sec"] = FunctionDefinitionSwift(name: "sec", impl: builtin_sec)
        env.functionTable["csc"] = FunctionDefinitionSwift(name: "csc", impl: builtin_csc)
        env.functionTable["cot"] = FunctionDefinitionSwift(name: "cot", impl: builtin_cot)
        env.functionTable["acos"] = FunctionDefinitionSwift(name: "acos", impl: builtin_acos)
        env.functionTable["asin"] = FunctionDefinitionSwift(name: "asin", impl: builtin_asin)
        env.functionTable["atan"] = FunctionDefinitionSwift(name: "atan", impl: builtin_atan)
        env.functionTable["atan2"] = FunctionDefinitionSwift(name: "atan2", impl: builtin_atan2)
        env.functionTable["asec"] = FunctionDefinitionSwift(name: "asec", impl: builtin_asec)
        env.functionTable["acsc"] = FunctionDefinitionSwift(name: "acsc", impl: builtin_acsc)
        env.functionTable["acot"] = FunctionDefinitionSwift(name: "acot", impl: builtin_acot)
        
        // Iperboliche
        env.functionTable["cosh"] = FunctionDefinitionSwift(name: "cosh", impl: builtin_cosh)
        env.functionTable["sinh"] = FunctionDefinitionSwift(name: "sinh", impl: builtin_sinh)
        env.functionTable["tanh"] = FunctionDefinitionSwift(name: "tanh", impl: builtin_tanh)
        env.functionTable["sech"] = FunctionDefinitionSwift(name: "sech", impl: builtin_sech)
        env.functionTable["csch"] = FunctionDefinitionSwift(name: "csch", impl: builtin_csch)
        env.functionTable["coth"] = FunctionDefinitionSwift(name: "coth", impl: builtin_coth)
        env.functionTable["acosh"] = FunctionDefinitionSwift(name: "acosh", impl: builtin_acosh)
        env.functionTable["asinh"] = FunctionDefinitionSwift(name: "asinh", impl: builtin_asinh)
        env.functionTable["atanh"] = FunctionDefinitionSwift(name: "atanh", impl: builtin_atanh)
        env.functionTable["asech"] = FunctionDefinitionSwift(name: "asech", impl: builtin_asech)
        env.functionTable["acsch"] = FunctionDefinitionSwift(name: "acsch", impl: builtin_acsch)
        env.functionTable["acoth"] = FunctionDefinitionSwift(name: "acoth", impl: builtin_acoth)
        
        // Esponenziali e logaritmi
        env.functionTable["exp"] = FunctionDefinitionSwift(name: "exp", impl: builtin_exp)
        env.functionTable["log"] = FunctionDefinitionSwift(name: "log", impl: builtin_log)
        env.functionTable["log10"] = FunctionDefinitionSwift(name: "log10", impl: builtin_log10)
        env.functionTable["sqrt"] = FunctionDefinitionSwift(name: "sqrt", impl: builtin_sqrt)
        env.functionTable["**"] = FunctionDefinitionSwift(name: "**", impl: builtin_pow)
        
        // Utilità
        env.functionTable["abs"] = FunctionDefinitionSwift(name: "abs", impl: builtin_abs)
        env.functionTable["mod"] = FunctionDefinitionSwift(name: "mod", impl: builtin_mod)
        env.functionTable["round"] = FunctionDefinitionSwift(name: "round", impl: builtin_round)
        env.functionTable["pi"] = FunctionDefinitionSwift(name: "pi", impl: builtin_pi)
        
        // Conversioni angoli
        env.functionTable["deg-rad"] = FunctionDefinitionSwift(name: "deg-rad", impl: builtin_deg_rad)
        env.functionTable["rad-deg"] = FunctionDefinitionSwift(name: "rad-deg", impl: builtin_rad_deg)
    }
}

// MARK: - Costanti

private let PI = Double.pi
private let SMALLEST_ALLOWED_NUMBER = 1e-15

// MARK: - Helper: Estrazione numero

/// Estrae un numero (int o float) da un Value e lo converte in Double
private func extractNumber(_ value: Value, functionName: String) throws -> Double {
    switch value {
    case .int(let i):
        return Double(i)
    case .float(let d):
        return d
    default:
        throw EvalError.typeMismatch(functionName, expected: "number", got: String(describing: value))
    }
}

// MARK: - Trigonometriche

/// (cos <number>) - Coseno
/// Ref: CosFunction (emathfun.c, line 163)
public func builtin_cos(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("cos", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "cos")
    return .float(cos(num))
}

/// (sin <number>) - Seno
/// Ref: SinFunction (emathfun.c, line 178)
public func builtin_sin(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("sin", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "sin")
    return .float(sin(num))
}

/// (tan <number>) - Tangente
/// Ref: TanFunction (emathfun.c, line 193)
public func builtin_tan(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("tan", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "tan")
    return .float(tan(num))
}

/// (acos <number>) - Arcocoseno
/// Ref: AcosFunction (emathfun.c, line 263)
public func builtin_acos(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acos", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acos")
    
    // Dominio: [-1, 1]
    guard num >= -1.0 && num <= 1.0 else {
        throw EvalError.runtime("acos: domain error - argument must be in [-1, 1]")
    }
    
    return .float(acos(num))
}

/// (asin <number>) - Arcoseno
/// Ref: AsinFunction (emathfun.c, line 283)
public func builtin_asin(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("asin", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "asin")
    
    // Dominio: [-1, 1]
    guard num >= -1.0 && num <= 1.0 else {
        throw EvalError.runtime("asin: domain error - argument must be in [-1, 1]")
    }
    
    return .float(asin(num))
}

/// (atan <number>) - Arcotangente
/// Ref: AtanFunction (emathfun.c, line 303)
public func builtin_atan(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("atan", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "atan")
    return .float(atan(num))
}

/// (atan2 <y> <x>) - Arcotangente a due argomenti
/// Ref: Atan2Function (emathfun.c, line 318)
public func builtin_atan2(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("atan2", expected: 2, got: args.count)
    }
    let y = try extractNumber(args[0], functionName: "atan2")
    let x = try extractNumber(args[1], functionName: "atan2")
    return .float(atan2(y, x))
}

// MARK: - Iperboliche

/// (cosh <number>) - Coseno iperbolico
/// Ref: CoshFunction (emathfun.c, line 413)
public func builtin_cosh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("cosh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "cosh")
    return .float(cosh(num))
}

/// (sinh <number>) - Seno iperbolico
/// Ref: SinhFunction (emathfun.c, line 428)
public func builtin_sinh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("sinh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "sinh")
    return .float(sinh(num))
}

/// (tanh <number>) - Tangente iperbolica
/// Ref: TanhFunction (emathfun.c, line 443)
public func builtin_tanh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("tanh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "tanh")
    return .float(tanh(num))
}

/// (acosh <number>) - Arco coseno iperbolico
/// Ref: AcoshFunction (emathfun.c, line 493)
public func builtin_acosh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acosh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acosh")
    
    // Dominio: [1, +∞)
    guard num >= 1.0 else {
        throw EvalError.runtime("acosh: domain error - argument must be >= 1")
    }
    
    return .float(acosh(num))
}

/// (asinh <number>) - Arco seno iperbolico
/// Ref: AsinhFunction (emathfun.c, line 513)
public func builtin_asinh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("asinh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "asinh")
    return .float(asinh(num))
}

/// (atanh <number>) - Arco tangente iperbolica
/// Ref: AtanhFunction (emathfun.c, line 528)
public func builtin_atanh(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("atanh", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "atanh")
    
    // Dominio: (-1, 1)
    guard num > -1.0 && num < 1.0 else {
        throw EvalError.runtime("atanh: domain error - argument must be in (-1, 1)")
    }
    
    return .float(atanh(num))
}

// MARK: - Esponenziali e Logaritmi

/// (exp <number>) - Esponenziale (e^x)
/// Ref: ExpFunction (emathfun.c, line 598)
public func builtin_exp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("exp", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "exp")
    let result = exp(num)
    
    // Controlla overflow
    guard !result.isInfinite else {
        throw EvalError.runtime("exp: overflow error")
    }
    
    return .float(result)
}

/// (log <number>) - Logaritmo naturale (base e)
/// Ref: LogFunction (emathfun.c, line 621)
public func builtin_log(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("log", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "log")
    
    // Dominio: (0, +∞)
    guard num > 0.0 else {
        throw EvalError.runtime("log: domain error - argument must be > 0")
    }
    
    return .float(log(num))
}

/// (log10 <number>) - Logaritmo base 10
/// Ref: Log10Function (emathfun.c, line 641)
public func builtin_log10(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("log10", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "log10")
    
    // Dominio: (0, +∞)
    guard num > 0.0 else {
        throw EvalError.runtime("log10: domain error - argument must be > 0")
    }
    
    return .float(log10(num))
}

/// (sqrt <number>) - Radice quadrata
/// Ref: SqrtFunction (emathfun.c, line 661)
public func builtin_sqrt(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("sqrt", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "sqrt")
    
    // Dominio: [0, +∞)
    guard num >= 0.0 else {
        throw EvalError.runtime("sqrt: domain error - argument must be >= 0")
    }
    
    return .float(sqrt(num))
}

/// (** <base> <exponent>) - Potenza (base^exponent)
/// Ref: PowFunction (emathfun.c, line 719)
public func builtin_pow(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("**", expected: 2, got: args.count)
    }
    let base = try extractNumber(args[0], functionName: "**")
    let exponent = try extractNumber(args[1], functionName: "**")
    
    let result = pow(base, exponent)
    
    // Controlla errori
    guard !result.isNaN && !result.isInfinite else {
        throw EvalError.runtime("**: domain or overflow error")
    }
    
    return .float(result)
}

// MARK: - Utilità

/// (abs <number>) - Valore assoluto
/// Ref: Built-in nella maggior parte delle implementazioni CLIPS
public func builtin_abs(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("abs", expected: 1, got: args.count)
    }
    
    switch args[0] {
    case .int(let i):
        return .int(abs(i))
    case .float(let d):
        return .float(abs(d))
    default:
        throw EvalError.typeMismatch("abs", expected: "number", got: String(describing: args[0]))
    }
}

/// (mod <dividend> <divisor>) - Modulo
/// Ref: ModFunction (emathfun.c, line 754)
public func builtin_mod(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("mod", expected: 2, got: args.count)
    }
    
    let dividend = try extractNumber(args[0], functionName: "mod")
    let divisor = try extractNumber(args[1], functionName: "mod")
    
    // Divisore non può essere zero
    guard abs(divisor) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("mod: division by zero")
    }
    
    // CLIPS ritorna un valore con lo stesso segno del dividendo
    let result = dividend.truncatingRemainder(dividingBy: divisor)
    
    return .float(result)
}

/// (round <number>) - Arrotondamento
/// Ref: RoundFunction (emathfun.c, line 791)
///
/// Comportamento CLIPS 6.40+:
/// - Arrotonda all'intero più vicino
/// - Se esattamente a metà (x.5), arrotonda lontano da zero
public func builtin_round(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("round", expected: 1, got: args.count)
    }
    
    let num = try extractNumber(args[0], functionName: "round")
    
    // Arrotondamento "away from zero" per valori .5
    let rounded: Int64
    if num >= 0 {
        rounded = Int64(floor(num + 0.5))
    } else {
        rounded = Int64(ceil(num - 0.5))
    }
    
    return .int(rounded)
}

/// (pi) - Costante π
/// Ref: PiFunction (emathfun.c, line 681)
public func builtin_pi(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty else {
        throw EvalError.wrongArgCount("pi", expected: 0, got: args.count)
    }
    return .float(PI)
}

// MARK: - Conversioni Angoli

/// (deg-rad <degrees>) - Converte gradi in radianti
/// Ref: DegRadFunction (emathfun.c, line 696)
public func builtin_deg_rad(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("deg-rad", expected: 1, got: args.count)
    }
    let degrees = try extractNumber(args[0], functionName: "deg-rad")
    let radians = degrees * PI / 180.0
    return .float(radians)
}

/// (rad-deg <radians>) - Converte radianti in gradi
/// Ref: RadDegFunction (emathfun.c, line 711)
public func builtin_rad_deg(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("rad-deg", expected: 1, got: args.count)
    }
    let radians = try extractNumber(args[0], functionName: "rad-deg")
    let degrees = radians * 180.0 / PI
    return .float(degrees)
}

// MARK: - Trigonometriche Secondarie

/// (sec <number>) - Secante (1/cos)
/// Ref: SecFunction (emathfun.c, line 208)
public func builtin_sec(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("sec", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "sec")
    let cosVal = cos(num)
    
    guard abs(cosVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("sec: singularity error - cos(x) too close to zero")
    }
    
    return .float(1.0 / cosVal)
}

/// (csc <number>) - Cosecante (1/sin)
/// Ref: CscFunction (emathfun.c, line 228)
public func builtin_csc(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("csc", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "csc")
    let sinVal = sin(num)
    
    guard abs(sinVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("csc: singularity error - sin(x) too close to zero")
    }
    
    return .float(1.0 / sinVal)
}

/// (cot <number>) - Cotangente (1/tan)
/// Ref: CotFunction (emathfun.c, line 248)
public func builtin_cot(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("cot", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "cot")
    let tanVal = tan(num)
    
    guard abs(tanVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("cot: singularity error - tan(x) too close to zero")
    }
    
    return .float(1.0 / tanVal)
}

/// (asec <number>) - Arco secante
/// Ref: AsecFunction (emathfun.c, line 333)
public func builtin_asec(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("asec", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "asec")
    
    guard abs(num) >= 1.0 else {
        throw EvalError.runtime("asec: domain error - |x| must be >= 1")
    }
    
    return .float(acos(1.0 / num))
}

/// (acsc <number>) - Arco cosecante
/// Ref: AcscFunction (emathfun.c, line 353)
public func builtin_acsc(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acsc", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acsc")
    
    guard abs(num) >= 1.0 else {
        throw EvalError.runtime("acsc: domain error - |x| must be >= 1")
    }
    
    return .float(asin(1.0 / num))
}

/// (acot <number>) - Arco cotangente
/// Ref: AcotFunction (emathfun.c, line 373)
public func builtin_acot(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acot", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acot")
    return .float(atan(1.0 / num))
}

// MARK: - Iperboliche Secondarie

/// (sech <number>) - Secante iperbolica (1/cosh)
/// Ref: SechFunction (emathfun.c, line 458)
public func builtin_sech(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("sech", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "sech")
    let coshVal = cosh(num)
    
    guard abs(coshVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("sech: singularity error")
    }
    
    return .float(1.0 / coshVal)
}

/// (csch <number>) - Cosecante iperbolica (1/sinh)
/// Ref: CschFunction (emathfun.c, line 473)
public func builtin_csch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("csch", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "csch")
    let sinhVal = sinh(num)
    
    guard abs(sinhVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("csch: singularity error - sinh(x) too close to zero")
    }
    
    return .float(1.0 / sinhVal)
}

/// (coth <number>) - Cotangente iperbolica (1/tanh)
/// Ref: CothFunction (emathfun.c, line 478)
public func builtin_coth(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("coth", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "coth")
    let tanhVal = tanh(num)
    
    guard abs(tanhVal) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("coth: singularity error - tanh(x) too close to zero")
    }
    
    return .float(1.0 / tanhVal)
}

/// (asech <number>) - Arco secante iperbolica
/// Ref: AsechFunction (emathfun.c, line 533)
public func builtin_asech(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("asech", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "asech")
    
    guard num > 0.0 && num <= 1.0 else {
        throw EvalError.runtime("asech: domain error - argument must be in (0, 1]")
    }
    
    return .float(acosh(1.0 / num))
}

/// (acsch <number>) - Arco cosecante iperbolica
/// Ref: AcschFunction (emathfun.c, line 553)
public func builtin_acsch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acsch", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acsch")
    
    guard abs(num) > SMALLEST_ALLOWED_NUMBER else {
        throw EvalError.runtime("acsch: singularity error - argument too close to zero")
    }
    
    return .float(asinh(1.0 / num))
}

/// (acoth <number>) - Arco cotangente iperbolica
/// Ref: AcothFunction (emathfun.c, line 573)
public func builtin_acoth(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("acoth", expected: 1, got: args.count)
    }
    let num = try extractNumber(args[0], functionName: "acoth")
    
    guard abs(num) > 1.0 else {
        throw EvalError.runtime("acoth: domain error - |x| must be > 1")
    }
    
    return .float(atanh(1.0 / num))
}

