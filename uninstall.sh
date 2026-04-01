#!/usr/bin/env bash

set -e

echo "removing binary..."
sudo rm -f /usr/local/bin/psx2rip

echo "removing data..."
rm -rf "$HOME/.psx2rip"

if command -v brew >/dev/null; then
  echo "checking installed tools..."

  if brew list --formula | grep -q "^rom-tools$"; then
    read -p "remove rom-tools (chdman)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew uninstall rom-tools
  fi

  if brew list --formula | grep -q "^pv$"; then
    read -p "remove pv? (y/n): " confirm
    [ "$confirm" = "y" ] && brew uninstall pv
  fi

  if brew list --formula | grep -q "^cdrdao$"; then
    read -p "remove cdrdao? (y/n): " confirm
    [ "$confirm" = "y" ] && brew uninstall cdrdao
  fi

  if brew list --formula | grep -q "^cdrtools$"; then
    read -p "remove cdrtools (toc2cue)? (y/n): " confirm
    [ "$confirm" = "y" ] && brew uninstall cdrtools
  fi
fi

echo "done"