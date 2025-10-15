# 🤖 Come Funziona la Compilazione Automatica

## 📋 Overview

Ho creato **3 GitHub Actions workflow** che compilano automaticamente il libro LaTeX e pubblicano il PDF.

---

## 🔄 Workflow 1: Compilazione Automatica

**File**: `.github/workflows/compile-libro.yml`

### Quando Si Attiva

- ✅ **Push su main** con modifiche in `libro/`
- ✅ **Pull Request** con modifiche in `libro/`
- ✅ **Manuale** (pulsante "Run workflow")

### Cosa Fa

1. **Compila** libro LaTeX → PDF
2. **Upload** PDF come artifact (scaricabile 90 giorni)
3. **Se push su main**: Crea release automatica
   - Tag: `libro-2025-10-15` (data odierna)
   - Name: "Libro SLIPS - 2025-10-15"
   - Asset: main.pdf

### Come Usare

#### Download da Artifacts

```
1. GitHub → Actions → "Compila Libro LaTeX"
2. Click sul run più recente
3. Scroll down → Artifacts
4. Download "libro-slips" (ZIP con PDF)
```

#### Download da Releases

```
1. GitHub → Releases
2. Click su release più recente "Libro SLIPS - DATE"
3. Assets → Download main.pdf
```

---

## 🎯 Workflow 2: Release Manuale

**File**: `.github/workflows/libro-release.yml`

### Quando Si Attiva

Solo **manualmente** (workflow_dispatch)

### Input Richiesti

- **version**: Es. "1.0", "2.0", "1.5-beta"
- **prerelease**: true/false (checkbox)

### Cosa Fa

1. **Compila** con 3 passate complete:
   - Pass 1: genera toc/lof/lot
   - BibTeX: processa bibliografia
   - MakeIndex: processa indice
   - Pass 2: risolve riferimenti
   - Pass 3: finalizza
2. **Rinomina** PDF: `SLIPS-Libro-v1.0.pdf`
3. **Crea release** GitHub:
   - Tag: `libro-v1.0`
   - Name: "📚 Libro SLIPS v1.0"
   - Body: Descrizione completa
   - Asset: PDF versionato

### Come Usare

```
1. GitHub → Actions
2. Seleziona "Release Libro (Manuale)"
3. Click "Run workflow" (in alto a destra)
4. Compila form:
   - Branch: main
   - version: 1.0
   - prerelease: ☐ (unchecked)
5. Click "Run workflow" (verde)
6. Attendi ~5 minuti
7. Vai su Releases → Trova "Libro SLIPS v1.0"
8. Download PDF
```

**Uso consigliato**: Per milestone importanti (1.0, 2.0, etc.)

---

## 📄 Workflow 3: Deploy su GitHub Pages

**File**: `.github/workflows/libro-pages.yml`

### Quando Si Attiva

- Push su `main` con modifiche in `libro/`
- Manuale

### Cosa Fa

1. Compila libro
2. Deploy PDF su GitHub Pages
3. Accessibile via URL: `https://gpicchiarelli.github.io/SLIPS/libro.pdf`

### Setup Richiesto

⚠️ **Prima di attivare questo workflow**:

```
1. GitHub → Settings → Pages
2. Source: "GitHub Actions"
3. Save
```

Poi il workflow funzionerà automaticamente.

**Nota**: Se non vuoi usare Pages, puoi ignorare questo workflow (non causa problemi).

---

## 🛠️ Dettagli Tecnici

### Container LaTeX

I workflow usano `xu-cheng/latex-action@v3`:
- Ubuntu latest
- TeX Live full
- Tutti i pacchetti LaTeX disponibili
- pdflatex, biber, makeindex pre-installati

### Performance

- **Compilazione**: ~3-5 minuti
- **Upload**: ~30 secondi
- **Release**: ~1 minuto
- **Totale**: ~5-7 minuti per run completo

### Artifacts

- **Formato**: ZIP contenente PDF
- **Nome**: `libro-slips.zip`
- **Contenuto**: `main.pdf`
- **Dimensione**: ~2-3 MB (compresso)
- **Retention**: 90 giorni (poi cancellato automaticamente)

### Releases

- **Permanenti**: Non scadono
- **Pubbliche**: Chiunque può scaricare
- **Versionate**: Tag git
- **Descrizione**: Markdown formattato

---

## 📊 Strategia Raccomandata

### Setup Iniziale

1. ✅ Commit workflow (già fatto dopo)
2. ✅ Push su main
3. ✅ Verifica first run in Actions

### Uso Quotidiano

- **Sviluppo**: Modifica `.tex` localmente, test con `make`
- **Commit**: Push su branch feature
- **PR**: Crea PR → CI compila automaticamente
- **Merge**: Merge su main → Release automatica creata

### Milestone

- **v1.0**: Usa workflow release manuale, crea tag `libro-v1.0`
- **v2.0**: Dopo completamento tutti capitoli
- **Draft**: Usa prerelease=true per bozze

---

## 🎯 Flusso Tipico

```
┌─────────────────────────────────────────────┐
│ Developer: Modifica capitoli/*.tex          │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ git add libro/                              │
│ git commit -m "feat(libro): aggiorna cap 8" │
│ git push origin feature/cap8                │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ GitHub: Apri Pull Request                   │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ GitHub Actions: Compila libro (PR)          │
│ ✓ Build successful                          │
│ ✓ Artifact disponibile per review           │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Code Review: Scarica PDF, verifica          │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Merge to main                               │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ GitHub Actions: Compila + Release           │
│ ✓ Tag: libro-2025-10-15                     │
│ ✓ Release creata con PDF                    │
│ ✓ (Opzionale) Deploy su Pages               │
└─────────────────────────────────────────────┘
```

---

## 🚀 Prima Esecuzione

Dopo il push dei workflow:

```
1. GitHub → Actions
2. Vedrai 3 workflow disponibili:
   - "Compila Libro LaTeX"
   - "Release Libro (Manuale)"
   - "Deploy Libro su GitHub Pages"

3. Per test immediato:
   - Click "Compila Libro LaTeX"
   - Run workflow
   - Branch: main
   - Attendi ~5 minuti
   - Download PDF da artifacts!
```

---

## 🎓 Vantaggi CI per Libro

### ✅ Consistenza

- Ambiente compilazione identico sempre
- No "works on my machine"
- Riproducibilità garantita

### ✅ Accessibilità

- Chiunque può scaricare PDF senza LaTeX installato
- Review facilitato (PDF in PR)
- Distribuzione automatica

### ✅ Versioning

- Ogni commit → artifact
- Milestone → release permanente
- Storia completa delle versioni

### ✅ Collaboration

- Contributori possono verificare PDF
- No necessità TeX Live locale
- Feedback immediato su errori

---

## 📝 Personalizzazioni Possibili

### Cambiare Retention Artifacts

```yaml
- uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # Invece di 90
```

### Aggiungere Notifiche

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Libro compilato!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Deploy su AWS S3

```yaml
- name: Upload to S3
  uses: jakejarvis/s3-sync-action@master
  with:
    args: --acl public-read
  env:
    AWS_S3_BUCKET: 'my-libro-bucket'
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_KEY }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET }}
    SOURCE_DIR: 'libro'
```

---

**I workflow sono PRONTI! Commit e push per attivarli.** ✅

