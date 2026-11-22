#!/usr/bin/env bash
# Build the offline deployment bundle for dotemacs.
#
# Runs on the build machine (network available). Produces:
#   deploy/dist/dotemacs-offline-31.1-focal-x86_64.tar.xz
#
# Every component that is compiled from source is packed as a depth-1 git
# repository tarball.  The only exception is GMP (no official git) which is
# packed as the official release tarball.

set -euo pipefail

# If anything aborts unexpectedly (set -e), say so instead of silently returning
# to the prompt; the persisted state lets the next run resume.
trap 'rc=$?; if [ "$rc" -ne 0 ]; then printf "\033[1;31m[error]\033[0m build stopped (exit %s); re-run ./build.sh to resume\n" "$rc" >&2; fi' EXIT
trap 'rc=$?; if [ "$rc" -ne 0 ]; then printf "\033[1;31m[error]\033[0m command failed (exit %s): %s\n" "$rc" "$BASH_COMMAND" >&2; fi' ERR

DEPLOY_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(dirname "$DEPLOY_DIR")
# shellcheck source=lib/common.sh
source "$DEPLOY_DIR/lib/common.sh"

EMACS_VERSION=31.1
BUNDLE_VERSION=31.1.9
BUNDLE_NAME="dotemacs-offline-${EMACS_VERSION}-focal-x86_64"
DIST=${DIST:-$DEPLOY_DIR/dist}
STAGE=$DIST/$BUNDLE_NAME
WORK=${WORK:-$DIST/work}
JOBS=${JOBS:-$(nproc)}
WITH_CLANGD_PREBUILT=${WITH_CLANGD_PREBUILT:-0}
DO_VERIFY=${DO_VERIFY:-0}
KEEP_WORK=${KEEP_WORK:-0}
SKIP_TOOLS=${SKIP_TOOLS:-0}
SKIP_PACKAGES=${SKIP_PACKAGES:-0}
SKIP_GRAMMARS=${SKIP_GRAMMARS:-0}
SKIP_WHEELS=${SKIP_WHEELS:-0}

mkdir -p "$DIST"
if [ "${CLEAN:-0}" = 1 ]; then
    log "CLEAN=1: removing previous build state and artifacts"
    rm -rf "$STAGE" "$WORK"
fi
mkdir -p "$STAGE"/{repos/submodules,repos/grammars,repos/prereq,repos/patches,manifests,wheels,tarballs,tools}
mkdir -p "$WORK"/{src,pkgs,grammars,mirrors}

RESOLVED=$STAGE/manifests/resolved.txt
[ -f "$RESOLVED" ] || printf '# component\tkind\turl\tref\tcommit\n' > "$RESOLVED"

# Rewrite the record for a component instead of appending a duplicate.
record() {
    local name=$1
    { grep -v "^$name	" "$RESOLVED" 2>/dev/null || true
      printf '%s\t%s\t%s\t%s\t%s\n' "$@" ; } > "$RESOLVED.tmp"
    mv "$RESOLVED.tmp" "$RESOLVED"
}

# --- resumable step state ---------------------------------------------------
# Format: <key> <TAB> <status> <TAB> <signature> <TAB> <timestamp>
STATE=${BUILD_STATE:-$WORK/build-state}
FORCE_BUILD=${FORCE_BUILD:-0}
touch "$STATE"

step_sig() { printf '%s' "$*" | sha256sum | cut -d' ' -f1 | cut -c1-16; }
step_status() { awk -F'\t' -v k="$1" '$1==k{print $2; exit}' "$STATE" 2>/dev/null; }
step_signature() { awk -F'\t' -v k="$1" '$1==k{print $3; exit}' "$STATE" 2>/dev/null; }
step_set() { # key status [sig]
    local key=$1 st=$2 sig=${3:-}
    { grep -v "^$key	" "$STATE" 2>/dev/null || true
      printf '%s\t%s\t%s\t%s\n' "$key" "$st" "$sig" "$(date -u +%FT%TZ)" ; } > "$STATE.tmp"
    mv "$STATE.tmp" "$STATE"
}
step_done() { # key sig [artifact-check...]
    local key=$1 sig=$2
    shift 2
    [ "$FORCE_BUILD" = 1 ] && return 1
    [ "$(step_status "$key")" = ok ] || return 1
    [ "$(step_signature "$key")" = "$sig" ] || return 1
    "$@"
}
step_start() { # key sig
    local prev
    prev=$(step_status "$1")
    if [ "$prev" = failed ]; then
        warn "step $1 failed in the previous run; retrying"
    fi
    step_set "$1" running "$2"
}
step_ok() { step_set "$1" ok "$2"; }
step_fail() { step_set "$1" failed "$2"; }

# ---------------------------------------------------------------------------
# 1. Tool sources (GCC, CMake, Emacs, LLVM, ...)
# ---------------------------------------------------------------------------
tool_artifact_ok() { # kind url name
    case "$1" in
        tarball)   [ -f "$STAGE/tarballs/$(basename "$2")" ] ;;
        *)         [ -f "$STAGE/repos/$3.tar" ] ;;
    esac
}

pack_tool() { # name kind url ref
    local name=$1 kind=$2 url=$3 ref=$4 commit sig
    sig=$(step_sig "$kind|$url|$ref")
    if step_done "tool:$name" "$sig" tool_artifact_ok "$kind" "$url" "$name"; then
        log "step tool:$name: already done, skipping"
        case "$kind" in
            tarball)
                record "$name" tarball "$url" "$(basename "$url")" \
                       "$(sha256_file "$STAGE/tarballs/$(basename "$url")")" ;;
            tarball-src)
                record "$name" tarball-src "$url" "$(basename "$url")" \
                       "$(sha256_file "$WORK/tarballs/$(basename "$url")")" ;;
            git)
                record "$name" git "$url" "$ref" \
                       "$(git -C "$WORK/src/$name" rev-parse HEAD 2>/dev/null || echo unknown)" ;;
        esac
        return 0
    fi
    step_start "tool:$name" "$sig"
    case "$kind" in
        tarball)
            log "fetching tarball $name: $url"
            download "$url" "$STAGE/tarballs/$(basename "$url")" \
                || { step_fail "tool:$name" "$sig"; die "download failed: $url"; }
            record "$name" tarball "$url" "$(basename "$url")" \
                   "$(sha256_file "$STAGE/tarballs/$(basename "$url")")"
            ;;
        tarball-src)
            local tf=$WORK/tarballs/$(basename "$url")
            mkdir -p "$WORK/tarballs"
            log "fetching source tarball $name: $url"
            download "$url" "$tf" \
                || { step_fail "tool:$name" "$sig"; die "download failed: $url"; }
            rm -rf "$WORK/src/$name"; mkdir -p "$WORK/src/$name"
            tar -xf "$tf" -C "$WORK/src/$name" --strip-components=1 \
                || { step_fail "tool:$name" "$sig"; die "cannot unpack $tf"; }
            record "$name" tarball-src "$url" "$(basename "$url")" "$(sha256_file "$tf")"
            tar -C "$WORK/src/$name" -cf - . | xz -T0 -1 > "$STAGE/repos/$name.tar"
            ;;
        git)
            if [ -z "$ref" ]; then
                local resolved
                resolved=$(resolve_ref "$url") || { step_fail "tool:$name" "$sig"; die "cannot resolve ref for $name ($url)"; }
                ref=${resolved%%$'\t'*}
            fi
            log "cloning $name @ $ref (depth 1)"
            if ! clone_depth1 "$url" "$ref" "$WORK/src/$name"; then
                # Never silently replace a pinned release with the default
                # branch: that changes the shipped version.
                step_fail "tool:$name" "$sig"
                die "cannot fetch pinned $name@$ref from $url (network? re-run to resume; use FORCE_BUILD=1 to retry)"
            fi
            commit=$(git -C "$WORK/src/$name" rev-parse HEAD)
            record "$name" git "$url" "$ref" "$commit"
            tar -C "$WORK/src/$name" -cf - . | xz -T0 -1 > "$STAGE/repos/$name.tar"
            ;;
    esac
    step_ok "tool:$name" "$sig"
}


pack_tools() {
    local name kind url ref
    while IFS=$'\t' read -r name kind url ref; do
        case "$name" in ''|'#'*) continue ;; esac
        pack_tool "$name" "$kind" "$url" "$ref"
    done < "$DEPLOY_DIR/manifests/tool-refs.txt"
}

# ---------------------------------------------------------------------------
# 2. Submodules: resolve newest pin, bump the scratch dotemacs, pack mirrors
# ---------------------------------------------------------------------------
MIRROR_HOST=${MIRROR_HOST:-ubuntu22}
PACKAGES_TXT=$WORK/packages.txt

package_upstream() { # name dir
    local name=$1 dir=$2 url
    url=$(awk -v n="$name" -F'\t' '$1==n{print $2; exit}' \
              "$DEPLOY_DIR/manifests/upstreams.txt" 2>/dev/null || true)
    if [ -z "$url" ]; then
        url=$(detect_upstream "$dir" "$name" || true)
    fi
    printf '%s' "$url"
}

fast_ls() { timeout 25 git -c http.version=HTTP/1.1 ls-remote "$@" 2>/dev/null; }

mirror_url() { printf '%s:~/repos/dotemacs/packages/%s/.git' "$MIRROR_HOST" "$1"; }

latest_tag_from() { # url
    fast_ls --tags --refs "$1" \
        | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
        | sort -V | tail -1
}

write_package_worker() {
    cat > "$WORK/pack-one.sh" <<'WORKER'
#!/usr/bin/env bash
set -uo pipefail
name=$1
line=$(awk -F'\t' -v n="$name" '$1==n{print;exit}' "$WORK/pkg-list.txt")
[ -n "$line" ] || { echo "FAILED $name (not listed)" >&2; exit 1; }
IFS=$'\t' read -r _ url kind <<< "$line"
# shellcheck source=lib/common.sh
source "$DEPLOY_DIR/lib/common.sh"
fast_ls() { timeout 25 git -c http.version=HTTP/1.1 ls-remote "$@" 2>/dev/null; }
mirror_url() { printf '%s:~/repos/dotemacs/packages/%s/.git' "$MIRROR_HOST" "$1"; }
latest_tag_from() {
    fast_ls --tags --refs "$1" | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -1
}
ref=""
if [ "$kind" = upstream ] && [ -n "$url" ]; then
    head=$(fast_ls "$url" HEAD || true)
    if [ -n "$head" ]; then
        ref=$(latest_tag_from "$url" || true)
        [ -n "$ref" ] || ref=HEAD
    fi
fi
if [ -z "$ref" ]; then
    kind=mirror
    url=$(mirror_url "$name")
    ref=$(latest_tag_from "$url" || true)
    [ -n "$ref" ] || ref=HEAD
fi
if ! clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" 2>/dev/null; then
    if [ "$kind" = upstream ]; then
        url=$(mirror_url "$name"); kind=mirror
        ref=$(latest_tag_from "$url" || true); [ -n "$ref" ] || ref=HEAD
        clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" || { echo "FAILED $name" >&2; exit 1; }
    else
        echo "FAILED $name" >&2; exit 1
    fi
fi
commit=$(git -C "$WORK/pkgs/$name" rev-parse HEAD)
printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$url" "$ref" "$commit" > "$WORK/results/$name"
WORKER
    chmod +x "$WORK/pack-one.sh"
}

pkg_artifacts_ok() { # name
    [ -f "$WORK/results/$1" ] && git -C "$WORK/pkgs/$1" rev-parse HEAD >/dev/null 2>&1
}

pack_packages() {
    local dir name url ref kind commit sig line
    : > "$PACKAGES_TXT"
    mkdir -p "$WORK/results" "$WORK/pkgs"
    for dir in "$REPO_DIR"/packages/*/; do
        name=$(basename "$dir")
        url=$(package_upstream "$name" "$dir")
        kind=upstream
        [ -n "$url" ] || { kind=mirror; url=$(mirror_url "$name"); }
        local up
        up=$(awk -v n="$name" -F'\t' '$1==n{print $2; exit}' \
                 "$DEPLOY_DIR/manifests/upstreams.txt" 2>/dev/null || true)
        sig=$(step_sig "$name|${up:-mirror}")

        if step_done "pkg:$name" "$sig" pkg_artifacts_ok "$name"; then
            log "step pkg:$name: already done, skipping"
            line=$(tail -1 "$WORK/results/$name")
            printf '%s\n' "$line" >> "$PACKAGES_TXT"
            record "pkg:$name" git "$(printf '%s' "$line" | cut -f3)" \
                   "$(printf '%s' "$line" | cut -f4)" "$(printf '%s' "$line" | cut -f5)"
            continue
        fi

        step_start "pkg:$name" "$sig"
        ref=""
        if [ "$kind" = upstream ]; then
            local head tags
            head=$(fast_ls "$url" HEAD || true)
            if [ -n "$head" ]; then
                tags=$(fast_ls --tags --refs "$url" || true)
                if [ -n "$tags" ]; then
                    ref=$(printf '%s\n' "$tags" | awk -F/ '{print $NF}' \
                        | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -1 || true)
                fi
                [ -n "$ref" ] || ref=HEAD
            fi
        fi
        if [ -z "$ref" ]; then
            kind=mirror
            url=$(mirror_url "$name")
            ref=$(fast_ls --tags --refs "$url" 2>/dev/null | awk -F/ '{print $NF}' \
                    | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -1) || true
            [ -n "$ref" ] || ref=HEAD
        fi
        log "package $name <- $kind $url @ $ref"
        if ! clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" 2>/dev/null; then
            warn "depth-1 clone failed for $name; falling back to mirror"
            url=$(mirror_url "$name"); kind=mirror; ref=HEAD
            clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" \
                || { step_fail "pkg:$name" "$sig"; die "cannot fetch $name from $url"; }
        fi
        commit=$(git -C "$WORK/pkgs/$name" rev-parse HEAD)
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$url" "$ref" "$commit" \
            > "$WORK/results/$name"
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$url" "$ref" "$commit" >> "$PACKAGES_TXT"
        record "pkg:$name" git "$url" "$ref" "$commit"
        step_ok "pkg:$name" "$sig"
    done
}


dotemacs_tree_ok() { [ -f "$STAGE/repos/dotemacs.tar" ] && [ -s "$STAGE/manifests/submodules.txt" ]; }

build_dotemacs_tree() {
    local scratch=$WORK/dotemacs
    local sig
    sig=$(step_sig "dotemacs|$(sha256_file "$PACKAGES_TXT")")
    if step_done dotemacs-tree "$sig" dotemacs_tree_ok; then
        log "step dotemacs-tree: already done, skipping"
        return 0
    fi
    step_start dotemacs-tree "$sig"
    if [ -d "$scratch/.git" ] && [ -d "$scratch/packages" ] \
       && git -C "$scratch" rev-parse HEAD >/dev/null 2>&1; then
        log "reusing the existing scratch copy of dotemacs (resuming)"
    else
        log "creating scratch copy of dotemacs"
        rm -rf "$scratch"
        mkdir -p "$scratch"
        tar -C "$REPO_DIR" \
            --exclude='./deploy/dist' --exclude='./eln-cache' --exclude='./lsp.bridge.pyenv' \
            --exclude='./auto-save-list' --exclude='./transient' \
            -cf - . | tar -C "$scratch" -xf -
    fi

    local name kind url ref commit sub
    while IFS=$'\t' read -r name kind url ref commit; do
        [ -n "$name" ] || continue
        sub=$scratch/packages/$name
        # Always materialise the package from the freshly-cloned work tree.
        # The source repo may have empty submodule directories, and a previous
        # interrupted scratch copy may be incomplete; copying the cached clone
        # is deterministic and also means most packages are already at the
        # resolved commit (no extra fetch needed below).
        if [ -d "$WORK/pkgs/$name/.git" ]; then
            rm -rf "$sub"
            mkdir -p "$(dirname "$sub")"
            cp -a "$WORK/pkgs/$name" "$sub"
        elif [ ! -d "$sub" ]; then
            die "no cached clone for $name and $sub is missing"
        fi
        if ! git -C "$sub" rev-parse HEAD >/dev/null 2>&1; then
            die "package $name is not a usable git checkout: sub=$sub cached=$WORK/pkgs/$name"
        fi
        if [ "$(git -C "$sub" rev-parse HEAD 2>/dev/null || true)" = "$commit" ]; then
            log "$name: already at $commit"
            git -C "$scratch" add "packages/$name"
            continue
        fi
        log "bumping $name -> $commit"
        git -C "$sub" fetch --quiet --depth 1 "$url" "$ref" 2>/dev/null \
            || git -C "$sub" fetch --quiet --depth 1 "$url" "$commit" 2>/dev/null \
            || git -C "$sub" fetch --quiet "$url" "$commit" \
            || die "cannot fetch $name from $url"
        git -C "$sub" checkout --quiet -B offline-deploy FETCH_HEAD 2>/dev/null \
            || git -C "$sub" checkout --quiet -B offline-deploy "$commit"
        commit=$(git -C "$sub" rev-parse HEAD)
        git -C "$scratch" add "packages/$name"
    done < "$PACKAGES_TXT"

    # Update PACKAGES_TXT to the commits actually checked out (single source
    # of truth for the parent gitlink, the mirror branch and the manifest).
    local n nkind nurl nref ncommit
    : > "$WORK/packages.new"
    while IFS=$'\t' read -r n nkind nurl nref ncommit; do
        [ -n "$n" ] || continue
        ncommit=$(git -C "$scratch/packages/$n" rev-parse HEAD)
        printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$nkind" "$nurl" "$nref" "$ncommit" \
            >> "$WORK/packages.new"
    done < "$PACKAGES_TXT"
    mv "$WORK/packages.new" "$PACKAGES_TXT"

    # Drop .gitmodules sections whose path is no longer a gitlink in the index
    # (e.g. a submodule that was removed from the package list).
    while IFS=' ' read -r key path; do
        if ! git -C "$scratch" ls-files -s -- "$path" 2>/dev/null | grep -q '^160000'; then
            warn "removing stale submodule entry $key ($path)"
            git -C "$scratch" config -f .gitmodules --remove-section "${key%.path}"
        fi
    done < <(git -C "$scratch" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

    git -C "$scratch" add -A
    git -C "$scratch" -c user.name='dotemacs deploy' -c user.email='deploy@localhost' \
        -c commit.gpgsign=false commit --quiet --allow-empty -m \
        'deploy: bump submodules to latest and apply offline config' \
        || warn "nothing to commit in dotemacs scratch"

    # Pack mirrors; manifest maps gitmodules name -> path -> commit -> mirror.
    : > "$WORK/submodules-manifest.txt"
    while IFS=$'\t' read -r name kind url ref commit; do
        [ -n "$name" ] || continue
        git -C "$scratch/packages/$name" checkout --quiet -B offline-deploy "$commit" 2>/dev/null || true
        rm -rf "$WORK/mirror-$name.git"
        git clone --quiet --depth 1 --bare --no-local --branch offline-deploy \
            "file://$scratch/packages/$name" "$WORK/mirror-$name.git" \
            || die "cannot mirror $name"
        tar -C "$WORK/mirror-$name.git" -cf - . | xz -T0 -1 \
            > "$STAGE/repos/submodules/$name.git.tar"
        printf '%s\t%s\t%s\t%s\n' "$name" "$url" "$commit" "$name.git.tar" \
            >> "$WORK/submodules-manifest.txt"
    done < "$PACKAGES_TXT"

    # Map each submodule name (as in .gitmodules) to its path and mirror.
    : > "$STAGE/manifests/submodules.txt"
    while read -r key path; do
        local sname=${key#submodule.}
        sname=${sname%.path}
        local base
        base=$(basename "$path")
        local line
        line=$(awk -v n="$base" -F'\t' '$1==n{print; exit}' "$WORK/submodules-manifest.txt")
        [ -n "$line" ] || { warn "no mirror for submodule $sname ($path)"; continue; }
        local url commit tarfile
        url=$(printf '%s' "$line" | cut -f2)
        commit=$(printf '%s' "$line" | cut -f3)
        tarfile=$(printf '%s' "$line" | cut -f4)
        printf '%s\t%s\t%s\t%s\t%s\n' "$sname" "$path" "$commit" "$tarfile" "$url" \
            >> "$STAGE/manifests/submodules.txt"
    done < <(git -C "$scratch" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

    tar -C "$scratch" --exclude='./eln-cache' --exclude='./lsp.bridge.pyenv' \
        --exclude='./auto-save-list' --exclude='./transient' \
        -cf - . | xz -T0 -1 > "$STAGE/repos/dotemacs.tar"
    step_ok dotemacs-tree "$sig"
}

# ---------------------------------------------------------------------------
# 3. Tree-sitter grammars (depth 1)
# ---------------------------------------------------------------------------
grammar_pairs() {
    local el=$REPO_DIR/packages/treesit-auto/treesit-auto.el
    [ -f "$el" ] || return 0
    awk '
        /:lang / { lang=$0; sub(/.*:lang /,"",lang); gsub(/[ \047]/,"",lang); next }
        /:url "/ { if (lang != "") { u=$0; sub(/.*:url "/,"",u); sub(/".*/,"",u);
                                    print lang "\t" u; lang="" } }
    ' "$el"
}

pack_grammars() {
    local langs lang url ref
    if [ -f "$DEPLOY_DIR/manifests/grammars.txt" ]; then
        grep -v '^#' "$DEPLOY_DIR/manifests/grammars.txt" | grep -v '^$' > "$WORK/grammar-pairs.txt"
        langs=$(cut -f1 "$WORK/grammar-pairs.txt" | tr '\n' ' ')
    else
        langs=$(ls "$REPO_DIR"/tree-sitter/*.so 2>/dev/null \
                    | sed 's#.*libtree-sitter-##; s#\.so$##' | tr '\n' ' ' || true)
        [ -n "$langs" ] || { warn "no tree-sitter grammars configured (manifests/grammars.txt missing)"; return 0; }
        grammar_pairs > "$WORK/grammar-pairs.txt"
    fi
    : > "$WORK/grammar-list.txt"
    : > "$WORK/grammar-names.txt"
    for lang in $langs; do
        url=$(awk -v l="$lang" -F'\t' '$1==l{print $2; exit}' "$WORK/grammar-pairs.txt")
        if [ -z "$url" ]; then
            warn "no upstream URL known for grammar $lang"
            continue
        fi
        if [ -f "$STAGE/repos/grammars/$lang.tar" ] && [ -f "$WORK/grammar-results/$lang" ]; then
            log "step grammar:$lang: already done, skipping"
            record "grammar:$lang" git "$(cut -f2 "$WORK/grammar-results/$lang")" \
                   "$(cut -f3 "$WORK/grammar-results/$lang")" "$(cut -f4 "$WORK/grammar-results/$lang")"
            continue
        fi
        printf '%s\t%s\n' "$lang" "${url%.git}" >> "$WORK/grammar-list.txt"
        printf '%s\n' "$lang" >> "$WORK/grammar-names.txt"
    done

    cat > "$WORK/pack-one-grammar.sh" <<'GWORKER'
#!/usr/bin/env bash
set -uo pipefail
lang=${1:-}
[ -n "$lang" ] || exit 0
url=$(awk -F'\t' -v l="$lang" '$1==l{print $2;exit}' "$WORK/grammar-list.txt")
[ -n "$url" ] || exit 1
# shellcheck source=lib/common.sh
source "$DEPLOY_DIR/lib/common.sh"
fast_ls() { timeout 25 git -c http.version=HTTP/1.1 ls-remote "$@" 2>/dev/null; }
tag=$(fast_ls --tags --refs "$url" | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -1)
ref=${tag:-HEAD}
if ! clone_depth1 "$url" "$ref" "$WORK/grammars/$lang" 2>/dev/null; then
    ref=HEAD
    clone_depth1 "$url" "$ref" "$WORK/grammars/$lang" || { echo "FAILED $lang" >&2; exit 1; }
fi
commit=$(git -C "$WORK/grammars/$lang" rev-parse HEAD)
tar -C "$WORK/grammars/$lang" -cf - . | xz -T0 -1 > "$STAGE/repos/grammars/$lang.tar"
printf '%s\t%s\t%s\t%s\n' "$lang" "$url" "$ref" "$commit" > "$WORK/grammar-results/$lang"
GWORKER
    chmod +x "$WORK/pack-one-grammar.sh"
    mkdir -p "$WORK/grammar-results"
    export WORK DEPLOY_DIR STAGE
    if [ -s "$WORK/grammar-names.txt" ]; then
        xargs -P 6 -n 1 -a "$WORK/grammar-names.txt" bash "$WORK/pack-one-grammar.sh" || true
    fi
    local l
    while IFS= read -r l; do
        if [ -f "$WORK/grammar-results/$l" ]; then
            # shellcheck disable=SC2046
            record "grammar:$l" git "$(cut -f2 "$WORK/grammar-results/$l")" \
                   "$(cut -f3 "$WORK/grammar-results/$l")" "$(cut -f4 "$WORK/grammar-results/$l")"
        else
            warn "grammar $l was not packaged"
        fi
    done < "$WORK/grammar-names.txt"
}

# ---------------------------------------------------------------------------
# 4. Python wheels for lsp-bridge
# ---------------------------------------------------------------------------
wheels_ok() { [ -d "$STAGE/wheels" ] && [ "$(ls "$STAGE/wheels"/*.whl 2>/dev/null | wc -l)" -ge 4 ]; }

pack_wheels() {
    local sig
    sig=$(step_sig "wheels|$(sha256_file "$DEPLOY_DIR/manifests/python-wheels.txt")")
    if step_done wheels "$sig" wheels_ok; then
        log "step wheels: already done, skipping"
        return 0
    fi
    local -a pipcmd=()
    local cand
    for cand in "$REPO_DIR/lsp.bridge.pyenv/bin/pip" \
                "$HOME/.emacs.d/lsp.bridge.pyenv/bin/pip" \
                "$(command -v pip3 2>/dev/null || true)" \
                "$(command -v pip 2>/dev/null || true)"; do
        [ -n "$cand" ] && [ -x "$cand" ] && { pipcmd=("$cand"); break; }
    done
    if [ ${#pipcmd[@]} -eq 0 ] && python3 -m pip --version >/dev/null 2>&1; then
        pipcmd=(python3 -m pip)
    fi
    [ ${#pipcmd[@]} -gt 0 ] || die "no pip available to download wheels (install python3-pip or set up ~/.emacs.d/lsp.bridge.pyenv)"
    log "using ${pipcmd[*]} for wheel downloads"
    step_start wheels "$sig"
    rm -rf "$STAGE/wheels"; mkdir -p "$STAGE/wheels"
    log "downloading required (universal) lsp-bridge wheels"
    local req
    while IFS= read -r req; do
        case "$req" in ''|'#'*) continue ;; esac
        if ! "${pipcmd[@]}" download --quiet --no-deps --only-binary=:all: \
                --python-version 38 --platform manylinux2014_x86_64 \
                --platform manylinux_2_28_x86_64 --platform manylinux_2_17_x86_64 \
                -d "$STAGE/wheels" "$req" 2>/dev/null; then
            warn "no wheel for $req; building one from source"
            "${pipcmd[@]}" wheel --quiet --no-deps -w "$STAGE/wheels" "$req" \
                || die "cannot obtain a wheel for $req"
        fi
    done < "$DEPLOY_DIR/manifests/python-wheels.txt"
    ls "$STAGE/wheels"/*.whl >/dev/null 2>&1 || die "no wheels were produced"
    log "wheel set: $(ls "$STAGE/wheels" | wc -l) files"
    step_ok wheels "$sig"
}

# ---------------------------------------------------------------------------
# 5. Tab display fix
# ---------------------------------------------------------------------------
pack_patch() {
    local src=$REPO_DIR/../emacs
    local commit=8a81ef94438f1cafd49f7a678097f16493422f1b
    local repo_patches=$DEPLOY_DIR/patches
    local sig
    sig=$(step_sig "patch|$commit")
    patch_ok() { [ -f "$STAGE/repos/patches/0001-fix-tab-dispaly.patch" ] \
                 && [ -f "$STAGE/repos/patches/0001-fix-tab-dispaly.diff" ] \
                 && [ -f "$STAGE/repos/patches/README.org" ]; }
    if step_done patch "$sig" patch_ok; then
        log "step patch: already done, skipping"
        return 0
    fi
    step_start patch "$sig"
    mkdir -p "$STAGE/repos/patches"

    if [ -f "$repo_patches/0001-fix-tab-dispaly.patch" ] \
       && [ -f "$repo_patches/0001-fix-tab-dispaly.diff" ]; then
        # The patch is checked in, so building does not require a local Emacs
        # repository at $REPO_DIR/../emacs.
        cp "$repo_patches/0001-fix-tab-dispaly.patch" "$STAGE/repos/patches/"
        cp "$repo_patches/0001-fix-tab-dispaly.diff" "$STAGE/repos/patches/"
        if [ -f "$repo_patches/README.org" ]; then
            cp "$repo_patches/README.org" "$STAGE/repos/patches/README.org"
        fi
        log "using checked-in tab display patch"
    else
        [ -d "$src/.git" ] || die "cannot find local emacs repo at $src (and deploy/patches is missing)"
        git -C "$src" cat-file -e "$commit^{commit}" || die "commit $commit missing in $src"
        git -C "$src" format-patch -1 "$commit" --stdout \
            > "$STAGE/repos/patches/0001-fix-tab-dispaly.patch"
        git -C "$src" diff "$commit^" "$commit" -- src/term.c src/xdisp.c \
            > "$STAGE/repos/patches/0001-fix-tab-dispaly.diff"
        {
            echo "* Tab display fix patch"
            echo
            echo "Source commit: =$commit="
            echo "Author: Arto Young <arto.young@outlook.com> (authored 2022-06-23)"
            echo "Files: src/term.c, src/xdisp.c (2 files, 16 insertions)"
            echo
            echo "Applied to Emacs ${EMACS_VERSION} before =./configure= by install.sh."
        } > "$STAGE/repos/patches/README.org"
    fi

    if [ -d "$WORK/src/emacs" ]; then
        git -C "$WORK/src/emacs" apply --check -v "$STAGE/repos/patches/0001-fix-tab-dispaly.diff" \
            && log "tab patch applies cleanly to Emacs $EMACS_VERSION" \
            || die "tab patch does not apply to Emacs $EMACS_VERSION"
    else
        warn "no Emacs source tree available to verify the tab patch (skipping --check)"
    fi
    printf '%s\t%s\n' "$commit" "$(sha256_file "$STAGE/repos/patches/0001-fix-tab-dispaly.diff")" \
        > "$STAGE/manifests/patches.txt"
    step_ok patch "$sig"
}

# ---------------------------------------------------------------------------
# 6. Optional prebuilt clangd
# ---------------------------------------------------------------------------
pack_clangd_prebuilt() {
    [ "$WITH_CLANGD_PREBUILT" = 1 ] || return 0
    log "building clangd prebuilt (this takes a while)"
    local b=$WORK/clangd-build
    cmake -S "$WORK/src/llvm-project/llvm" -B "$b" -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
        -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_TERMINFO=OFF \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,\$ORIGIN/../lib"
    cmake --build "$b" --target clangd -j"$JOBS"
    mkdir -p "$STAGE/tools/clangd-prebuilt/bin" "$STAGE/tools/clangd-prebuilt/lib"
    cp "$b/bin/clangd" "$STAGE/tools/clangd-prebuilt/bin/"
    local lib
    for lib in $(ldd "$b/bin/clangd" | awk '{print $3}' | grep '^/'); do
        case "$lib" in
            /lib/x86_64-linux-gnu/*|/usr/lib/x86_64-linux-gnu/*) ;;
            *) cp -L "$lib" "$STAGE/tools/clangd-prebuilt/lib/" 2>/dev/null || true ;;
        esac
    done
    printf 'clangd\tprebuilt\t%s\n' "$(git -C "$WORK/src/llvm-project" rev-parse HEAD)" \
        > "$STAGE/manifests/clangd-prebuilt.txt"
}

# ---------------------------------------------------------------------------
# 7. Assemble bundle
# ---------------------------------------------------------------------------
assemble() {
    install -m 755 "$DEPLOY_DIR/install.sh"  "$STAGE/install.sh"
    install -m 755 "$DEPLOY_DIR/uninstall.sh" "$STAGE/uninstall.sh"
    install -m 644 "$DEPLOY_DIR/README.org"  "$STAGE/README.org"
    cp "$DEPLOY_DIR/manifests/tool-refs.txt" "$STAGE/manifests/tool-refs.txt"
    cp "$DEPLOY_DIR/manifests/upstreams.txt" "$STAGE/manifests/upstreams.txt" 2>/dev/null || true
    cp "$DEPLOY_DIR/manifests/python-wheels.txt" "$STAGE/manifests/python-wheels.txt"
    {
        echo "BUNDLE_VERSION=$BUNDLE_VERSION"
        echo "EMACS_VERSION=$EMACS_VERSION"
        echo "BUILD_DATE=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "BUILD_HOST=$(uname -n)"
        echo "JOBS=$JOBS"
    } > "$STAGE/BUILD_INFO"
    echo "$BUNDLE_VERSION" > "$STAGE/VERSION"
    ( cd "$STAGE" && find . -type f ! -name SHA256SUMS -print0 | sort -z \
        | xargs -0 sha256sum > SHA256SUMS )
}

main() {
    export XZ_OPT=${XZ_OPT:--1}
    have git && have curl && have tar && have xz || die "missing basic tools"
    log "bundle version $BUNDLE_VERSION, work dir $WORK"
    if [ -s "$STATE" ]; then
        local prev
        prev=$(awk -F'\t' '$2!="ok"{printf "%s(%s) ", $1, $2}' "$STATE")
        if [ -n "$prev" ]; then
            log "resuming; unfinished steps: $prev"
        fi
    fi
    [ "$SKIP_TOOLS" = 1 ]    || pack_tools
    [ "$SKIP_PACKAGES" = 1 ] || { pack_packages; build_dotemacs_tree; }
    [ "$SKIP_GRAMMARS" = 1 ] || pack_grammars
    [ "$SKIP_WHEELS" = 1 ]   || pack_wheels
    pack_patch
    pack_clangd_prebuilt
    assemble
    ( cd "$DIST" && tar -czf "$BUNDLE_NAME.tar.gz" "$BUNDLE_NAME" )
    sha256sum "$DIST/$BUNDLE_NAME.tar.gz" > "$DIST/$BUNDLE_NAME.tar.gz.sha256"
    log "bundle: $DIST/$BUNDLE_NAME.tar.gz"
    cat "$DIST/$BUNDLE_NAME.tar.gz.sha256"
    if [ "$DO_VERIFY" = 1 ]; then
        "$DEPLOY_DIR/lib/verify.sh" "$DIST/$BUNDLE_NAME.tar.gz" || die "verification failed"
    fi
    [ "$KEEP_WORK" = 1 ] || true
}

main "$@"
