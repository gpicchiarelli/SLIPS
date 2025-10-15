# 🤝 Come Contribuire al Libro SLIPS

## Tipologie di Contributi

Accettiamo contributi di vario tipo:

### 1. Correzioni

- **Typo e refusi**: Errori ortografici, grammaticali
- **Errori tecnici**: Formule sbagliate, codice errato
- **Link rotti**: URL non funzionanti

**Processo**: PR con modifiche, indicare pagina/sezione

### 2. Miglioramenti

- **Chiarezza**: Riformulazioni più chiare
- **Esempi**: Aggiunta di esempi pratici
- **Figure**: Diagrammi esplicativi
- **Esercizi**: Problemi per il lettore

**Processo**: Proposta via issue, poi PR se approvata

### 3. Completamento Capitoli

- **Stub da completare**: 19 capitoli pianificati ma stub
- **Espansioni**: Approfondimenti di capitoli esistenti
- **Nuove sezioni**: Aggiunte a capitoli

**Processo**: 
1. Claim issue del capitolo
2. Bozza in branch dedicato
3. Review da maintainer
4. Iterazione fino ad approvazione
5. Merge

### 4. Traduzioni

- **Inglese**: Versione EN del libro
- **Altre lingue**: Benvenute

**Processo**: Fork repo, traduci, mantieni struttura

---

## 📝 Linee Guida Stilistiche

### Tono e Registro

- **Formale accademico**: Libro non è tutorial informale
- **Terza persona**: Evitare "tu" o "io"
- **Impersonale**: "Si osserva che..." non "Osserviamo che..."
- **Oggettivo**: Evitare opinioni non supportate

### Formattazione LaTeX

#### Struttura Capitolo

```latex
\chapter{Titolo}
\label{cap:label_minuscolo}

\section{Sezione Principale}
Testo introduttivo...

\subsection{Sottosezione}
Contenuto...

\subsubsection{Dettaglio}
Approfondimento...
```

#### Definizioni e Teoremi

```latex
\begin{definizione}[Nome Definizione]
\label{def:nome}
Testo della definizione...
\end{definizione}

\begin{teorema}[Nome Teorema]
\label{thm:nome}
Enunciato...
\end{teorema}

\begin{proof}
Dimostrazione...
\end{proof}
```

#### Codice

```latex
% Swift
\begin{lstlisting}[language=Swift]
func example() {
    // Codice Swift
}
\end{lstlisting}

% CLIPS
\begin{lstlisting}[language=CLIPS]
(defrule example
  (pattern)
  =>
  (action))
\end{lstlisting}

% C
\begin{lstlisting}[language=C]
void example() {
    // Codice C
}
\end{lstlisting}
```

#### Equazioni

```latex
% Inline
Il costo è $O(n \cdot m)$ nel caso peggiore.

% Display
\begin{equation}
\label{eq:nome}
T(n) = O(n \log n)
\end{equation}

% Multi-linea
\begin{align}
a &= b + c\\
d &= e \cdot f
\end{align}
```

#### Figure

```latex
\begin{figure}[h]
\centering
\begin{tikzpicture}
% Codice TikZ
\end{tikzpicture}
\caption{Descrizione figura}
\label{fig:nome}
\end{figure}
```

### Terminologia

- **Consistente**: Usa sempre stessi termini
  - "working memory" (non "memoria di lavoro")
  - "pattern matching" (non "confronto di pattern")
  - "alpha node" (non "nodo alpha")

- **Italiano vs Inglese**:
  - Termini tecnici consolidati: inglese (RETE, pattern matching)
  - Spiegazioni e testo: italiano
  - Codice: commenti in inglese (standard Swift)

### Riferimenti

#### Citazioni Bibliografiche

```latex
Come dimostrato da Forgy \cite{forgy1982rete}, l'algoritmo RETE...
```

#### Riferimenti Interni

```latex
Come visto nel Capitolo \ref{cap:rete_intro}...
L'equazione \eqref{eq:complexity} mostra che...
Vedere Figura \ref{fig:architecture}...
```

#### Riferimenti Codice C

Nei commenti Swift nel testo:

```latex
Port fedele di \texttt{struct defmodule} (moduldef.h linee 138--145)
```

---

## 🔍 Code Review Checklist

Prima di PR, verifica:

- [ ] Compila senza errori: `make`
- [ ] No warning LaTeX critici
- [ ] Spell check eseguito
- [ ] Formule numerate e referenziate
- [ ] Codice testato e funzionante
- [ ] Riferimenti bibliografici corretti
- [ ] Caption per figure/tabelle
- [ ] Label univoche (`cap:`, `sec:`, `fig:`, `tab:`, `eq:`)
- [ ] Indice compilato correttamente
- [ ] PDF leggibile e ben formattato

---

## 📚 Risorse per Contributori

### LaTeX

- **Guida LaTeX**: https://www.overleaf.com/learn
- **TikZ Gallery**: https://texample.net/tikz/
- **Math Symbols**: https://www.ctan.org/pkg/comprehensive

### Content

- **CLIPS Manual**: https://www.clipsrules.net/Documentation.html
- **SLIPS Docs**: https://gpicchiarelli.github.io/SLIPS/
- **Codice SLIPS**: https://github.com/gpicchiarelli/SLIPS

### Stile Accademico

- **Italiano Accademico**: Guide universitarie
- **Mathematical Writing**: Knuth, Larrabee, Roberts (1989)

---

## 🎯 Priorità Contributi

### Alta Priorità

1. **Capitolo 8: Beta Network** - Teoricamente fondamentale
2. **Capitolo 9: Complessità** - Dimostrazioni formali
3. **Capitolo 18: SLIPS RETE** - Implementazione dettagliata

### Media Priorità

4. Capitoli 3-4: Fondamenti logici
5. Capitoli 11-15: Analisi CLIPS C
6. Capitoli 17, 19, 21: Core, Agenda, Pattern

### Bassa Priorità

7. Capitoli 5, 7, 10: Approfondimenti
8. Capitoli 23, 25-27: Guide avanzate

---

## 🏆 Riconoscimenti

Tutti i contributori vengono:

- Elencati nei ringraziamenti
- Accreditati nel frontespizio (contributi maggiori)
- Menzionati in CONTRIBUTORS.md

---

**Grazie per contribuire a rendere SLIPS una risorsa di qualità per la comunità!**

