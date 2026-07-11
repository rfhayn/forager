# App Store — Resubmit vs. Reply after a rejection

App Review rejections resolve two different ways depending on the rejection
**type**. Picking the wrong path costs days (it once cost a 3-day stall and a
support phone call). Check the type first, then follow the matching path.

## Metadata rejections
Guideline 2.3.6 (Accurate Metadata), Age Rating issues, description / screenshot
/ keyword problems — anything whose status is **"Metadata Rejected"** and whose
fix lives entirely in App Store Connect.

1. Update the metadata in ASC.
2. Reply to the reviewer in Resolution Center.
3. **Apple continues the review from the reply — no resubmit, no new binary.**

This is documented Apple behavior and confirmed across community sources. Do
**not** generalize the Cancel/Resubmit dance below to metadata rejections.

## Binary / guideline rejections
Code-level issues, functional complaints — status **"Rejected."**

1. Fix the code, archive a new build (or reuse the same build if permitted).
2. Explicitly **Submit for Review**.
3. If the Resubmit button is disabled, click **Cancel Submission** on the
   rejected submission to unlock it.

## Rule of thumb
- Fix is only in ASC (ratings, descriptions, screenshots, keywords, privacy) →
  **reply + update metadata**, done.
- A code change / new binary is involved → **archive, upload, resubmit** (may
  need Cancel Submission to unlock Resubmit).
- When unsure, default to the **less-destructive path** (reply first) and
  escalate only if the status doesn't change within a reasonable window.

---
*Promoted from auto-memory during the 2026-07-10 memory sweep.*
