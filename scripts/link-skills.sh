#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer. Modifications to it, or requests for
# modifications, will not be approved.
#
# Links all skills in the repository into the local skill directories used by
# each agent harness:
#   - ~/.claude/skills: Claude Code
#   - ~/.agents/skills: Codex and other Agent Skills-compatible harnesses
# Each entry is a symlink into this repo, so a `git pull` is all that's needed
# to keep installed skills up to date.
#
# FORK(RarogCmex): this copy diverges from upstream on purpose, and upstream
# will not take the change (see the NOTE above). Five differences:
#   1. `in-progress/` is NOT linked. The harness here is pi, which reads
#      ~/.agents/skills directly, so a linked beta skill sits in the model's
#      skill list on every task, not only when it is being reviewed.
#      LINK_IN_PROGRESS=1 restores upstream's behaviour for a feedback session.
#   2. Beta links left over from an earlier run (or from upstream's version of
#      this script) are removed, so re-running never resurrects them.
#   3. Broken symlinks in pi's own layer (~/.pi/agent/skills) are pruned, since
#      that layer points at ~/.agents/skills and would otherwise dangle.
#   4. ~/.claude/skills is a destination only when the claude CLI is installed.
#      Upstream links both unconditionally, which on a machine without Claude
#      Code creates a directory that nothing reads.
#   5. `scripts/language-rules.md` is installed into each harness's global
#      instruction file between markers (see the tail of this script). The repo
#      is deployed on several machines, so the language rules travel in git
#      instead of being hand-pasted per machine.
# Expect a conflict here on any sync that touches this file.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# FORK: see difference 4 above. Kept as a probe rather than a hardcoded removal,
# so installing Claude Code later brings the destination back by itself.
DESTS=("$HOME/.agents/skills")
if command -v claude >/dev/null 2>&1; then
  DESTS=("$HOME/.claude/skills" "${DESTS[@]}")
fi

# Collect the repo's skills once, link into every destination. `deprecated/`
# is retired, and `misc/` is kept around but rarely used and not promoted (see
# each bucket's own README): neither belongs in a daily-driver skill
# directory, so both are skipped here, same as everywhere else non-promoted
# skills are kept out. FORK: `in-progress/` is skipped as well, unless
# LINK_IN_PROGRESS=1. Upstream links it by default because that local install is
# where its feedback loop runs; this fork wants beta out of the daily driver.
link_in_progress="${LINK_IN_PROGRESS:-0}"
excludes=(-not -path '*/node_modules/*' -not -path '*/deprecated/*' -not -path '*/misc/*')
if [ "$link_in_progress" != "1" ]; then
  excludes+=(-not -path '*/in-progress/*')
fi

names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md "${excludes[@]}" -print0)

for DEST in "${DESTS[@]}"; do
  # If $DEST is a symlink that resolves into this repo, we'd end up writing the
  # per-skill symlinks back into the repo's own skills/ tree. Detect and bail
  # out instead of polluting the working copy.
  if [ -L "$DEST" ]; then
    resolved="$(readlink -f "$DEST")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $DEST is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "linked $name -> $src ($DEST)"
  done
done

# FORK: unlink what this run excludes but an earlier run linked. Only symlinks
# resolving into this repo are touched, so skills installed from elsewhere
# (real directories, or links into another repo) survive.
if [ "$link_in_progress" != "1" ]; then
  for DEST in "${DESTS[@]}"; do
    [ -d "$DEST" ] || continue
    for entry in "$DEST"/*; do
      [ -L "$entry" ] || continue
      case "$(readlink -f "$entry")" in
        "$REPO"/skills/in-progress/*)
          rm "$entry"
          echo "unlinked beta $(basename "$entry") ($DEST)"
          ;;
      esac
    done
  done
fi

# FORK: pi layers its own symlinks on top of ~/.agents/skills. When a target
# disappears the entry dangles and pi still offers the skill, so prune the ones
# that no longer resolve.
PI_SKILLS="$HOME/.pi/agent/skills"
if [ -d "$PI_SKILLS" ]; then
  for entry in "$PI_SKILLS"/*; do
    [ -L "$entry" ] || continue
    if [ ! -e "$entry" ]; then
      rm "$entry"
      echo "pruned broken link $(basename "$entry") ($PI_SKILLS)"
    fi
  done
fi

# FORK: the language rules live in git, not in each machine's dotfiles, because
# this repo is deployed on more than one machine. They are installed into each
# harness's global instruction file between markers, idempotently: re-running
# replaces the block and never touches anything outside it.
RULES="$REPO/scripts/language-rules.md"
RULES_BEGIN="<!-- matt-pocock-skills:language-begin -->"
RULES_END="<!-- matt-pocock-skills:language-end -->"
RULES_DONE=0

install_language_rules() {
  target="$1"
  [ -f "$RULES" ] || return 0
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp)"
  if [ -f "$target" ] && grep -qF "$RULES_BEGIN" "$target"; then
    awk -v b="$RULES_BEGIN" -v e="$RULES_END" -v src="$RULES" '
      BEGIN { while ((getline line < src) > 0) block = block line "\n" }
      $0 == b { print; printf "%s", block; inside = 1; next }
      $0 == e { inside = 0 }
      !inside { print }
    ' "$target" > "$tmp"
  else
    if [ -s "$target" ]; then
      cat "$target" >> "$tmp"
      printf '\n' >> "$tmp"
    fi
    printf '%s\n' "$RULES_BEGIN" >> "$tmp"
    cat "$RULES" >> "$tmp"
    printf '%s\n' "$RULES_END" >> "$tmp"
  fi
  if cmp -s "$tmp" "$target"; then
    echo "language rules already current ($target)"
    rm -f "$tmp"
  else
    cp "$tmp" "$target"
    rm -f "$tmp"
    echo "language rules -> $target"
  fi
  RULES_DONE=$((RULES_DONE + 1))
}

# Only harnesses that are set up on this machine get a file. pi is keyed on its
# agent dir, the other two on their CLI, matching the ~/.claude/skills rule above.
if [ -d "$HOME/.pi/agent" ]; then
  install_language_rules "$HOME/.pi/agent/AGENTS.md"
fi
if command -v claude >/dev/null 2>&1; then
  install_language_rules "$HOME/.claude/CLAUDE.md"
fi
if command -v codex >/dev/null 2>&1; then
  install_language_rules "$HOME/.codex/AGENTS.md"
fi
if [ "$RULES_DONE" -eq 0 ]; then
  echo "no known harness instruction file on this machine; paste $RULES by hand"
fi
