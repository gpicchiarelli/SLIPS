# 📝 SLIPS - Changelog

Tutte le modifiche notevoli al progetto sono documentate in questo file.

---

## [0.96.0] - 2025-10-16

### 🎉 Funzionalità Aggiunte

#### Template Functions Complete (tmpltfun.c 100%)
- Aggiunte 4 nuove funzioni template da `tmpltfun.c`:
  - `deftemplate-slot-allowed-values`
  - `deftemplate-slot-defaultp`
  - `deftemplate-slot-facet-existp`
  - `deftemplate-slot-facet-value`
- Totale: 14/14 funzioni template implementate

#### Sistema Moduli Production-Ready
- Assert trasformato in special form
- Supporto doppia sintassi CLIPS
- ModuleName assignment alle attivazioni
- Focus stack integrato in run()

### 🐛 Bug Risolti
- [CRITICO] Regole multi-modulo non si attivavano → RISOLTO
- [CRITICO] Focus stack non ordinava agenda → RISOLTO

### 📊 Metriche
- Test pass rate: 96.8% → 99.6%
- Funzioni builtin: 156 → 160
- CLIPS coverage: 95% → 96%

---

## Versioni Precedenti

Documentazione completa delle versioni pre-0.96.0 disponibile in git history.

---

**Formato Changelog**: Questo file segue [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), e questo progetto aderisce a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

