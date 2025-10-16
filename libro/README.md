# 📚 SLIPS - Libro Accademico

## Swift Language Implementation of Production Systems
### Teoria, Implementazione e Guida Tecnica

Un volume accademico completo sul progetto SLIPS: dalla teoria formale dei sistemi a produzione all'implementazione pratica in Swift 6.2.

---

## 📖 Informazioni sul Libro

- **Titolo**: SLIPS - Swift Language Implementation of Production Systems
- **Sottotitolo**: Teoria, Implementazione e Guida Tecnica
- **Autori**: Contributori SLIPS
- **Edizione**: Prima edizione, Ottobre 2025
- **Licenza**: Creative Commons BY-SA 4.0
- **Pagine**: ~400 (stimate)
- **Lingua**: Italiano
- **Formato**: PDF (da LaTeX)

---

## 🎯 Pubblico

Il libro è rivolto a:

- **Studenti** di informatica (AI, sistemi esperti)
- **Ricercatori** in AI simbolica
- **Sviluppatori** Swift interessati a sistemi complessi
- **Ingegneri** che traducono codice legacy
- **Architetti software** interessati a design patterns

---

## 📚 Contenuto

### Parte I: Fondamenti Teorici (4 capitoli)
- Introduzione e contesto storico
- Sistemi a produzione formali
- Logica proposizionale e del primo ordine
- Rappresentazione della conoscenza

### Parte II: L'Algoritmo RETE (6 capitoli)
- Pattern matching e problema della complessità
- Introduzione a RETE
- Alpha network
- Beta network e join
- Analisi di complessità e dimostrazione correttezza
- Ottimizzazioni avanzate

### Parte III: Architettura CLIPS (5 capitoli)
- Overview CLIPS C
- Strutture dati fondamentali
- Gestione della memoria
- Sistema di agenda
- Moduli e visibilità

### Parte IV: Implementazione SLIPS (7 capitoli)
- Architettura generale ✅
- Core engine
- RETE in Swift
- Agenda e conflict resolution
- Sistema di moduli ✅
- Pattern matching avanzato
- Testing e validazione ✅

### Parte V: Guida allo Sviluppo (5 capitoli)
- Estendere SLIPS
- Best practices ✅
- Performance e profiling
- Debugging
- Direzioni future

### Appendici (4 appendici)
- A: API Reference completa ✅
- B: Catalogo built-in functions ✅
- C: Esempi e casi di studio ✅
- D: Benchmark di performance ✅

---

## 🔧 Compilazione

### Requisiti

- LaTeX distribution (TeX Live, MiKTeX, o MacTeX)
- pdflatex
- biber (per bibliografia)
- makeindex (per indice analitico)

### Installazione su macOS

```bash
brew install --cask mactex
```

### Installazione su Linux

```bash
# Ubuntu/Debian
sudo apt-get install texlive-full

# Fedora
sudo dnf install texlive-scheme-full
```

### Compilazione

```bash
# Compilazione completa (consigliata)
make

# Compilazione rapida (senza bibliografia/indice)
make quick

# Pulizia file intermedi
make clean

# Pulizia completa
make distclean

# Visualizza PDF
make view
```

### Compilazione Manuale

```bash
pdflatex main.tex
biber main
makeindex main
pdflatex main.tex
pdflatex main.tex
```

---

## 📂 Struttura Directory

```
libro/
├── main.tex                  # File principale
├── bibliografia.bib          # Bibliografia BibTeX
├── Makefile                  # Build automation
├── README.md                 # Questo file
│
├── capitoli/                 # Capitoli del libro
│   ├── 01_introduzione.tex           ✅ Completo
│   ├── 02_sistemi_produzione.tex     ✅ Completo
│   ├── 03_logica_formale.tex         ⏳ Stub
│   ├── ...                           ⏳ 18 stub
│   ├── 16_slips_architettura.tex     ✅ Completo
│   ├── 20_slips_moduli.tex           ✅ Completo
│   ├── 22_slips_testing.tex          ✅ Completo
│   ├── 24_best_practices.tex         ✅ Completo
│   ├── appendice_a_api.tex           ✅ Completo
│   └── appendice_d_benchmark.tex     ✅ Completo
│
└── figure/                   # Immagini (se necessarie)
```

---

## 📊 Stato Completamento

| Parte | Capitoli | Completati | Stato |
|-------|----------|------------|-------|
| Parte I | 4 | 2 | 50% |
| Parte II | 6 | 1 | 17% |
| Parte III | 5 | 0 | 0% |
| Parte IV | 7 | 4 | 57% |
| Parte V | 5 | 1 | 20% |
| Appendici | 4 | 4 | 100% |
| **Totale** | **31** | **12** | **39%** |

**Nota**: Gli stub permettono compilazione completa. I capitoli completati (~120 pagine) coprono le parti più critiche.

---

## ✅ Capitoli Completati (Dettaglio)

### 📖 Capitolo 1: Introduzione (15 pagine)
- Motivazione e contesto storico
- Problema del matching
- CLIPS e SLIPS overview
- Struttura del libro
- Notazione e convenzioni

### 📖 Capitolo 2: Sistemi a Produzione (25 pagine)
- Definizione formale
- Ciclo recognize-act
- Pattern matching e unificazione
- Semantica operazionale
- Conditional elements (NOT, EXISTS, OR)
- Confronti con altri paradigmi

### 📖 Capitolo 6: Introduzione RETE (30 pagine)
- Problema efficienza
- Intuizione di Forgy
- Architettura rete
- Alpha, Beta, Join nodes
- Propagazione incrementale
- Analisi complessità preliminare

### 📖 Capitolo 16: Architettura SLIPS (35 pagine)
- Principi di progettazione
- Mapping C → Swift completo
- Environment design
- Value type con enum
- DriveEngine fedele a C
- NetworkBuilder
- Metriche qualità

### 📖 Capitolo 20: Moduli in SLIPS (25 pagine)
- Teoria moduli e focus
- Defmodule implementation
- Import/export resolution
- Focus stack dettagliato
- Comandi moduli
- Caso di studio medico
- Test suite (22 test)

### 📖 Capitolo 22: Testing (22 pagine)
- Filosofia TDD
- 91 test suite
- Coverage analysis
- Golden file testing
- Mutation testing
- CI/CD workflow
- Debugging techniques

### 📖 Capitolo 24: Best Practices (18 pagine)
- Progettazione regole efficienti
- Pattern ordering
- Memory management
- Modularizzazione
- Performance optimization
- Code style
- Contribution workflow

### 📖 Appendici (20 pagine totali)
- API Reference completa
- Catalogo 87+ built-in
- Esempi completi
- Benchmark performance

**Totale Completato**: ~190 pagine di contenuto accademico denso

---

## 🚀 Come Estendere il Libro

### Aggiungere Capitolo

1. Crea file: `capitoli/XX_nome_capitolo.tex`
2. Aggiungi `\input{capitoli/XX_nome_capitolo}` in `main.tex`
3. Compila con `make`

### Template Capitolo

```latex
% Capitolo N: Titolo

\chapter{Titolo Capitolo}
\label{cap:label}

\section{Introduzione}

Contenuto...

\section{Teoria}

\begin{definizione}[Nome]
...
\end{definizione}

\section{Implementazione}

\begin{lstlisting}[language=Swift]
// Codice Swift
\end{lstlisting}

\section{Esempi}

\begin{esempio}[Descrizione]
...
\end{esempio}

\section{Conclusioni}

\begin{successbox}[Punti Chiave]
...
\end{successbox}
```

---

## 📝 Contribuire

I contributi al libro sono benvenuti:

- **Correzioni**: typo, errori tecnici
- **Miglioramenti**: chiarezza, esempi aggiuntivi
- **Completamento stub**: implementare capitoli pianificati
- **Traduzioni**: versione inglese

### Processo

1. Fork repository SLIPS
2. Branch: `docs/libro/nome-modifica`
3. Modifica file `.tex`
4. Test: `make && make view`
5. Pull Request con descrizione

---

## 📜 Licenza

**Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**

Sei libero di:
- ✅ **Condividere** — copiare e ridistribuire
- ✅ **Adattare** — remix, modificare, costruire

Alle seguenti condizioni:
- **Attribuzione** — credito appropriato
- **ShareAlike** — stessa licenza per opere derivate

Licenza completa: http://creativecommons.org/licenses/by-sa/4.0/

**Codice sorgente SLIPS**: MIT License (separata)

---

## 🔗 Link Utili

- **Repository SLIPS**: https://github.com/gpicchiarelli/SLIPS
- **Documentazione Online**: https://gpicchiarelli.github.io/SLIPS/
- **CLIPS Ufficiale**: https://www.clipsrules.net/
- **Swift**: https://swift.org/

---

## 📧 Contatti

- **Issues**: https://github.com/gpicchiarelli/SLIPS/issues
- **Discussions**: https://github.com/gpicchiarelli/SLIPS/discussions
- **Pull Requests**: Benvenute!

---

## 🙏 Ringraziamenti

- **Charles L. Forgy** - Algoritmo RETE
- **Gary Riley & NASA** - CLIPS
- **Chris Lattner & Apple** - Swift
- **Contributori SLIPS** - Codice e review
- **Reviewer del libro** - Feedback preziosi

---

**Versione**: 1.0 (Prima Edizione)  
**Data**: Ottobre 2025  
**Maintainer**: Contributori SLIPS

