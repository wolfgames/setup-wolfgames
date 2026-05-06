#!/bin/bash
set -euo pipefail

# Install gh if not present
if ! command -v gh &>/dev/null; then
  echo "GitHub CLI not found. Installing..."
  case "$(uname -s)" in
    Darwin)
      if ! command -v brew &>/dev/null; then
        echo "Homebrew is required. Install from https://brew.sh then re-run."
        exit 1
      fi
      brew install gh
      ;;
    *)
      echo "Please install GitHub CLI from https://cli.github.com then re-run."
      exit 1
      ;;
  esac
fi

# Authenticate with required scope
if gh auth status --hostname github.com &>/dev/null; then
  gh auth refresh --hostname github.com --scopes "read:packages"
else
  gh auth login --hostname github.com --scopes "read:packages"
fi

TOKEN=$(gh auth token)
NPMRC="$HOME/.npmrc"

if grep -q "//npm.pkg.github.com/:_authToken=" "$NPMRC" 2>/dev/null; then
  sed -i.bak "s|//npm.pkg.github.com/:_authToken=.*|//npm.pkg.github.com/:_authToken=${TOKEN}|" "$NPMRC" && rm -f "$NPMRC.bak"
else
  echo "//npm.pkg.github.com/:_authToken=${TOKEN}" >> "$NPMRC"
fi

if ! grep -q "@wolfgames:registry=" "$NPMRC" 2>/dev/null; then
  echo "@wolfgames:registry=https://npm.pkg.github.com/" >> "$NPMRC"
fi

# Export NODE_AUTH_TOKEN in shell profile
case "$SHELL" in
  */zsh)  PROFILE="$HOME/.zshrc" ;;
  */bash) PROFILE="$HOME/.bashrc" ;;
  *)      PROFILE="$HOME/.profile" ;;
esac

if grep -q "export NODE_AUTH_TOKEN=" "$PROFILE" 2>/dev/null; then
  sed -i.bak "s|export NODE_AUTH_TOKEN=.*|export NODE_AUTH_TOKEN=${TOKEN}|" "$PROFILE" && rm -f "$PROFILE.bak"
else
  echo "export NODE_AUTH_TOKEN=${TOKEN}" >> "$PROFILE"
fi

echo "Done. You can now install @wolfgames packages."
echo "Restart your terminal (or run: source $PROFILE) to apply NODE_AUTH_TOKEN."
