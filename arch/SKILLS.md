# Google Antigravity Skills & Plugins Directory

Comprehensive directory of all skills, plugins, upstream sources, licenses, and 1-click installation automation for this environment.

---

## ⚡ 1-Click Install in One Go

To install or update every custom skill, git repository, and marketplace plugin in one go:

```bash
~/nixos-config/arch/setup-skills.sh
```

Or via full environment setup:
```bash
~/nixos-config/arch/setup-antigravity.sh
```

---

## 📋 Complete Skills Inventory

### 1. Standalone User Skills (`~/.gemini/config/skills/`)
Local skills maintained in `arch/dotfiles/antigravity/skills/`:

| Skill | Purpose / Trigger | Origin / Upstream | License |
| :--- | :--- | :--- | :--- |
| **`canvas-design`** | Design visual art, vector graphics, posters, SVG & HTML5 canvas | Custom / Curated | Open |
| **`chisle`** | Mandatory always-on token optimizer & efficiency ladder | Custom / Curated | Open |
| **`chisle-audit`** | One-shot code & prose bloat audit (`/chisle-audit`) | Custom / Curated | Open |
| **`chisle-help`** | Quick-reference card for Chisle commands (`/chisle-help`) | Custom / Curated | Open |
| **`chisle-review`** | Diff review for over-engineering & verbosity (`/chisle-review`) | Custom / Curated | Open |
| **`deep-debugger`** | Hypothesis-driven systematic debugging for complex bugs | Custom / Curated | Open |
| **`frontend-design`** | Distinctive, non-generic UI aesthetic guidance & typography | Custom / Curated | Open |
| **`pdf`** | Read, extract, OCR, merge, split, form-fill, and watermark PDFs | Custom / Curated | Open |
| **`reverse-engineer-anything`** | REA reverse engineering for native/managed/JS targets | Custom / Curated | Open |
| **`sast-security-auditor`** | Static security analysis, OWASP Top 10, secret scanning | Custom / Curated | Open |
| **`sinhala-explainer`** | Explains tech topics in spoken Sinhala (`/sinhala-explainer`) | Custom / Curated | Open |
| **`sinhala-explainer-only-from-content`** | Strict content-only explainer in Sinhala (`/sinhala-explainer-only-from-content`) | Custom / Curated | Open |
| **`sinhala-explainer-short`** | Ultra-concise Sinhala explainer (`/sinhala-explainer-short`) | Custom / Curated | Open |

---

### 2. External Git Repositories (`~/.gemini/config/plugins/` & `skills/`)
Cloned directly from upstream Git repositories to ensure license compliance and preservation of commit histories:

| Skill / Plugin | Path | Upstream Repository | License | Purpose / Details |
| :--- | :--- | :--- | :--- | :--- |
| **`andrej-karpathy-skills`** (`karpathy-guidelines`) | `~/.gemini/config/plugins/andrej-karpathy-skills` | [github.com/multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | MIT | Behavioral guidelines to prevent LLM coding pitfalls based on Andrej Karpathy's findings |
| **`i-have-adhd`** | `~/.gemini/config/plugins/i-have-adhd` & `skills/i-have-adhd` | [github.com/ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | Open Source | Formats output for ADHD readers: action-first, explicit steps, restated state |
| **`task-observer`** | `~/.gemini/config/skills/task-observer` | [github.com/rebelytics/one-skill-to-rule-them-all](https://github.com/rebelytics/one-skill-to-rule-them-all) | Open Source | Meta-observation skill logging execution insights into `~/.gemini/skill-observations/` |

---

### 3. Antigravity Official Marketplace Plugins (`~/.gemini/config/plugins/`)

| Plugin Name | Marketplace ID | Bundled Skills | License |
| :--- | :--- | :--- | :--- |
| **`chrome-devtools-plugin`** | `antigravity-plugins-official/plugin/chrome-devtools-plugin` | `chrome-devtools`, `a11y-debugging`, `cookie-debugging`, `debug-optimize-lcp`, `memory-leak-debugging`, `troubleshooting` | Apache-2.0 |
| **`modern-web-guidance-plugin`** | `antigravity-plugins-official/plugin/modern-web-guidance-plugin` | `modern-web-guidance`, `chrome-extensions` | Apache-2.0 / Google |
| **`google-antigravity-sdk`** | `antigravity-plugins-official/plugin/google-antigravity-sdk` | Python SDK agent development tools | Apache-2.0 / Google |

---

### 4. Built-in Runtime Skills (`~/.gemini/antigravity/builtin/skills/`)
Provided natively by the Antigravity CLI and IDE:
- `agy-customizations`: Guide for creating skills, rules, plugins, hooks, and MCP servers.
- `antigravity-guide`: Sitemap and reference for Antigravity IDE, `agy` CLI, SDK, slash commands, and keys.
- `automation`: Background scheduled automation generator (`/automation`).
- `generative_ui`: Dynamic interactive widget generator.
- `migrate-workflows`: Legacy workflow migration tool.
- `plugin`: Plugin installation and lifecycle manager (`/plugin`).
- `ui-plugin-navigation`: Quick-access pills for side panels.

---

## ⚖️ Copyright & Upstream Licensing Notes

- **Open Source Attribution**: External plugins (`andrej-karpathy-skills`, `i-have-adhd`, `task-observer`) are cloned directly from their official Git upstream repos with full commit history, author attribution, and license files intact.
- **Copyright Integrity**: When deploying to new environments, `setup-skills.sh` clones fresh copies from official remotes, avoiding uncredited redistributions.
