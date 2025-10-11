# GitHub Actions Workflows

Questa cartella contiene i workflow di GitHub Actions per CI/CD del progetto SLIPS.

## Workflows Disponibili

### 🔧 CI (`ci.yml`)
**Trigger:** Push e PR su `main` e `develop`

Esegue:
- Build del progetto Swift su macOS 14
- Esecuzione di tutti i test
- Generazione report code coverage
- Build su Linux (Ubuntu container con Swift 5.9)
- Lint e controllo warning

**Badge:**
```markdown
[![CI](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml/badge.svg)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml)
```

### 📚 Deploy Documentation (`pages.yml`)
**Trigger:** Push su `main` quando ci sono modifiche in `docs/` o esecuzione manuale

Esegue:
- Build della documentazione
- Deploy automatico su GitHub Pages
- Pubblicazione del sito web su `https://gpicchiarelli.github.io/SLIPS/`

**Badge:**
```markdown
[![Deploy Pages](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml/badge.svg)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml)
```

### 🚀 Release (`release.yml`)
**Trigger:** Push di un tag `v*.*.*` (es. `v0.1.0`)

Esegue:
- Build del binary CLI in modalità release
- Creazione di release su GitHub
- Upload del binary `slips-cli-macos.tar.gz`
- Generazione note di rilascio automatiche

**Esempio creazione release:**
```bash
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin v0.1.0
```

### ✅ PR Checks (`pr-checks.yml`)
**Trigger:** Apertura/aggiornamento di Pull Request

Esegue:
- Build e test approfonditi
- Controllo warning di compilazione
- Validazione struttura package
- Test di compatibilità con diverse versioni Swift
- Commento automatico sulla PR con risultati

## Configurazione Locale

### Testare i workflow localmente con act

Installa [act](https://github.com/nektos/act):
```bash
brew install act
```

Esegui il workflow CI in locale:
```bash
act -j build-and-test
```

### Variabili d'Ambiente

I workflow utilizzano solo variabili standard di GitHub Actions:
- `GITHUB_TOKEN` - fornito automaticamente
- `GITHUB_REF` - riferimento git corrente
- `GITHUB_REPOSITORY` - nome del repository

### Badge da Aggiungere al README

Aggiungi questi badge al `README.md` principale:

```markdown
[![CI](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml/badge.svg)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml)
[![Deploy Pages](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml/badge.svg)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml)
[![codecov](https://codecov.io/gh/gpicchiarelli/SLIPS/branch/main/graph/badge.svg)](https://codecov.io/gh/gpicchiarelli/SLIPS)
```

## Manutenzione

### Dependabot
Il file `dependabot.yml` mantiene aggiornate automaticamente le GitHub Actions.
Le PR di aggiornamento vengono create settimanalmente.

### Aggiornamento Workflow

Per modificare i workflow:
1. Modifica il file YAML corrispondente
2. Testa localmente con `act` se possibile
3. Crea una PR e verifica che i check passino
4. Mergia su `main`

### Requisiti

- **macOS runner:** utilizza `macos-14` con Xcode 15.4
- **Swift:** versione 5.9+ supportata
- **Linux:** build testato su Ubuntu con Swift 5.9

## Troubleshooting

### Build fallisce su macOS
- Verifica che il progetto compili localmente: `swift build`
- Controlla la versione di Xcode specificata nel workflow
- Verifica i log dettagliati nella sezione Actions di GitHub

### Test falliscono
- Esegui `swift test` localmente per riprodurre il problema
- Verifica che tutti i file di test siano inclusi nel `Package.swift`
- Controlla i log dettagliati del workflow

### Deploy documentazione non funziona
- Verifica che GitHub Pages sia abilitato nelle impostazioni del repository
- Assicurati che la branch di deploy sia configurata correttamente
- Controlla che i permessi del workflow siano corretti

## Riferimenti

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Swift on GitHub Actions](https://github.com/swift-actions)
- [GitHub Pages Deploy Action](https://github.com/peaceiris/actions-gh-pages)

