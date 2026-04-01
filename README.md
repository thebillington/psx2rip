# psx2rip

`psx2rip` is a lightweight Bash utility for Unix-like systems to pull PSX (PlayStation 1) and PS2 games from disc into compressed CHD format. It was built and tested on macOS (Apple Silicon).

The utility will should work on Linux using Homebrew and with replacement of `diskutil`, but has not been tested.

---

## Support

### PSX

PSX ripping is fully supported. Automatic game name detection is supported via DuckStation’s database `gamedb.yaml`. This is not foolproof and not all games are listed. If you find a game that isn't listed, you should [contribute upstream](https://github.com/stenzek/duckstation/blob/master/README.md).

### PS2

Both CD and DVD based PS2 titles are supported. The utility pulls `GameIndex.yaml` from PCSX2 in order to identify game titles from their serial. This is not foolproof and not all games are listed. If you find a game that isn't listed, you should [contribute upstream](https://pcsx2.net/docs/contributing/).

---

## Installation

### Pre-requisites

The installation script requires `brew` which is available on macOS and Linux:

- [https://brew.sh](https://brew.sh)
- [https://docs.brew.sh/Homebrew-on-Linux](https://docs.brew.sh/Homebrew-on-Linux)

---

### Installing

```bash
git clone https://github.com/thebillington/psx2rip
bash install.sh
```

The install script:

1. Moves the `psx2rip` script to `/usr/local/bin`
2. Downloads:
   - DuckStation [gamedb.yaml](https://github.com/stenzek/duckstation/blob/master/data/resources/gamedb.yaml) (PSX)
   - PCSX2 [GameIndex.yaml](https://github.com/PCSX2/pcsx2/blob/master/bin/resources/GameIndex.yaml) (PS2)
3. Install requires tools via Homebrew
  - `rom-tools` for `chdman` - used to compress the image
  - `pv` - used to calculate percentage of rip for DVD based PS2 games
  - `cdrdao` - used to rip CD based PSX and PS2 games

---

### Uninstalling

```bash
bash uninstall.sh
```

Removes installed files and dependencies.

---

## How it works

The script automates:

**disc detection → identification → ripping → compression**

---

### 1. Dependency checks

```bash
for cmd in diskutil grep awk sed dd; do
  command -v "$cmd" >/dev/null || { echo "$cmd not found"; exit 1; }
done
```

---

### 2. Database setup

```bash
psxdb="$HOME/.psx2rip/gamedb.yaml"
ps2db="$HOME/.psx2rip/GameIndex.yaml"
```

- `gamedb.yaml` → PSX (DuckStation)
- `GameIndex.yaml` → PS2 (PCSX2)

---

### 3. Drive detection

```bash
drive=$(diskutil list | awk '/^\/dev\/disk/ {d=$1} /\(external, physical\)/ {print d; exit}')
```

---

### 4. Serial extraction

```bash
diskutil mountDisk "$drive"

serial=$(grep -o 'S[A-Z]\{3\}_[0-9]\{3\}\.[0-9]\{2\}' /Volumes/*/SYSTEM.CNF | head -n1)
```

Normalize format:

```bash
id=$(echo "$serial" | sed 's/_/-/; s/\.//')
```

---

### 5. Game lookup

PSX database:

```bash
name=$(grep -A1 "^$id:" "$psxdb" | grep 'name:' | sed 's/.*name:[[:space:]]*"\?\(.*\)"\?/\1/' | head -n1)
```

Fallback to PS2:

```bash
name=$(grep -A1 "$id" "$ps2db" | grep 'name:' | sed 's/.*name: "\(.*\)"/\1/')
```

Fallback to manual input if not found.

---

### 6. Media detection

```bash
media=$(diskutil info "$drive" | awk -F': ' '/Optical Media Type/ {print $2}')
```

- CD → PSX or CD-based PS2  
- DVD → PS2  

---

### 7. Unmount

```bash
diskutil unmountDisk "$drive"
```

---

## Ripping

### CD (PSX / CD-based PS2)

```bash
cdrdao read-cd --read-raw --datafile "$bin" "$toc"
input="$toc"
```

Produces:
- `.bin`
- `.toc`

---

### DVD (PS2)

```bash
dd if="$drive" of="$iso" bs=4M status=progress
input="$iso"
```

(Uses `pv` if available for progress.)

---

## Compression

```bash
chdman createcd -i "$input" -o "$chd"
rm -f "$iso" "$bin" "$toc"
```

If `chdman` is unavailable, raw output is kept.

---

## Output

- Preferred: `.chd`
- Fallback: `.toc` / `.iso`

Compatible with:
- DuckStation (PSX)
- PCSX2 (PS2)

---

## Notes

- Requires a compatible optical drive
- Read errors may occur on damaged discs
- Not all games exist in upstream databases
- Manual naming fallback is always available