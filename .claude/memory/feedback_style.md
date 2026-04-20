---
name: Collaboration style preferences
description: How this user prefers to work — tool choices, response style, workflow
type: feedback
originSessionId: 155a249a-c47d-433a-bcdc-c8e5b0c76691
---
Prefers shell scripts over Python where possible (uses ImageMagick via bash rather than Pillow).

**Why:** User chose `magick` CLI over Pillow when given the option ("Can you use magick instead?").

**How to apply:** Default to ImageMagick CLI in shell scripts for image processing tasks in this project. Only suggest Python when shell becomes unwieldy.

---

User updates README and diagram themselves and expects changes to be respected without revert.

**Why:** Multiple system-reminder notices about user-modified files during session.

**How to apply:** Always re-read files before editing if there's any chance they've been modified since last read.
