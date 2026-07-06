# 🧭 KOORDINATEN — Wer ist wer (Maxime #1)

**Diese Schublade ist die iPadOS-App. Sie bewegt sich NIEMALS in einen anderen Ordner, ein anderes Repo oder ein anderes Git.**

## Diese App
- **Entity:** mykilOS **iPadOS**
- **Lokaler Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS iPAD`
- **GitHub (origin):** `github.com/JohannesLeoB/mykilOS-iPadOS`

## Die vier getrennten Schubladen — nie vermischen
| Entity | Lokaler Ordner | GitHub-Repo |
|---|---|---|
| macOS | `mykilOS Mac` | `mykilOS-macOS` |
| iOS | `mykilOS iOS` (Quellcode eigentlich unter `/Users/johannesleoberger/Claude/Projects/myMini/mykilos-mobile/myMini`) | `myMini` |
| **iPadOS (diese)** | `mykilOS iPAD` | `mykilOS-iPadOS` |
| browser | `mykilOS Web` | `mykilOS-WWW` |

## Harte Regeln (Maxime #1)
1. **Vor JEDER Aktion** (build/test/commit/push/Agent): `git -C "<repo>" remote get-url origin` MUSS `mykilOS-iPadOS` enthalten — sonst **SOFORT STOP**.
2. **Nur absoluter Pfad**, nie cwd-relativ. Der Session-`cwd` kann fälschlich auf eine Nachbar-Schublade zeigen — **ignorieren**, `mykilOS iPAD` immer absolut ansprechen.
3. Nachbar-Repos (macOS/iOS/Web) dürfen **nur gelesen** werden (Vernetzung, Design-Tokens, Konventionen abgleichen) — niemals beschrieben, committet oder gepusht.
4. Ein **Pre-Push-Hook** (`.git/hooks/pre-push`, versioniert in `scripts/guard-pre-push.sh`) blockt physisch jeden Push, dessen Ziel nicht `mykilOS-iPadOS` ist.
5. Ein **PreToolUse-Hook** (`.claude/guard-ipados.sh`) blockt Write/Edit/Bash-Schreibzugriffe außerhalb dieser Schublade.

## Historie
- 2026-07-06: Repo `mykilOS-iPadOS` auf GitHub angelegt (leer). Lokales Repo hier initialisiert, Guard-Rails nach Vorbild von `mykilOS Mac`/`mykilOS iOS` übernommen.
