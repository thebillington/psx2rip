#!/usr/bin/env bash

set -e

echo "installing binary..."
sudo install -m 755 ps2rip /usr/local/bin/ps2rip

echo "setting up data directory..."
mkdir -p "$HOME/.ps2rip"

if [ ! -f "$HOME/.ps2rip/GameIndex.yaml" ]; then
  echo "downloading GameIndex..."
  curl -L -o "$HOME/.ps2rip/GameIndex.yaml" \
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

  if ! brew list --formula | grep -q "^cdrtools$"; then
    read -p "install cdrtools (toc2cue)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew install cdrtools
  else
    echo "cdrtools already installed"
  fi

else
  echo "homebrew not found, skipping optional installs"
fi

echo "installed ps2rip"