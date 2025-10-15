# 🚀 Quick Start - Compilazione Libro SLIPS

## Installazione Rapida (macOS)

```bash
# 1. Installa MacTeX (se non già installato)
brew install --cask mactex

# 2. Riavvia terminal per aggiornare PATH

# 3. Verifica installazione
pdflatex --version
biber --version
```

## Compilazione

```bash
# Metodo 1: Makefile (raccomandato)
cd libro/
make

# Metodo 2: Script bash
cd libro/
./compile.sh

# Metodo 3: Manuale
cd libro/
pdflatex main.tex
biber main
makeindex main  
pdflatex main.tex
pdflatex main.tex
```

## Visualizzazione

```bash
# Apri PDF appena compilato
make view

# Oppure manualmente
open main.pdf
```

## Compilazione Rapida (sviluppo)

Per modifiche rapide senza bibliografia/indice:

```bash
make quick
```

## Pulizia

```bash
# Rimuovi file intermedi
make clean

# Rimuovi tutto (incluso PDF)
make distclean
```

## Troubleshooting

### Errore: pdflatex not found

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt-get install texlive-full

# Fedora
sudo dnf install texlive-scheme-full
```

### Errore: biber not found

Biber dovrebbe essere incluso in TeX Live. Se manca:

```bash
# macOS
tlmgr install biber

# Linux
sudo apt-get install biber
```

### Errore di compilazione

1. Verifica sintassi LaTeX in file modificato
2. Compila con verbose: `pdflatex main.tex` (senza `-interaction`)
3. Leggi errori in `main.log`

### Warning: Missing references

Normale alla prima compilazione. Eseguire 3 volte pdflatex:

```bash
pdflatex main.tex  # Pass 1
biber main
pdflatex main.tex  # Pass 2
pdflatex main.tex  # Pass 3 - risolve refs
```

## Struttura Output

Dopo compilazione:

```
libro/
├── main.pdf          ← IL LIBRO!
├── main.aux
├── main.log
├── main.toc
├── main.bbl
├── main.lof
├── main.lot
└── ...
```

## Personalizzazione

### Cambiare Font

Modifica in `main.tex`:

```latex
% Invece di lmodern
\usepackage{times}        % Times New Roman
\usepackage{palatino}     % Palatino
\usepackage{helvet}       % Helvetica
```

### Cambiare Dimensione Carta

```latex
% Invece di a4paper
\documentclass[letterpaper, ...]{book}
```

### Cambiare Lingua

```latex
% Invece di italian
\usepackage[english]{babel}
```

## Tips

- **Watch mode**: Usa `latexmk -pvc` per ricompilazione automatica
- **Spell check**: Abilita in editor (VS Code, Overleaf)
- **Version control**: Committa spesso, evita `.aux` e `.log`
- **Backup**: Il PDF è riproducibile da sorgenti

## Aiuto

Per assistenza:
- GitHub Issues: https://github.com/gpicchiarelli/SLIPS/issues
- LaTeX Stack Exchange: https://tex.stackexchange.com/

---

**Tempo Compilazione**: ~30 secondi (prima volta), ~10 secondi (successive)  
**Dimensione PDF**: ~2-3 MB  
**Pagine**: ~400 stimate

