---
name: frontend-design
description: Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one. Helps with aesthetic direction, typography, and making choices that avoid generic, templated defaults ("AI slop").
---

# Frontend Design Skill

Approach every frontend design task as a lead designer at an elite digital studio known for giving every product a distinct, bespoke visual identity. Reject generic, cliché, or templated defaults. Make deliberate, opinionated choices about palette, typography, micro-interactions, and layout specific to the project's purpose.

---

## 1. Ground the Design in the Subject Matter

1. **Understand Audience & Purpose**:
   - Before writing CSS or layout code, clearly identify who uses the interface and what problem it solves.
   - A technical dashboard for site reliability engineers requires high information density, subtle dividers, and monospace accents; a creative portfolio requires dramatic whitespace, editorial typography, and fluid transitions; a B2B SaaS requires clarity, reassuring contrast, and intuitive navigation.
2. **Real Content Over Placeholders**:
   - Avoid generic "Lorem ipsum" or meaningless buzzwords ("Streamline your synergy").
   - Write realistic domain copy, genuine data points, and realistic empty/error states.

---

## 2. Core Visual Principles

### A. Avoid Generic "AI Slop" Defaults
Steer clear of patterns that make designs look machine-templated:
* **Backgrounds**: Avoid default warm yellow-cream (`#FDFBF7`) or generic purple-neon gradients on dark backgrounds unless explicitly requested.
* **Typographic Clichés**:
  - Do not arbitrarily colorize or italicize a single word in a headline (e.g., "Build *faster* with AI").
  - Do not slap uppercase tracking on every subheader or label.
  - Do not add random numeric badges ("01", "02", "03") unless content is an actual sequence.
* **Cards & Containers**:
  - Avoid putting every piece of text inside an identical rounded card with a diffuse drop-shadow.
  - Use whitespace, line dividers (`border-t`), or typography scale to group information.

### B. Typography as Voice
* **Type Hierarchy**:
  - Stick to one strong superfamily or at most two complementary typefaces (e.g., an editorial Serif display paired with a clean geometric Sans body, or a distinctive Grotesk with a precise Monospace).
  - Define a strict scale: display (36-48px+), h1 (28-32px), h2 (20-24px), body (14-16px), caption (12px).
* **Line Length & Rhythm**:
  - Keep prose reading widths between 45–75 characters (`max-w-prose` or `60-70ch`).
  - Use generous line-height (`leading-relaxed`) for body paragraphs, tighter line-height (`leading-tight` or `tracking-tight`) for large headings.

### C. Color Architecture
* **Dominant & Accent Rules**:
  - 60% Dominant neutral (grounding background and card surfaces).
  - 30% Structural tone (borders, secondary text, muted indicators).
  - 10% Sharp accent (interactive buttons, focus rings, key metric highlights).
* **Accessible Contrast**:
  - Always guarantee WCAG AA minimums (4.5:1 for body text, 3:1 for large text and controls).
  - Provide deliberate light/dark mode tokens rather than relying on automated color inversions.

### D. Motion & Micro-Interactions
* **Purposeful Transitions**:
  - Use motion to communicate state change (drawer opening, item deleted, accordion expanded).
  - Keep durations between `150ms` and `250ms` with natural easing curves (`cubic-bezier(0.16, 1, 0.3, 1)`).
  - Avoid non-stop ambient animations, floating badges, or staggered fade-ins across every section that distract from core tasks.

---

## 3. Implementation Checklist (Tailwind & Modern CSS)

- [ ] Semantic HTML (`<main>`, `<nav>`, `<article>`, `<aside>`, `<dialog>`).
- [ ] Responsive design from mobile (`375px`) to ultrawide (`1440px+`).
- [ ] Explicit focus states (`focus-visible:ring-2 focus-visible:outline-none`).
- [ ] Proper empty, loading (skeletons), and error states for all interactive data views.
- [ ] Fluid spacing using consistent rem-based tokens (`space-y-4`, `gap-6`, `p-6`).
