#!/usr/bin/env bash
#
# Packages this repo into storescreens.skill, the archive assistants load
# when they can't clone the repo.
#
# The archive carries exactly what SKILL.md reads at runtime: itself, every
# file under references/ it links to, and the test template it tells the
# assistant to copy. README images live in assets/ too but are deliberately
# left out - they're documentation for humans browsing GitHub, and banner.png
# alone would nearly triple the archive.
#
# Run this after any edit to SKILL.md or references/. The archive is a build
# product checked into git, so it goes stale silently otherwise.

set -euo pipefail

cd "$(dirname "$0")"

OUT="storescreens.skill"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Files the skill actually needs, relative to the repo root.
CONTENTS=(
    SKILL.md
    references/config-reference.md
    references/render-reference.md
    references/submit-reference.md
    references/upload-build-reference.md
    assets/ScreenshotTests.swift.template
)

for file in "${CONTENTS[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "error: $file is missing; skill would ship incomplete" >&2
        exit 1
    fi
done

# Every references/*.md that SKILL.md links to has to be in CONTENTS, or the
# assistant follows a link into nothing.
missing_refs=0
while read -r ref; do
    [[ -z "$ref" ]] && continue
    if ! printf '%s\n' "${CONTENTS[@]}" | grep -qxF "$ref"; then
        echo "error: SKILL.md links to $ref but it isn't in CONTENTS" >&2
        missing_refs=1
    fi
done < <(grep -o 'references/[a-z0-9-]*\.md' SKILL.md | sort -u)
[[ $missing_refs -eq 0 ]] || exit 1

for file in "${CONTENTS[@]}"; do
    mkdir -p "$STAGE/$(dirname "$file")"
    cp "$file" "$STAGE/$file"
done

rm -f "$OUT"
# -X drops extended attributes and Finder metadata so the archive is
# reproducible across machines.
(cd "$STAGE" && zip -qrX "$OLDPWD/$OUT" .)

echo "built $OUT"
unzip -l "$OUT" | tail -n +2
