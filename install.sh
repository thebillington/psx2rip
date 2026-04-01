#!/usr/bin/env bash

set -e

echo "installing binary..."
sudo install -m 755 psx2rip /usr/local/bin/psx2rip

echo "setting up data directory..."
data_dir="$HOME/.psx2rip"
mkdir -p "$data_dir"

if [ ! -f "$data_dir/gamedb.yaml" ]; then
  echo "downloading Duckstation gamedb..."
  curl -L -o "$data_dir/gamedb.yaml" \
    https://raw.githubusercontent.com/stenzek/duckstation/master/data/resources/gamedb.yaml
fi

if [ ! -f "$data_dir/GameIndex.yaml" ]; then
  echo "downloading PCSX2 GameIndex..."
  curl -L -o "$data_dir/GameIndex.yaml" \
    https://raw.githubusercontent.com/PCSX2/pcsx2/master/bin/resources/GameIndex.yaml
fi

if command -v brew >/dev/null; then

  if ! brew list --formula | grep -q "^rom-tools$"; then
    read -p "install chdman (rom-tools)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew install rom-tools
  else
    echo "rom-tools already installed"
  fi

  if ! brew list --formula | grep -q "^pv$"; then
    read -p "install pv (progress bar)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew install pv
  else
    echo "pv already installed"
  fi

  if ! brew list --formula | grep -q "^cdrdao$"; then
    read -p "install cdrdao (CD ripping)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew install cdrdao
  else
    echo "cdrdao already installed"
  fi

else
  echo "homebrew not found, skipping optional installs"
fi

echo "installed psx2rip"
