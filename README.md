# Bulk upload from (Apple or any other) Photos to Samsung the Frame

Automate bulk photo uploads to Samsung the Frame TV's Art Mode. The mobile app allows upload only one-by-one but I wanted bulk upload. Just put your pictures from Apple Photos or any other source into the ./input folder, optimize them for a portrait mounted Samsung the Frame and bulk upload.

I use my Samsung the Frame mounted in portrait mode to my wall.
* Size 32"
* Resolution 1080 × 1920 (Full HD, portrait mounted)
* Aspect Ratio 9:16
* Hostname `samsung.fritz.box` in my case

---

## Setup

### 1. Create a Python virtual environment and install required libs

```bash
python3 -m venv .venv
source .venv/bin/activate
pip3 install "samsungtvws[cli]"
```

### 2. Install prerequisites
```bash
brew install imagemagick
```

---

## Usage

Communication happens in your local network, nothing is uploaded to the Internet. For every API call, the TV will show a prompt asking you to allow access. Accept it on the TV.

### Optimize photos for Samsung the Frame in portrait mounting

```bash
bash process_photos.sh
```

The script collects all photos from ./input/ and crops portrait photos, makes landscape photos into collages of 2, resizes to the native resolution.

```
   Portrait 4x     Remaining         Landscape pair                  Landscape solo
    ┌───────┐      <4 Portraits
   ┌┴──────┐│      ┌───────┐         ┌────────┐  ┌────────┐          ┌────────┐
   │▒     ▒││      │▒     ▒│         │▒      ▒│  │▒      ▒│          │        │
   │▒photo▒││      │▒photo▒│         │▒  p1  ▒│  │▒  p2  ▒│          │ photo  │
   │▒  1  ▒├┘      │▒     ▒│         └────────┘  └────────┘          └────────┘
   └───────┘       └───────┘               │                              │
       │               │                   │                              │
       ▼ 2x2 collage   ▼ crop l/r          ▼ 2x1 collage                  ▼ fill top/bottom
  ┌─────────┐      ┌─────────┐         ┌─────────┐                   ┌─────────┐
  │    █    │      │         │         │         │                   │█████████│ ← black
  │ p1 █ p2 │      │         │         │ photo 1 │ ← photo 1         │█████████│
  │    █    │      │  photo  │         │         │                   │         │
  │█████████│←30px │         │         │█████████│ ← 30px black      │  photo  │
  │    █    │      │         │         │         │ ← photo 2         │         │
  │ p3 █ p4 │      │         │         │ photo 2 │                   │█████████│
  │    █    │      │         │         │         │                   │█████████│ ← black
  └─────────┘      └─────────┘         └─────────┘                   └─────────┘
   1080×1920       1080×1920           1080×1920                     1080×1920

```

### Sync processed photos to the TV

```bash
source .venv/bin/activate
samsungtv --host samsung.fritz.box art-sync output/ --sync-all --portrait-matte none
```
This uses a local state file `./output/.samsungtvws-art-sync.json` to track uploads.
- Re-running uploads new photos / deletes removed photos / prevents uploading unchanged photos repeatedly. 
- If connection timed out, happened to me once for >180 photos when Samsung was in Art Mode and powered off after some time, just go to the main menu to keep it powered on and upload again.
- Can be overridden with `--refresh`. 

### Delete all uploaded photos

```bash
source .venv/bin/activate
samsungtv --host samsung.fritz.box art-available \
  | python3 -c "
import sys, ast
items = ast.literal_eval(sys.stdin.read())
ids = {i['content_id'] for i in items if i['content_id'].startswith('MY_')}
print(' '.join(ids))
" \
  | xargs samsungtv --host samsung.fritz.box art-delete-list
```

Notes:
- `art-available` lists all photos currently on the TV. `python3` extracts their content IDs, which are then passed to `art-delete-list` in one call. This removes everything uploaded — including photos added outside of `art-sync`.
- Only `MY_` IDs are selected — `SAM-` preinstalled/store content is left untouched