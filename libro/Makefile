# Makefile per compilazione libro SLIPS

# Configurazione
MAIN = main
LATEX = pdflatex
BIBTEX = biber
MAKEINDEX = makeindex

# Opzioni
LATEX_FLAGS = -interaction=nonstopmode -halt-on-error
BIBTEX_FLAGS = 
MAKEINDEX_FLAGS = 

# File sorgenti
TEX_FILES = $(wildcard capitoli/*.tex)
BIB_FILE = bibliografia.bib

# Output
PDF = $(MAIN).pdf

.PHONY: all clean distclean view help

# Build completo
all: $(PDF)

# Compilazione PDF (multi-pass per riferimenti)
$(PDF): $(MAIN).tex $(TEX_FILES) $(BIB_FILE)
	@echo "==> Prima passata LaTeX..."
	$(LATEX) $(LATEX_FLAGS) $(MAIN)
	@echo "==> BibTeX..."
	-$(BIBTEX) $(BIBTEX_FLAGS) $(MAIN)
	@echo "==> MakeIndex..."
	-$(MAKEINDEX) $(MAKEINDEX_FLAGS) $(MAIN)
	@echo "==> Seconda passata LaTeX..."
	$(LATEX) $(LATEX_FLAGS) $(MAIN)
	@echo "==> Terza passata LaTeX..."
	$(LATEX) $(LATEX_FLAGS) $(MAIN)
	@echo "==> PDF generato: $(PDF)"

# Compilazione rapida (singola passata)
quick: $(MAIN).tex
	@echo "==> Compilazione rapida..."
	$(LATEX) $(LATEX_FLAGS) $(MAIN)
	@echo "==> PDF generato: $(PDF)"

# Pulizia file intermedi
clean:
	@echo "==> Pulizia file intermedi..."
	rm -f *.aux *.log *.toc *.out *.bbl *.blg *.bcf *.run.xml *.lof *.lot *.lol *.idx *.ind *.ilg
	rm -f capitoli/*.aux
	@echo "==> Pulizia completata"

# Pulizia completa (incluso PDF)
distclean: clean
	@echo "==> Rimozione PDF..."
	rm -f $(PDF)
	@echo "==> Pulizia completa"

# Apri PDF con viewer di default
view: $(PDF)
	@echo "==> Apertura PDF..."
	open $(PDF) || xdg-open $(PDF) || evince $(PDF)

# Mostra aiuto
help:
	@echo "Makefile per libro SLIPS"
	@echo ""
	@echo "Target disponibili:"
	@echo "  make          - Compila PDF completo (3 passate)"
	@echo "  make quick    - Compilazione rapida (1 passata)"
	@echo "  make clean    - Rimuove file intermedi"
	@echo "  make distclean- Rimuove tutto (incluso PDF)"
	@echo "  make view     - Apri PDF compilato"
	@echo "  make help     - Mostra questo messaggio"
	@echo ""
	@echo "Requisiti:"
	@echo "  - pdflatex"
	@echo "  - biber (per bibliografia)"
	@echo "  - makeindex (per indice analitico)"
	@echo ""
	@echo "Installazione su macOS:"
	@echo "  brew install --cask mactex"

# Watch mode (richiede entr o similar)
watch:
	@echo "==> Watch mode (richiede entr)..."
	@echo "Uso: ls **/*.tex | entr make quick"

