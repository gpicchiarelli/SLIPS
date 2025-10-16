#!/bin/bash
# Script di compilazione libro SLIPS

set -e  # Exit on error

echo "=========================================="
echo "  Compilazione Libro SLIPS"
echo "=========================================="
echo ""

# Check requisiti
command -v pdflatex >/dev/null 2>&1 || {
    echo "❌ pdflatex non trovato!"
    echo "Installare: brew install --cask mactex (macOS)"
    exit 1
}

command -v biber >/dev/null 2>&1 || {
    echo "⚠️  biber non trovato (bibliografia potrebbe non funzionare)"
}

command -v makeindex >/dev/null 2>&1 || {
    echo "⚠️  makeindex non trovato (indice analitico potrebbe non funzionare)"
}

echo "✅ Requisiti soddisfatti"
echo ""

# Pulizia preventiva
echo "🧹 Pulizia file intermedi precedenti..."
make clean 2>/dev/null || true
echo ""

# Compilazione
echo "📄 Compilazione in corso..."
echo ""

echo "  [1/5] Prima passata pdflatex..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex > /dev/null

echo "  [2/5] BibTeX (bibliografia)..."
biber main 2>/dev/null || true

echo "  [3/5] MakeIndex (indice)..."
makeindex main 2>/dev/null || true

echo "  [4/5] Seconda passata pdflatex..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex > /dev/null

echo "  [5/5] Terza passata pdflatex..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex > /dev/null

echo ""
echo "✅ Compilazione completata con successo!"
echo ""

# Statistiche
if [ -f main.pdf ]; then
    SIZE=$(du -h main.pdf | cut -f1)
    PAGES=$(pdfinfo main.pdf 2>/dev/null | grep Pages | awk '{print $2}' || echo "?")
    echo "📊 Statistiche:"
    echo "   - File: main.pdf"
    echo "   - Dimensione: $SIZE"
    echo "   - Pagine: $PAGES"
    echo ""
fi

# Apri PDF
echo "📖 Aprire il PDF? [y/N]"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    open main.pdf 2>/dev/null || xdg-open main.pdf 2>/dev/null || echo "Aprire manualmente: main.pdf"
fi

echo ""
echo "=========================================="
echo "  Compilazione Completata!"
echo "=========================================="

