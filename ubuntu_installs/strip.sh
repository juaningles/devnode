#!/bin/bash
# Remove blacklisted paths and apt packages listed in a strip list (see strip.list).
# Usage: bash strip.sh <strip.list>
set -euo pipefail

LIST="$1"
test -f "$LIST"
# nullglob: patterns with no match expand to nothing; globstar: ** matches any depth
shopt -s nullglob globstar

pkgs=()
paths=()
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in
        pkg:*) pkgs+=("${line#pkg:}") ;;
        /*/*) paths+=("$line") ;;
        *) echo "strip: entries must be pkg:<name> or a path at least two levels deep: '$line'" >&2; exit 1 ;;
    esac
done < "$LIST"

installed=()
for p in "${pkgs[@]}"; do
    if dpkg -s "$p" >/dev/null 2>&1; then
        installed+=("$p")
    else
        echo "strip: package $p not installed, skipping"
    fi
done
if [ ${#installed[@]} -gt 0 ]; then
    echo "strip: purging ${installed[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove "${installed[@]}"
fi

for entry in "${paths[@]}"; do
    # unquoted so globs expand; nullglob drops patterns with no match
    for p in $entry; do
        if [ -e "$p" ] || [ -L "$p" ]; then
            echo "strip: removing $p"
            rm -rf -- "$p"
        fi
    done
done
