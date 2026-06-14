# CRKCACHY – Installation in 3 Schritten

**Ein Befehl.** Der Installer fragt dich, was du willst. Du antwortest mit **1, 2, 3 oder 4**.

> Kein Spiel, kein Crack – nur Einrichtung. [Rechtliches](docs/legal.md)  
> **English:** [README.en.md](README.en.md)

---

## Schritt 1 – Terminal öffnen

`Ctrl+Alt+T` oder Startmenü → **Konsole**

---

## Schritt 2 – CRKCACHY holen (einmalig)

```bash
git clone https://github.com/benjarogit/crkcachy.git
cd crkcachy
chmod +x install.sh lib/*.sh tools/*/install.sh tools/*/checks.sh
```

---

## Schritt 3 – Installer starten

```bash
./install.sh
```

### Du siehst diese Auswahl:

| Eingabe | Was passiert |
|---------|----------------|
| **1** | **Alles** – PC vorbereiten + Spiel aus Liste wählen *(empfohlen)* |
| **2** | Nur PC (Pakete, Proton, Spacewar) |
| **3** | Nur Spiel – wenn PC schon fertig ist |
| **4** | Nur prüfen – nichts installieren |

Danach folgst du den **Nummern und Fragen** im Terminal.

**Sprache:** automatisch (DE/EN). Manuell: `./install.sh --lang en`

---

## Wie der Installer „weiß“ was du willst

1. **Du wählst** ob PC oder Spiel (Menü 1–4).
2. **Spiele-Liste ist dynamisch** – alles unter `tools/` mit `install.sh` erscheint automatisch.
3. **Mehrere Spiele?** Nach einem Spiel: „Noch ein weiteres Spiel?“ → **j**
4. **Alle Spiele?** In der Liste: **a** = alle der Reihe durchgehen.

Neues Spiel später: jemand legt `tools/neues-spiel/install.sh` an → erscheint in der Liste.

---

## Nur prüfen (ohne Install)

```bash
./install.sh --status
```

---

## Hilfe

- Spiel-Anleitung: `tools/house-of-ashes/README.md`
- [Troubleshooting](docs/troubleshooting.md)

## Lizenz

MIT – [LICENSE](LICENSE)
