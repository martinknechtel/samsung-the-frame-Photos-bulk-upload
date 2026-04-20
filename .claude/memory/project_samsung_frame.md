---
name: Samsung The Frame automation project
description: Context, setup, and hard-won lessons for the Samsung Frame photo upload automation project
type: project
originSessionId: 155a249a-c47d-433a-bcdc-c8e5b0c76691
---
Bulk upload automation from Apple iCloud Photos to Samsung The Frame TV's Art Mode.

**Why:** Samsung's mobile app only allows one-by-one upload; user wanted bulk upload of hundreds of family photos.

**How to apply:** Use this context when helping with further development of process_photos.sh, art-sync commands, or any Samsung Frame API work.

## Hardware
- Samsung The Frame 32", Full HD (1080×1920 portrait mounted)
- Hostname: samsung.fritz.box
- Photos processed to 1080×1920 (portrait mounted)

## Stack
- `samsungtvws[cli]` (Python, venv at .venv/) — WebSocket API to TV
- `imagemagick` (brew) — photo processing
- `process_photos.sh` — sorts input/ into portrait 2×2 collages and landscape stacked pairs, outputs to output/
- `art-sync output/ --sync-all --portrait-matte none` — uploads output/ to TV

## Photo processing logic (process_photos.sh)
- Portrait photos: grouped in 4s → 2×2 collage (525×945 cells, 30px gaps, center-cropped to fill cells); remainder <4 → full screen crop l/r
- Landscape photos: paired → stacked collage with equal black gaps top/middle/bottom; odd one → scale to width, pad top/bottom with black (fill top/bottom)
- Output always 1080×1920 JPEG

## Critical operational lessons

**art-sync writes state file only at end of run.**
If it hangs mid-run, no state is saved and everything re-uploads on next run (creating duplicates). For large batches, consider a manual loop with `art-upload` per file if reliability matters.

**TV approval prompt has a short window.**
First connection requires accepting a prompt on the TV remote. If too slow, the connection times out with WebSocketTimeoutException.

**art-available output is Python literal syntax (single quotes), not JSON.**
Parse with `ast.literal_eval`, not `json.loads`. Each photo appears twice (once per category) — deduplicate with a set. Only delete `MY_` IDs; `SAM-` = preinstalled/store content.
