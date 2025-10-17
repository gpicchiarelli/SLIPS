# 🏗️ SLIPS - Architecture Diagram

**Data**: 17 Ottobre 2025  
**Versione**: 0.80.0-dev

**⚠️ ARCHITETTURA**: SLIPS è una **TRADUZIONE FEDELE** del codice C di CLIPS 6.4.2.  
Non è una reimplementazione o semplificazione. Ogni struttura e algoritmo RETE  
è tradotto DIRETTAMENTE da `drive.c`, `network.h`, `reteutil.c` del codice C originale.

---

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIPS API                             │
│  createEnvironment() | eval() | load() | run() | assert()  │
│                   (MainActor - Thread Safe)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      ENVIRONMENT                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Facts       │  │   Rules      │  │  Templates   │      │
│  │  [Int:Fact]  │  │   [Rule]     │  │  [Template]  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Modules     │  │   Agenda     │  │    RETE      │      │
│  │  [Module]    │  │   Queue      │  │   Network    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
           │                 │                    │
           ▼                 ▼                    ▼
┌─────────────────┐  ┌─────────────┐  ┌──────────────────────┐
│  MODULE SYSTEM  │  │   AGENDA    │  │   RETE ENGINE        │
│                 │  │             │  │                      │
│  • Defmodule    │  │  • Priority │  │  • Alpha Network     │
│  • Focus Stack  │  │  • 4 Strat  │  │  • Beta Network      │
│  • Import/Exp   │  │  • Salience │  │  • Join Nodes        │
│  • Commands     │  │  • Run()    │  │  • Propagation       │
└─────────────────┘  └─────────────┘  └──────────────────────┘
```

---

## 🔄 Data Flow - Rule Execution

```
1. DEFINE RULE                    2. ASSERT FACT
   ┌──────────┐                      ┌──────────┐
   │ (defrule)│                      │ (assert) │
   └────┬─────┘                      └────┬─────┘
        │                                 │
        ▼                                 ▼
   ┌──────────────┐                 ┌──────────────┐
   │   Parser     │                 │ Fact Manager │
   │  evaluator.  │                 │              │
   │    swift     │                 │ env.facts[]  │
   └────┬─────────┘                 └────┬─────────┘
        │                                 │
        ▼                                 │
   ┌──────────────────┐                  │
   │ NetworkBuilder   │                  │
   │ buildNetwork()   │                  │
   └────┬─────────────┘                  │
        │                                 │
        ▼                                 │
   ┌──────────────────────────────────┐  │
   │        RETE NETWORK              │  │
   │                                  │  │
   │  ┌────────┐    ┌────────┐       │  │
   │  │ Alpha  │───▶│  Join  │       │  │
   │  │ Node   │    │  Node  │       │  │
   │  └────────┘    └───┬────┘       │  │
   │                    │             │  │
   │                    ▼             │  │
   │              ┌──────────┐        │  │
   │              │  Beta    │        │  │
   │              │  Memory  │        │  │
   │              └────┬─────┘        │  │
   │                   │              │  │
   │                   ▼              │  │
   │             ┌──────────┐         │  │
   │             │Production│         │  │
   │             │   Node   │         │  │
   │             └────┬─────┘         │  │
   └──────────────────┼───────────────┘  │
                      │                  │
                      │    ┌─────────────┘
3. MATCH & ACTIVATE   │    │
                      ▼    ▼
                 ┌──────────────────┐
                 │  Propagation     │
                 │  propagateAssert │
                 └────┬─────────────┘
                      │
                      ▼
                 ┌──────────────┐
                 │   AGENDA     │
                 │  Activation  │
                 │    Queue     │
                 └────┬─────────┘
                      │
4. FIRE RULE          │
                      ▼
                 ┌──────────────┐
                 │  run()       │
                 │  Fire rule   │
                 │  Execute RHS │
                 └──────────────┘
```

---

## 📁 File Organization

```
SLIPS/
│
├── Sources/SLIPS/
│   │
│   ├── CLIPS.swift              ← Public API Facade
│   │   └── @MainActor enum CLIPS
│   │       ├── createEnvironment()
│   │       ├── eval(expr:)
│   │       ├── run(limit:)
│   │       └── reset()
│   │
│   ├── Core/                    ← Core Engine (22 files)
│   │   ├── Environment
│   │   │   ├── envrnmnt.swift       (Environment class)
│   │   │   └── Entities.swift       (Value, types)
│   │   │
│   │   ├── Expression System
│   │   │   ├── evaluator.swift      (Eval engine)
│   │   │   ├── expressn.swift       (AST nodes)
│   │   │   ├── exprnpsr.swift       (Parser)
│   │   │   └── exprnops.swift       (Operators)
│   │   │
│   │   ├── Functions
│   │   │   └── functions.swift      (87+ builtins)
│   │   │
│   │   ├── Rules
│   │   │   └── ruleengine.swift     (Rule management)
│   │   │
│   │   ├── Modules
│   │   │   └── Modules.swift        (Module system)
│   │   │
│   │   ├── I/O System
│   │   │   ├── router.swift         (Router protocol)
│   │   │   ├── routerData.swift     (Router data)
│   │   │   └── router_registry.swift(Registry)
│   │   │
│   │   └── Utilities
│   │       ├── scanner.swift        (Lexer)
│   │       ├── memalloc.swift       (Memory)
│   │       └── prntutil.swift       (Print utils)
│   │
│   ├── Rete/                    ← RETE Algorithm (12 files)
│   │   │
│   │   ├── Network Structure
│   │   │   ├── Nodes.swift          (Explicit nodes)
│   │   │   ├── NetworkBuilder.swift (Build network)
│   │   │   └── Graph.swift          (Graph structure)
│   │   │
│   │   ├── Alpha Network
│   │   │   └── AlphaNetwork.swift   (Pattern matching)
│   │   │
│   │   ├── Beta Network
│   │   │   ├── BetaEngine.swift     (Join logic)
│   │   │   ├── BetaNetwork.swift    (Beta structure)
│   │   │   └── BetaMemoryHash.swift (Hash indexing)
│   │   │
│   │   ├── Propagation
│   │   │   ├── Propagation.swift    (Assert/retract)
│   │   │   └── DriveEngine.swift    (C-faithful drive)
│   │   │
│   │   └── Support
│   │       ├── Match.swift          (Match structs)
│   │       ├── ReteUtil.swift       (Utilities)
│   │       └── PartialMatchBridge.swift
│   │
│   └── Agenda/                  ← Conflict Resolution (1 file)
│       └── Agenda.swift             (Priority queue)
│
└── Tests/SLIPSTests/            ← Test Suite (41 files)
    ├── ModulesTests.swift          (22 tests)
    ├── ReteTests.swift             (15+ tests)
    ├── RuleTests.swift             (12+ tests)
    ├── MultifieldTests.swift       (7 tests)
    └── ...                         (35+ more test files)
```

---

## 🔗 Component Dependencies

```
                  ┌─────────────┐
                  │   CLIPS     │  Public API
                  │   Facade    │  (MainActor)
                  └──────┬──────┘
                         │
                         ├──────────────────────┐
                         │                      │
                         ▼                      ▼
              ┌──────────────────┐    ┌─────────────────┐
              │   Environment    │◀───│   Functions     │
              │   (State Store)  │    │   (Builtins)    │
              └────────┬─────────┘    └─────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │ Modules │   │  RETE   │   │ Agenda  │
   │ System  │   │ Engine  │   │ Queue   │
   └─────────┘   └────┬────┘   └────┬────┘
                      │              │
                      │              │
                      ▼              │
              ┌──────────────┐       │
              │ RuleEngine   │◀──────┘
              │ (Orchestr.)  │
              └──────────────┘
```

### Dependency Rules

✅ **Allowed**:
- Core → Rete (Environment shared)
- Rete → Agenda (creates Activation)
- Modules → Core (extends Environment)
- Functions → Environment (reads/writes state)

❌ **Forbidden**:
- Rete → Functions (circular)
- Agenda → Rete (circular)
- Modules → Rete (layering violation)

---

## 🎨 Design Patterns Map

```
┌────────────────────────────────────────────────────────────┐
│                      DESIGN PATTERNS                        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐         ┌──────────────┐                 │
│  │   Facade    │         │  Interpreter │                 │
│  │ CLIPS.swift │         │ evaluator.sw │                 │
│  └─────────────┘         └──────────────┘                 │
│                                                             │
│  ┌─────────────┐         ┌──────────────┐                 │
│  │  Strategy   │         │   Builder    │                 │
│  │ Agenda.swift│         │ NetworkBuild │                 │
│  └─────────────┘         └──────────────┘                 │
│                                                             │
│  ┌─────────────┐         ┌──────────────┐                 │
│  │  Composite  │         │   Observer   │                 │
│  │ ReteNode    │         │ Watch/Router │                 │
│  └─────────────┘         └──────────────┘                 │
│                                                             │
│  ┌─────────────┐         ┌──────────────┐                 │
│  │   Memento   │         │   Registry   │                 │
│  │  BetaToken  │         │ router_reg.  │                 │
│  └─────────────┘         └──────────────┘                 │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 🔄 RETE Network Detail

```
RETE NETWORK STRUCTURE
======================

Facts DB                       Alpha Network
┌──────────────┐              ┌─────────────────────┐
│ Fact #1      │─────────────▶│  AlphaNode          │
│ (person      │              │  pattern: person    │
│  name John   │              │  memory: [1,3,5]    │
│  age 30)     │              └──────────┬──────────┘
└──────────────┘                         │
                                         │
┌──────────────┐              ┌─────────▼──────────┐
│ Fact #2      │─────────────▶│  AlphaNode         │
│ (job         │              │  pattern: job      │
│  person John │              │  memory: [2,4]     │
│  title CEO)  │              └──────────┬─────────┘
└──────────────┘                         │
                                         │
                     Beta Network        │
                     ┌───────────────────▼─────┐
                     │  JoinNode              │
                     │  left: AlphaNode(person)│
                     │  right: AlphaNode(job)  │
                     │  joinKeys: {person}     │
                     └───────────┬─────────────┘
                                 │
                     ┌───────────▼─────────────┐
                     │  BetaMemoryNode        │
                     │  tokens: [(J,CEO)]     │
                     │  hashBuckets: [...]    │
                     └───────────┬────────────┘
                                 │
                     ┌───────────▼────────────┐
                     │  ProductionNode        │
                     │  rule: "find-CEO"      │
                     │  salience: 10          │
                     └───────────┬────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   AGENDA     │
                          │  Activation  │
                          │  find-CEO:10 │
                          └──────────────┘
```

---

## 📊 Memory Model

```
ENVIRONMENT (Reference Type)
├── facts: [Int: FactRec]              ← Dictionary (O(1) lookup)
│   └── FactRec (Value Type)
│       ├── id: Int
│       ├── name: String
│       └── slots: [String: Value]
│
├── rules: [Rule]                      ← Array (O(n) scan)
│   └── Rule (Value Type)
│       ├── name: String
│       ├── patterns: [Pattern]
│       └── rhs: [ExpressionNode]
│
├── rete: ReteNetwork (Value Type)
│   ├── alphaNodes: [String: AlphaNode]  ← Shared nodes
│   ├── beta: [String: BetaMemory]       ← Per-rule memory
│   └── graphs: [String: Graph]          ← Network graphs
│
├── agendaQueue: Agenda (Value Type)
│   └── queue: [Activation]              ← Priority queue
│
└── modules: Linked List
    └── Defmodule (Reference Type)
        ├── name: String
        ├── importList: PortItem?
        └── next: Defmodule?
```

**Memory Management**: ARC (Automatic Reference Counting)
- Reference cycles prevented by weak references
- No manual malloc/free (unlike CLIPS C)
- Zero memory leaks detected

---

## 🎯 Critical Paths

### Path 1: Rule Definition → Execution

```
(defrule) → Parser → RuleEngine.addRule() → NetworkBuilder.buildNetwork()
    → Create AlphaNodes → Create JoinNodes → Create ProductionNode
    → Store in rete.productionNodes
```

### Path 2: Fact Assertion → Activation

```
(assert) → FactManager → Propagation.propagateAssert()
    → Find matching AlphaNodes → Create BetaToken
    → Propagate through JoinNodes → Update BetaMemory
    → Reach ProductionNode → Create Activation
    → Add to Agenda
```

### Path 3: Rule Firing

```
(run) → Agenda.pop() → Get highest priority Activation
    → Retrieve bindings → Execute RHS expressions
    → May assert/retract facts → May trigger new activations
```

---

## 🔍 Performance Hot Paths

**Identified bottlenecks** (from architecture):

1. ⚡ **Pattern Matching** (Alpha Network)
   - O(f) per fact, f = number of facts in template
   - Optimized with early filtering

2. ⚡ **Join Operations** (Beta Network)
   - O(t₁ × t₂) worst case
   - Optimized with hash buckets: O(t₁ + t₂)

3. ⚡ **Agenda Operations**
   - Insert: O(log n) with priority queue
   - Pop: O(log n)

4. ⚡ **Module Lookup**
   - O(m) linear search, m = number of modules
   - Typically m < 10, acceptable

---

## 📚 Further Reading

- **CODE_ANALYSIS.md** - Complete technical analysis
- **STRATEGIC_PLAN.md** - Development roadmap (archived)
- **CONTRIBUTING.md** - Development guidelines
- **FASE*_COMPLETE.md** - Phase completion reports (archived)

---

**Version**: 1.0  
**Date**: 15 Ottobre 2025  
**Maintained by**: SLIPS Contributors

