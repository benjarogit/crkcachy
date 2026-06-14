# CRKCACHY – How to (simple)

**CRKCACHY** helps you run **standalone and portable games** via **Steam + Proton** – without Bottles or Wineboot.  
No game in the package: guides, checks, mods, and community fixes.

> Help only, no crack. [Legal](docs/legal.md)  
> **Deutsch:** [README.md](README.md)

---

## Step 1 – Open the terminal

**Ctrl + Alt + T** or search for **Terminal** / **Konsole**.

---

## Step 2 – Get CRKCACHY (once)

```bash
git clone https://github.com/benjarogit/crkcachy.git
cd crkcachy
chmod +x install.sh lib/*.sh tools/*/install.sh tools/*/checks.sh
```

---

## Step 3 – Start

```bash
./install.sh
```

The program:

1. sets up **arrow menu** and **guide reader** if needed (once, with your OK)  
2. checks your **PC**  
3. helps with the **game in Steam**

**Arrow keys** = pick · **Enter** = confirm

---

## View only (no game setup)

```bash
./install.sh --status
```

---

## House of Ashes

[tools/house-of-ashes/README.en.md](tools/house-of-ashes/README.en.md)

---

## Help

- [Prerequisites](docs/prerequisites.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

MIT – [LICENSE](LICENSE)
