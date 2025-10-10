# 🚀 Setup GitHub Pages per SLIPS

Questa guida spiega come attivare GitHub Pages per il sito di documentazione SLIPS.

## ⚙️ Configurazione Repository

### 1. Attivare GitHub Pages

1. Vai su **Settings** del repository GitHub
2. Nel menu laterale, clicca su **Pages**
3. In **Source**, seleziona:
   - **Deploy from a branch**
   - Branch: `main`
   - Folder: `/ (root)` oppure `/docs` a seconda della configurazione
4. Clicca **Save**

### 2. Workflow Automatico (Consigliato)

Il file `.github/workflows/pages.yml` è già configurato per il deploy automatico.

**Setup con GitHub Actions:**

1. Vai su **Settings** → **Pages**
2. In **Source**, seleziona:
   - **GitHub Actions**
3. Il workflow si attiverà automaticamente ad ogni push su `main` che modifica la cartella `docs/`

### 3. Verifica Deployment

Dopo il setup:

1. Fai un push con le modifiche
2. Vai su **Actions** nel repository
3. Aspetta che il workflow "Deploy Documentation to Pages" completi
4. Il sito sarà disponibile su: `https://gpicchiarelli.github.io/SLIPS/`

## 📁 Struttura File

```
SLIPS/
├── .github/
│   └── workflows/
│       └── pages.yml          # Workflow automatico deploy
├── docs/
│   ├── .nojekyll              # Disabilita Jekyll
│   ├── index.html             # Landing page
│   ├── en/
│   │   └── index.html         # Documentazione inglese
│   ├── it/
│   │   └── index.html         # Documentazione italiana
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── main.js
│   ├── assets/
│   │   ├── logo.svg
│   │   └── favicon.svg
│   └── README.md
```

## 🔧 Personalizzazione Dominio (Opzionale)

Per usare un dominio personalizzato:

1. Crea un file `docs/CNAME` con il tuo dominio:
   ```
   docs.slips.dev
   ```

2. Configura i DNS record presso il tuo provider:
   ```
   Type: CNAME
   Name: docs
   Value: gpicchiarelli.github.io
   ```

3. In GitHub **Settings** → **Pages** → **Custom domain**, inserisci il dominio

## 🧪 Test Locale

Prima del deploy, testa localmente:

```bash
cd docs

# Con Python
python3 -m http.server 8000

# Con Node.js
npx http-server -p 8000

# Con PHP
php -S localhost:8000
```

Apri `http://localhost:8000` nel browser.

## ✅ Checklist Pre-Deploy

- [ ] Tutte le pagine HTML sono valide
- [ ] Links interni funzionano correttamente
- [ ] Immagini e assets si caricano
- [ ] Responsive design testato su mobile
- [ ] Selettore lingua funziona
- [ ] Esempi di codice sono corretti
- [ ] Meta tags e SEO configurati
- [ ] Favicon presente

## 🐛 Troubleshooting

### Il sito non si carica

1. Verifica che il workflow sia completato senza errori
2. Controlla che `docs/.nojekyll` esista
3. Aspetta 5-10 minuti per la propagazione

### CSS/JS non si caricano

1. Verifica i path relativi negli HTML
2. Controlla che i file esistano nella cartella corretta
3. Apri la console browser per errori 404

### Modifiche non visibili

1. Svuota cache browser (Cmd+Shift+R su Mac, Ctrl+Shift+R su Windows)
2. Aspetta qualche minuto per il rebuild automatico
3. Verifica che il commit abbia triggerato il workflow

## 📚 Risorse

- [GitHub Pages Docs](https://docs.github.com/en/pages)
- [GitHub Actions for Pages](https://github.com/actions/deploy-pages)
- [Custom Domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

---

🎉 Una volta configurato, il sito si aggiornerà automaticamente ad ogni push!

