Contributing to SLIPS

Grazie per voler contribuire a SLIPS, traduzione fedele di CLIPS in Swift 6.2.
L’obiettivo è mantenere la parità funzionale con il motore originale, adottando Swift solo dove non altera la semantica.

⸻

Requisiti
	•	Swift 6.2+
	•	macOS 14+ o Linux compatibile
	•	Xcode 16.x (opzionale)

Build e test:

swift build
swift test


⸻

Linee guida
	•	Traduci il codice C 1:1 dove possibile.
	•	Usa Swift idiomatico solo se trasparente sul piano semantico e prestazionale.
	•	Mantieni il determinismo (stessi input → stessi output).
	•	Ogni modulo (parser, rete, facts, agenda, ecc.) deve avere test dedicati.
	•	Commenta le differenze rispetto al codice CLIPS originale.

⸻

Branch e commit
	•	main: stabile
	•	feat/, fix/, perf/ per feature, bugfix, ottimizzazioni
	•	Commit in formato Conventional Commits:
feat(rete): implement beta memory activation

⸻

PR e qualità
	•	PR piccole e chiare
	•	Obbligatori: test verdi, codice formattato, nessun warning
	•	Aggiungi benchmark se tocchi performance
	•	Aggiorna documentazione se serve

⸻

Codice di condotta

Questo progetto segue il Contributor Covenant v2.1.
Rispetta sempre gli altri collaboratori.

⸻

Licenza

Contributi soggetti alla licenza MIT.
