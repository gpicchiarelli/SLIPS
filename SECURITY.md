# Security Policy

## 🔒 Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.96.x  | :white_check_mark: |
| 0.95.x  | :white_check_mark: |
| < 0.95  | :x:                |

## 🛡️ Reporting a Vulnerability

**SLIPS** è un rule engine e, come tale, può essere utilizzato per applicazioni critiche. Segnalare vulnerabilità è importante per la sicurezza della community.

### Come Segnalare

Se scopri una vulnerabilità di sicurezza:

1. **NON** aprire un issue pubblico su GitHub
2. Invia una email a: **security@slips.dev** (o usa GitHub Security Advisories)
3. Includi:
   - Descrizione dettagliata della vulnerabilità
   - Steps per riprodurre
   - Potenziale impatto
   - Suggerimenti per il fix (se disponibili)

### Processo di Gestione

- **Tempo di risposta**: Entro 48 ore per conferma di ricezione
- **Acknowledgment**: Riceverai un acknowledgment entro 1 settimana
- **Fix timeline**: Dipende dalla gravità:
  - **Critica**: Fix entro 7 giorni
  - **Alta**: Fix entro 30 giorni
  - **Media/Bassa**: Fix entro 90 giorni
- **Disclosure**: Coordinata con te prima della pubblicazione

### Tipi di Vulnerabilità

Segnaliamo in particolare:

- **Memory safety**: Buffer overflows, use-after-free, double-free
- **Injection attacks**: Code injection attraverso input non validati
- **DoS**: Denial of Service attraverso input malformati
- **Information disclosure**: Esposizione di dati sensibili
- **Privilege escalation**: Accesso non autorizzato a risorse

### Ricompense

Attualmente non offriamo un programma di bug bounty, ma riconoscimenti pubblici possono essere forniti per contributi significativi alla sicurezza.

---

**Grazie per aiutare a mantenere SLIPS sicuro!** 🎯
