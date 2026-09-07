#!/usr/bin/env sh
# ---------------------------------------------------------------------------
# new-feature.sh — allocate a Spec Driven Development workspace for a feature
#
# Creates docs/specs/<NNN-feature-slug>/ seeded from .claude/templates/ and
# prints the resulting paths so the calling slash command knows where to write.
#
# Usage:
#   new-feature.sh "allow agents to close a ticket with a reason"
#   new-feature.sh --branch "..."     also create and switch to the git branch
#   new-feature.sh --current          print paths of the most recent feature
#
# Exit codes: 0 ok, 1 usage/IO error.
# ---------------------------------------------------------------------------

set -eu

SPECS_DIR="${HEXA_SPECS_DIR:-docs/specs}"
TEMPLATES_DIR="${HEXA_TEMPLATES_DIR:-.claude/templates}"
CREATE_BRANCH=0

usage() {
    echo "usage: new-feature.sh [--branch] \"<feature description>\"" >&2
    echo "       new-feature.sh --current" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# find the newest feature directory (highest NNN)
# ---------------------------------------------------------------------------
latest_dir() {
    [ -d "$SPECS_DIR" ] || return 0
    find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null \
        | sort \
        | tail -n 1
}

case "${1:-}" in
    --current)
        dir=$(latest_dir)
        if [ -z "$dir" ]; then
            echo "no feature workspace found under $SPECS_DIR" >&2
            exit 1
        fi
        echo "FEATURE_DIR=$dir"
        echo "SPEC_FILE=$dir/spec.md"
        echo "PLAN_FILE=$dir/plan.md"
        echo "TASKS_FILE=$dir/tasks.md"
        exit 0
        ;;
    --branch|-b)
        CREATE_BRANCH=1
        shift
        ;;
    --help|-h)
        usage
        ;;
esac

DESCRIPTION="${1:-}"
[ -n "$DESCRIPTION" ] || usage

# ---------------------------------------------------------------------------
# slug: lowercase, non-alphanumerics to '-', collapsed, trimmed, max 5 words
# ---------------------------------------------------------------------------
SLUG=$(printf '%s' "$DESCRIPTION" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-\{1,\}//; s/-\{1,\}$//' \
    | cut -c1-60 \
    | sed 's/-\{1,\}$//')

# keep it to the first five words so directory names stay readable
SLUG=$(printf '%s' "$SLUG" | awk -F'-' '{n=(NF>5?5:NF); s=$1; for(i=2;i<=n;i++) s=s"-"$i; print s}')

[ -n "$SLUG" ] || { echo "could not derive a slug from: $DESCRIPTION" >&2; exit 1; }

# ---------------------------------------------------------------------------
# allocate the next number
# ---------------------------------------------------------------------------
LAST=$(latest_dir)
if [ -n "$LAST" ]; then
    LAST_NUM=$(basename "$LAST" | cut -c1-3)
    NEXT=$(( $(printf '%s' "$LAST_NUM" | sed 's/^0*//; s/^$/0/') + 1 ))
else
    NEXT=1
fi
NNN=$(printf '%03d' "$NEXT")

FEATURE_ID="${NNN}-${SLUG}"
FEATURE_DIR="${SPECS_DIR}/${FEATURE_ID}"

if [ -d "$FEATURE_DIR" ]; then
    echo "feature workspace already exists: $FEATURE_DIR" >&2
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "SPEC_FILE=$FEATURE_DIR/spec.md"
    echo "PLAN_FILE=$FEATURE_DIR/plan.md"
    echo "TASKS_FILE=$FEATURE_DIR/tasks.md"
    exit 0
fi

mkdir -p "$FEATURE_DIR"

# ---------------------------------------------------------------------------
# seed from templates
# ---------------------------------------------------------------------------
TODAY=$(date +%Y-%m-%d 2>/dev/null || echo "")

# The description is user text substituted into sed's replacement side, so neutralise the
# characters sed would interpret there: the delimiter, the backslash and the "whole match" &.
SAFE_DESCRIPTION=$(printf '%s' "$DESCRIPTION" | sed 's/[\\|&]/\\&/g')

seed() {
    # seed <template-name> <target-name>
    src="${TEMPLATES_DIR}/$1"
    dst="${FEATURE_DIR}/$2"
    if [ -f "$src" ]; then
        sed "s|{{FEATURE_ID}}|${FEATURE_ID}|g; s|{{FEATURE_NAME}}|${SAFE_DESCRIPTION}|g; s|{{DATE}}|${TODAY}|g" \
            "$src" > "$dst"
    else
        printf '# %s\n\n> template %s not found — write this file by hand.\n' "$2" "$src" > "$dst"
    fi
}

seed spec.md  spec.md
seed plan.md  plan.md
seed tasks.md tasks.md

# ---------------------------------------------------------------------------
# optional branch
# ---------------------------------------------------------------------------
BRANCH=""
if [ "$CREATE_BRANCH" -eq 1 ] && git rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH="$FEATURE_ID"
    if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
        git checkout "$BRANCH" >/dev/null 2>&1 || BRANCH=""
    else
        git checkout -b "$BRANCH" >/dev/null 2>&1 || BRANCH=""
    fi
fi

echo "FEATURE_ID=$FEATURE_ID"
echo "FEATURE_DIR=$FEATURE_DIR"
echo "SPEC_FILE=$FEATURE_DIR/spec.md"
echo "PLAN_FILE=$FEATURE_DIR/plan.md"
echo "TASKS_FILE=$FEATURE_DIR/tasks.md"
[ -n "$BRANCH" ] && echo "BRANCH=$BRANCH"
exit 0
