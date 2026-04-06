# Samsung The Frame — Art Mode Photo Upload

Automate bulk photo uploads to Samsung The Frame TV's Art Mode using `samsungtvws`.

**TV:** `samsung.fritz.box` / `192.168.178.152`

---

## Setup

### 1. Create a virtual environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install samsungtvws

```bash
pip3 install "samsungtvws[cli]"
```

### 3. First-time TV authentication

On the first connection, the TV will show a prompt asking you to allow access. Accept it on the TV.

---

## Usage

### Check available matte/border styles

```bash
samsungtv --host samsung.fritz.box art-matte-list
```

### Upload all photos from a folder

```bash
samsungtv --host samsung.fritz.box art-sync photos/ --upload-all --matte shadowbox_polar
```

Uses a local state file to track uploads — re-running only uploads new photos.

### Sync (upload new + delete removed photos)

```bash
samsungtv --host samsung.fritz.box art-sync photos/ --sync-all --matte shadowbox_polar
```

### Upload a single photo

```bash
samsungtv --host samsung.fritz.box art-upload photos/example.jpg --matte shadowbox_polar
```

### No border/matte

```bash
samsungtv --host samsung.fritz.box art-sync photos/ --upload-all --matte none
```

---

## Slideshow settings

```bash
# Shuffled slideshow, rotate every 30 minutes, from uploaded photos
samsungtv --host samsung.fritz.box art-slideshow-set --category-id MY-C0002 --duration 30 --shuffle
```

| Category ID | Content |
|---|---|
| `MY-C0002` | My Pictures (uploaded photos) |
| `MY-C0004` | Favorites |
| `MY-C0008` | Samsung Art Store |

---

## What can be controlled via CLI

| Setting | Supported |
|---|---|
| Bulk upload from folder | Yes (`art-sync`) |
| Matte/passepartout style | Yes (`--matte <style>`) |
| No border | Yes (`--matte none`) |
| Photo filters | Yes (`art-photo-filter-set`) |
| Slideshow duration & shuffle | Yes (`art-slideshow-set`) |
| Art Mode on/off | Yes (`art-mode --on/--off`) |
| Brightness | Yes (Python API) |
| Border thickness / custom color | No — use the Samsung Frame app |

---

## Workflow: iCloud Photos

1. Export photos from iCloud/Apple Photos to the `photos/` folder
2. Run `art-sync` to upload new photos to the TV:

```bash
source .venv/bin/activate
samsungtv --host samsung.fritz.box art-sync photos/ --upload-all --matte shadowbox_polar
```
