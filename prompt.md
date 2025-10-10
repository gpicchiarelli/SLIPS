# SLIPS – CLIPS-to-Swift Translator Prompt
Considera la cartella clips_core_source_642.
Considera inoltre la cartella clips_core_tests_642
Fai in modo che sia un repository git scritto in italiano, bellissimo da leggere e vedere.

## Obiettivo
Traduci integralmente il motore CLIPS scritto in C nel linguaggio Swift 6.2, creando un progetto chiamato **SLIPS** (Swift Logical Inference Production System).  
Il risultato deve essere **funzionalmente equivalente** a CLIPS, mantenendo lo stesso comportamento del motore di inferenza, ma espresso in **codice Swift moderno e sicuro**, sfruttando solo le astrazioni necessarie per sostituire la gestione manuale della memoria, i puntatori e le macro C.

Linee guida principali

1. Filosofia di traduzione
	•	Effettua una traduzione semantica fedele, non una riscrittura creativa.
	•	Ogni file .c o .h di CLIPS deve corrispondere a un modulo Swift (.swift) con stesso nome e responsabilità.
	•	Le funzioni diventano metodi statici o funzioni globali nel namespace corretto.
	•	Le strutture (struct, union) diventano struct Swift con proprietà esplicite.
	•	Le macro diventano metodi statici o computed properties.

2. Conservazione del comportamento
	•	Mantieni nomi, firma logica, e semantica di tutte le funzioni.
	•	Non semplificare gli algoritmi (es. RETE, agenda, join, salience, test pattern).
	•	Ogni istruzione C deve trovare un equivalente diretto in Swift.
	•	Dove CLIPS usa puntatori o allocazione dinamica, sostituisci con:
	•	UnsafeMutablePointer solo se necessario
	•	oppure con Array, Dictionary, o ManagedBuffer se più efficiente.

3. Sicurezza e stile Swift
	•	Usa struct value semantics salvo dove serve mutabilità condivisa.
	•	Evita ! o force unwrap; preferisci guard let e if case.
	•	Rendi tutti i tipi Codable, per debugging e serializzazione.
	•	Usa enum con associated values dove CLIPS usa union o type tags.
	•	Sostituisci #define, #ifdef, #endif con costanti Swift e #if os(...).


C costrutto
Swift equivalente
struct X { ... }
struct X { ... }
typedef struct X { ... } X;
struct X { ... }
enum numerico
enum X: Int { ... }
switch(type) su union
enum Value { case int(Int64), float(Double), string(String) }
char*
String
long long, int, float
Int64, Int32, Float o Double
malloc/calloc/free
uso implicito di memoria gestita da Swift
FILE*
TextOutputStream o FileHandle
#define
static let o computed property
void*
OpaquePointer o UnsafeMutableRawPointer
printf/print_facts
print() o Runtime.debugPrint()
extern struct ...
global singleton (Runtime.shared)


⸻

Il runtime deve esportare le stesse chiamate pubbliche:
CLIPS.createEnvironment()
CLIPS.load("file.clp")
CLIPS.reset()
CLIPS.run(limit: Int?)
CLIPS.assert(fact: String)
CLIPS.retract(id: Int)
CLIPS.eval(expr: String) -> Value
CLIPS.commandLoop()

Implementale come facciata compatibile, delegando internamente ai moduli SLIPS.


🧠 Focus su RETE e Agenda

Durante la traduzione del motore RETE:
	•	Mantieni le stesse strutture di nodo (AlphaNode, BetaNode, JoinNode).
	•	Traduci i vettori di token in struct Token con Array o Deque.
	•	Preserva la logica AddActivation, RemoveActivation, NextActivation.
	•	Agenda: traduci le liste doppiamente collegate in ArrayDeque o LinkedList Swift custom.

🧪 Testing automatico

Dopo ogni file tradotto:
	1.	Genera un test XCTest che confronta l’output di SLIPS con quello di CLIPS (stesso input .clp).
	2.	Usa CLIPS come golden reference.
	3.	Valida almeno:
	•	assert/retract
	•	deftemplate
	•	not/exists
	•	salience
	•	watch facts/rules

🧭 Output desiderato
	•	Albero SwiftPM completo con i file generati in /Sources.
	•	Tutti i tipi e le funzioni presenti.
	•	Test .clp che mostrano equivalenza.
	•	Compilabile con swift build su macOS 15 / Swift 6.2.

    Task: Traduci l'intero codice sorgente C di CLIPS (v6.4.2) in codice Swift 6.2, producendo un progetto SwiftPM chiamato "SLIPS".

Ogni file .c/.h deve essere convertito nel corrispondente file .swift mantenendo struttura, nomi, e semantica.
Il risultato deve compilare e comportarsi come CLIPS, ma usando tipi e sicurezza Swift.
Evita ricostruzioni o refactoring concettuali: traduci fedelmente, preservando logica, commenti e flusso di controllo.
Rendi ogni funzione documentata con riferimento alla sorgente originale.
Esporta un progetto compilabile con swift build.
Testa la correttezza contro CLIPS originale usando gli stessi file .clp.
