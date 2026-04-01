# psx2rip

`psx2rip` is a lightweight Bash utility for Unix-like systems to pull PSX (Playstation 1) and PS2 games from disc into compressed CHD format. It was built and tested on macOS (Apple Silicon).

The utility will likely work on Linux using Homebrew, but has not been tested.

## Support

### PSX

PSX ripping is fully supported. Automatic game name detection is under development; planning to pull [gamedb.yaml](https://github.com/stenzek/duckstation/blob/master/data/resources/gamedb.yaml) from Duckstation. For now game titles must be entered manually.

### PS2

Both CD and DVD based PS2 titles are supported. The utility pulls `GameIndex.yaml` from [PCSX2](https://github.com/PCSX2/pcsx2/blob/master/bin/resources/GameIndex.yaml) in order to identify game titles from their Serial. This is not foolproof and not all games are listed. If you find a game that isn't listed, you should [contribute](https://pcsx2.net/docs/contributing/).

## Installation

### Pre-requisites

The installation script requires `brew` which is available on Mac and Linux:
[https://brew.sh/](https://brew.sh/)
[https://docs.brew.sh/Homebrew-on-Linux](https://docs.brew.sh/Homebrew-on-Linux)

### Installing the script

To install simply download this repository and then run `install.sh`:

```
git clone https://github.com/thebillington/psx2rip
bash install.sh
```

The install script does a few things:

1. Moves the `psx2rip` bash script to `/usr/local/bin` and makes it executable
2. Downloads the `yaml` game databases from Duckstation and PCSX2
3. Installs a few optional and required additional libraries via `brew`

### Uninstalling

To uninstall simply run the uninstall script:

```
bash uninstall.sh
```

This will delete the locally downloaded files and cleanup any libraries.

## How it works

The script automates three main steps: **disc detection → identification → ripping → compression**.

---

### 1. Dependency and environment checks

At startup, required tools are verified:

```bash
for cmd in diskutil grep awk sed dd; do
  command -v "$cmd" >/dev/null || { echo "$cmd not found"; exit 1; }
done
```

This ensures the system can:
- detect drives (`diskutil`)
- parse data (`grep`, `awk`, `sed`)
- perform raw reads (`dd`)

---

### 2. Game database availability

The script expects a local YAML database:

```bash
db="$HOME/.psx2rip/GameIndex.yaml"
[ ! -f "$db" ] && echo "GameIndex.yaml not found at $db" && exit 1
```

This is used to map **disc serial → game name**.

---

### 3. Optical drive detection

The script identifies the first external optical drive:

```bash
drive=$(diskutil list | awk '/^\/dev\/disk/ {d=$1} /\(external, physical\)/ {print d; exit}')
[ -z "$drive" ] && echo "no drive found" && exit 1
```

---

### 4. Mounting and reading disc serial

The disc is mounted and the PlayStation serial is extracted:

```bash
diskutil mountDisk "$drive" >/dev/null

serial=$(grep -o 'S[CL]ES_[0-9]\{3\}\.[0-9]\{2\}\|SLUS_[0-9]\{3\}\.[0-9]\{2\}' /Volumes/*/SYSTEM.CNF 2>/dev/null | head -n1)
[ -z "$serial" ] && echo "no serial found" && exit 1
```

The serial is normalized to match database format:

```bash
id=$(echo "$serial" | sed 's/_/-/; s/\.//')
```

---

### 5. Game name lookup

The script attempts to resolve the game name from the database:

```bash
name=$(grep -A1 "$id" "$db" 2>/dev/null | grep 'name:' | sed 's/.*name: "\(.*\)"/\1/')
```

If no match is found, the user is prompted:

```bash
if [ -z "$name" ]; then
  echo "not found $serial"
  read -p "name: " name
fi
```

---

### 6. Media type detection

The disc type is determined using:

```bash
media=$(diskutil info "$drive" | awk -F': ' '/Optical Media Type/ {print $2}')
```

This distinguishes:
- **CD** → PS1 or CD-based PS2
- **DVD** → PS2

---

### 7. Unmount before ripping

The disc is unmounted before raw access:

```bash
diskutil unmountDisk "$drive" >/dev/null
```

---

### 8. Ripping and compression

The workflow branches based on media type.

---

### CD (PSX and CD-based PS2)

CD-based discs are dumped using `cdrdao` in raw mode:

```bash
cdrdao read-cd --read-raw --datafile "$bin" "$toc"
```

This produces:
- `.bin` (raw data)
- `.toc` (track layout)

The TOC is converted into a CUE file:

```bash
toc2cue "$toc" "$cue"
```

The CUE file is then used as input:

```bash
input="$cue"
```

If `chdman` is available, the disc is compressed:

```bash
chdman createcd -i "$input" -o "$chd"
```

Temporary files are removed:

```bash
rm -f "$bin" "$toc" "$cue"
```

---

### DVD (PS2)

DVD-based discs are dumped using `dd`.

With progress display (`pv` installed):

```bash
dd if="$drive" bs=4M 2>/dev/null | pv -s "$size" > "$iso"
```

Without `pv`:

```bash
dd if="$drive" of="$iso" bs=4M status=progress
```

The ISO is then compressed:

```bash
chdman createcd -i "$iso" -o "$chd"
```

Temporary ISO is removed:

```bash
rm -f "$iso"
```

---

### Final output

- Preferred: `.chd` (compressed, space-efficient)
- Fallback: `.cue` or `.iso` if `chdman` is unavailable

The result is a clean, compressed, emulator-ready image suitable for use with DuckStation (PS1) or PCSX2 (PS2).
