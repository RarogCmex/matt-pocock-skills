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
# will not take the change (see the NOTE above). Three differences:
#   1. `in-progress/` is NOT linked. The harness here is pi, which reads
#      ~/.agents/skills directly, so a linked beta skill sits in the model's
#      skill list on every task, not only when it is being reviewed.
#      LINK_IN_PROGRESS=1 restores upstream's behaviour for a feedback session.
#   2. Beta links left over from an earlier run (or from upstream's version of
#      this script) are removed, so re-running never resurrects them.
#   3. Broken symlinks in pi's own layer (~/.pi/agent/skills) are pruned, since
#      that layer points at ~/.agents/skills and would otherwise dangle.
# Expect a conflict here on any sync that touches this file.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

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
