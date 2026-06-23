# Meet with Apple — Talking Points (forager 4.3(a))

**Appointment**: Thursday, July 2, 2026, 2:00 p.m. Eastern
**App**: forager — v2.0, build 140
**Appeal Ticket**: APL466617 · **Submission ID**: `e5e960e5-2797-4d0c-a768-581576a70214`
**History**: 3× 4.3(a) rejections (2026-04-21, ~late-Apr, 2026-05-13) + App Review Board upheld (2026-06-23) — **none named a specific app forager duplicates.**
**Full record**: `docs/app-store-rejection-43a-response.md` (§ 7 history, § 11 appeal + Board response)

> **Note vs. the filed appeal**: the written appeal omitted the optional Claude tier to keep "no network" clean. This live conversation *features* the hybrid parser on purpose — it is the single best evidence that forager is original engineering, not a template. Keep the framing in Pillar 1 exactly: on-device is the default and demoable offline; Claude is optional and off by default.

---

## The one thing to get from this call

> **"Which specific app does forager duplicate?"**

Everything below serves that question. A written appeal lets a reviewer dodge it; a live rep usually can't. Both possible answers help me:
- **They name an app** → concrete and actionable. I differentiate against it directly and refile.
- **They can't / won't name one** → confirms the rejection is *category-saturation perception*, not duplication — which justifies repositioning the listing's first impression and refiling fresh (build 141, new submission ID).

---

## Opening (≈30 seconds, calm and factual)

"Thanks for the time. forager has been rejected under 4.3(a) three times and the App Review Board upheld it — but no message has ever named an app it duplicates. I rewrote the title, subtitle, description, keywords, and screenshots between rounds; each re-review returned the same wording. I'm not here to argue I'm unique in the abstract. I'd like to either learn which app you're comparing it to, or walk you through three things I built that I don't think exist together anywhere else — and you can tell me what still reads as duplicative."

---

## If they push "it's a crowded category"

"Competing in a crowded category isn't duplication. 4.3(a)'s own listed factors are shared code, repackaged templates, purchased templates, and multiple accounts — none apply: original native Swift, no template, one solo-developer account, one app of its kind. The three features I'll show take real engineering a template can't produce. If the concern is something other than those four factors, I'd genuinely like to know what it is."

**Four-factor refutation (quick reference):**
| 4.3(a) factor | forager |
|---|---|
| Shared code/assets | Original native Swift, written from scratch |
| Repackaged template | No template; only app of its kind I've built |
| Purchased 3rd-party template | None used |
| Multiple apps across accounts | Solo dev, one account, one app in category |

---

## The three pillars — demo live (have a device/simulator ready)

### 1. Hybrid ingredient parsing — on-device **and** optional Claude  *(lead here — strongest proof of original work)*

**The frame (say it in this order so the two halves don't contradict):**
1. **Default is fully on-device.** Turn on **Airplane Mode** → paste-import a recipe → a line resolves into structured quantity / unit / name with **no network call**. A three-tier local pipeline: **regex → a Core ML BiLSTM-CRF model I trained → Apple's NaturalLanguage framework.**
2. **On top of that, an optional Claude tier.** Off by default. A user can enable it in Settings to handle the hardest ~7–8% of lines — the semantic edge cases on-device models miss. When on, it runs as a fourth tier behind the local three.

**Why this kills the spam claim:** "A repackaged template doesn't include a model I trained *and* an optional cloud-LLM fallback wired behind a local confidence router. This is months of original parsing work — it's the core of the app."

- Contrast: Samsung Food parses in the cloud only; Pestle depends on Apple Intelligence. forager works offline first, with cloud as an *option*, not a requirement.
- *If asked about the AI/LLM:* it parses user-pasted recipe text into fields — it does **not** generate content. Off by default; the app is fully functional without it.

### 2. Multi-stop shopping — Group by Store

- Assign stores to ingredients → one list reorganizes into per-store sections so you shop a route across multiple stores in one trip.
- Contrast: AnyList has per-item store tags but isn't built around this workflow; most apps assume a single store.

### 3. Account-free household sharing — built on Apple's own tech

- Settings → Household → invite via link. **No signup, no email, no third-party server** — it's a **CloudKit share (CKShare) link** on Apple's infrastructure. Lean into this with Apple: *"I'm using your platform's native sharing primitives, not reinventing accounts."*
- Contrast: account-based apps (AnyList, etc.) require a login; Crouton/Mela lean on Apple Family Sharing rather than a shareable link.

**Surveyed against 12 apps**: AnyList, Paprika, Mealime, Plan to Eat, Samsung Food, Yummly, BigOven, Crouton, Mela, Pestle, Bring!, Kitchen Stories. No single one combines all three of the above.

---

## Closing ask

"If you can point me to the specific app, I'll address the overlap directly. If not, I'd ask that the 4.3(a) determination be reconsidered, or tell me what first-impression change would resolve it — and I'm happy to refile a fresh build with whatever's needed."

---

## Tone discipline (do / don't)

- **Do**: stay factual; reframe from "is it spammy?" (subjective) to "do these four conditions hold?" (objective); demo, don't assert; ask for specifics.
- **Do (parsing)**: always say on-device **first**, Claude as **optional/off-by-default** second — never let it sound network-dependent.
- **Don't**: get emotional, threaten, cite time-in-beta as if owed approval, claim originality without the concrete contrasts, or describe the LLM as generating content.

---

## Right after the call — capture immediately

- Who you spoke with, what they said, **any app named**, any specific change requested.
- Log it: response doc § 7 (history row) + § 11.8, then `current-story.md` Next Action.
- Decide the branch: named app → triage change · no app → reposition first-impression + withdraw-and-refile-fresh build 141 (§ 11.6).
