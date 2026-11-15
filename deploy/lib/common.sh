# -*- mode: sh; lexical-binding: t -*-
# Shared helpers for the dotemacs offline bundle tooling.
#
# This file is sourced by deploy/build.sh (build machine). The generated
# install.sh must stay self-contained, so it does not source this file.

set -o pipefail

: "${GIT:=git}"
: "${CURL:=curl}"

log()  { printf '\033[1;34m[build]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

retry() {
    local n="${RETRY_ATTEMPTS:-2}" delay="${RETRY_DELAY:-2}" i=1
    while :; do
        if "$@"; then return 0; fi
        if [ "$i" -ge "$n" ]; then
            warn "giving up after $n attempts: $*"
            return 1
        fi
        warn "attempt $i/$n failed: $*; retrying in ${delay}s"
        sleep "$delay"
        i=$((i + 1))
        delay=$((delay * 2))
    done
}

# Git over flaky TLS: force HTTP/1.1 and retry.
git_net() {
    retry timeout 45 "$GIT" -c http.version=HTTP/1.1 -c http.lowSpeedLimit=1024 \
          -c http.lowSpeedTime=30 "$@"
}

ls_remote() { # ls_remote URL [extra args...]
    local url=$1; shift
    git_net ls-remote "$@" "$url"
}

# Echo the newest semver-ish tag of URL (v1.2.3 / 1.2.3), or nothing.
latest_tag() {
    local url=$1
    ls_remote "$url" --tags --refs 2>/dev/null \
        | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+\.[0-9]+(\.[0-9]+)?$' \
        | sort -V | tail -1
}

default_head() { # commit of the default branch
    local url=$1
    ls_remote "$url" HEAD 2>/dev/null | awk '{print $1}' | head -1
}

sha256_file() { sha256sum "$1" | awk '{print $1}'; }

download() { # download URL DEST
    local url=$1 dest=$2
    retry "$CURL" -fsSL --retry 3 --retry-delay 2 -o "$dest.part" "$url" \
        && mv "$dest.part" "$dest"
}

# Depth-1 clone of URL at REF (tag/branch/commit) into DEST.
# A commit must be reachable from some ref; we therefore fetch by ref
# when possible and fall back to fetch-by-commit.
clone_depth1() { # URL REF DEST
    local url=$1 ref=$2 dest=$3
    rm -rf "$dest"
    if printf '%s' "$ref" | grep -qE '^[0-9a-f]{40}$'; then
        # A commit: the default branch tip is expected to be that commit.
        if git_net clone --quiet --depth 1 "$url" "$dest" 2>/dev/null \
           && [ "$(git -C "$dest" rev-parse HEAD)" = "$ref" ]; then
            return 0
        fi
    elif git_net clone --quiet --depth 1 --single-branch --branch "$ref" "$url" "$dest" 2>/dev/null; then
        return 0
    fi
    # Fallback: init + fetch the exact commit (works for bare commit refs).
    mkdir -p "$dest"
    git -C "$dest" init --quiet
    git_net -C "$dest" remote add origin "$url" 2>/dev/null || true
    git_net -C "$dest" fetch --quiet --depth 1 origin "$ref" \
        && git -C "$dest" checkout --quiet FETCH_HEAD
}

# Pick the newest release tag for a repo, else the default branch HEAD.
resolve_ref() { # URL -> "ref<TAB>kind"
    local url=$1 tag head
    tag=$(latest_tag "$url") || true
    if [ -n "$tag" ]; then
        printf '%s\ttag\n' "$tag"
        return 0
    fi
    head=$(default_head "$url") || true
    [ -n "$head" ] || return 1
    printf '%s\tcommit\n' "$head"
}

# Extract github/gitlab/codeberg repo URLs from a package tree, ranked.
detect_upstream() { # DIR NAME
    local dir=$1 name=$2
    {
        grep -rhoE 'https?://(github|gitlab|codeberg|git\.savannah\.gnu)\.(com|org|gnu)/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' \
            "$dir" --include='*.el' --include='*.md' --include='*.org' --include='*.txt' 2>/dev/null || true
    } | sed -E 's#^http://#https://#; s#\.git$##' \
      | sed -E 's#(https://github\.com/[^/]+/[^/#]+).*#\1#; s#(https://gitlab\.com/[^/]+/[^/#]+).*#\1#; s#(https://codeberg\.org/[^/]+/[^/#]+).*#\1#' \
      | grep -vE '/issues|/pull|/wiki|/blob|/tree|/commit' \
      | sort | uniq -c | sort -rn \
      | awk -v n="$name" '
          { url=$2; cnt=$1
            base=url; sub(/.*\//, "", base)
            bonus=(index(tolower(base), tolower(n)) || index(tolower(n), tolower(base))) ? 100 : 0
            print cnt + bonus, url }
        ' | sort -rn | head -1 | awk '{print $2}'
}
