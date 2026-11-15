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
if [ "$SKIP_TOOLS$SKIP_PACKAGES$SKIP_GRAMMARS$SKIP_WHEELS" = "0000" ] || [ ! -d "$WORK" ]; then
    rm -rf "$STAGE"
    mkdir -p "$STAGE"/{repos/submodules,repos/grammars,repos/prereq,repos/patches,manifests,wheels,tarballs,tools}
    mkdir -p "$WORK"/{src,pkgs,grammars,mirrors}
    : > "$STAGE/manifests/resolved.txt"
    printf '# component\tkind\turl\tref\tcommit\n' >> "$STAGE/manifests/resolved.txt"
fi

RESOLVED=$STAGE/manifests/resolved.txt
record() { printf '%s\t%s\t%s\t%s\t%s\n' "$@" >> "$RESOLVED"; }

# ---------------------------------------------------------------------------
# 1. Tool sources (GCC, CMake, Emacs, LLVM, ...)
# ---------------------------------------------------------------------------
pack_tool() { # name kind url ref
    local name=$1 kind=$2 url=$3 ref=$4 commit
    if [ "$kind" = tarball ]; then
        log "fetching tarball $name: $url"
        download "$url" "$STAGE/tarballs/$(basename "$url")"
        record "$name" tarball "$url" "$(basename "$url")" \
               "$(sha256_file "$STAGE/tarballs/$(basename "$url")")"
        return 0
    fi
    if [ "$kind" = tarball-src ]; then
        # Official source tarball used as a build tree (no upstream git).
        local tf=$WORK/tarballs/$(basename "$url")
        mkdir -p "$WORK/tarballs"
        log "fetching source tarball $name: $url"
        download "$url" "$tf"
        rm -rf "$WORK/src/$name"; mkdir -p "$WORK/src/$name"
        tar -xf "$tf" -C "$WORK/src/$name" --strip-components=1
        record "$name" tarball-src "$url" "$(basename "$url")" "$(sha256_file "$tf")"
        tar -C "$WORK/src/$name" -cf - . | xz -T0 -1 > "$STAGE/repos/$name.tar"
        return 0
    fi
    if [ -z "$ref" ]; then
        local resolved
        resolved=$(resolve_ref "$url") || die "cannot resolve ref for $name ($url)"
        ref=${resolved%%$'\t'*}
    fi
    log "cloning $name @ $ref (depth 1)"
    if ! clone_depth1 "$url" "$ref" "$WORK/src/$name"; then
        warn "git clone failed for $name; trying default-branch HEAD"
        clone_depth1 "$url" "$(default_head "$url")" "$WORK/src/$name" \
            || die "cannot fetch $name from $url"
    fi
    commit=$(git -C "$WORK/src/$name" rev-parse HEAD)
    record "$name" git "$url" "$ref" "$commit"
    tar -C "$WORK/src/$name" -cf - . | xz -T0 -1 > "$STAGE/repos/$name.tar"
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

pack_packages() {
    local dir name url ref kind commit
    : > "$PACKAGES_TXT"
    for dir in "$REPO_DIR"/packages/*/; do
        name=$(basename "$dir")
        url=$(package_upstream "$name" "$dir")
        kind=upstream
        if [ -z "$url" ] || ! ls_remote "$url" HEAD >/dev/null 2>&1; then
            kind=mirror
            url="$MIRROR_HOST:~/repos/dotemacs/packages/$name/.git"
            ref=$(ls_remote "$url" HEAD 2>/dev/null | awk '{print $1}' | head -1) || true
        else
            ref=$(resolve_ref "$url" | cut -f1) || ref=HEAD
        fi
        [ -n "$ref" ] || die "cannot resolve a ref for package $name"
        log "package $name <- $kind $url @ $ref"
        if ! clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" 2>/dev/null; then
            warn "depth-1 clone failed for $name; falling back to mirror"
            url="$MIRROR_HOST:~/repos/dotemacs/packages/$name/.git"
            kind=mirror
            ref=$(ls_remote "$url" HEAD 2>/dev/null | awk '{print $1}' | head -1) || true
            [ -n "$ref" ] || die "cannot fetch $name"
            clone_depth1 "$url" "$ref" "$WORK/pkgs/$name" || die "cannot fetch $name from mirror"
        fi
        commit=$(git -C "$WORK/pkgs/$name" rev-parse HEAD)
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$url" "$ref" "$commit" >> "$PACKAGES_TXT"
        record "pkg:$name" git "$url" "$ref" "$commit"
    done
}

build_dotemacs_tree() {
    local scratch=$WORK/dotemacs
    log "creating scratch copy of dotemacs"
    rm -rf "$scratch"
    mkdir -p "$scratch"
    tar -C "$REPO_DIR" \
        --exclude='./deploy/dist' --exclude='./eln-cache' --exclude='./lsp.bridge.pyenv' \
        --exclude='./auto-save-list' --exclude='./transient' \
        -cf - . | tar -C "$scratch" -xf -

    local name kind url ref commit sub
    while IFS=$'\t' read -r name kind url ref commit; do
        [ -n "$name" ] || continue
        sub=$scratch/packages/$name
        log "bumping $name -> $commit"
        git -C "$sub" fetch --quiet --depth 1 "$url" "$ref" 2>/dev/null \
            || git -C "$sub" fetch --quiet --depth 1 "$url" "$commit" 2>/dev/null \
            || git -C "$sub" fetch --quiet "$url" "$commit" \
            || die "cannot fetch $name from $url"
        git -C "$sub" checkout --quiet -B offline-deploy FETCH_HEAD 2>/dev/null \
            || git -C "$sub" checkout --quiet -B offline-deploy "$commit"
        git -C "$scratch" add "packages/$name"
    done < "$PACKAGES_TXT"

    git -C "$scratch" add -A
    git -C "$scratch" -c user.name='dotemacs deploy' -c user.email='deploy@localhost' \
        -c commit.gpgsign=false commit --quiet -m \
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
    local langs lang url ref commit
    langs=$(ls "$REPO_DIR"/tree-sitter/*.so 2>/dev/null \
                | sed 's#.*libtree-sitter-##; s#\.so$##' | tr '\n' ' ')
    grammar_pairs > "$WORK/grammar-pairs.txt"
    for lang in $langs; do
        url=$(awk -v l="$lang" -F'\t' '$1==l{print $2; exit}' "$WORK/grammar-pairs.txt")
        if [ -z "$url" ]; then
            warn "no upstream URL known for grammar $lang"
            continue
        fi
        url=${url%.git}
        ref=$(resolve_ref "$url" | cut -f1) || ref=HEAD
        log "grammar $lang <- $url @ $ref"
        if clone_depth1 "$url" "$ref" "$WORK/grammars/$lang"; then
            commit=$(git -C "$WORK/grammars/$lang" rev-parse HEAD)
            tar -C "$WORK/grammars/$lang" -cf - . | xz -T0 -1 \
                > "$STAGE/repos/grammars/$lang.tar"
            record "grammar:$lang" git "$url" "$ref" "$commit"
        else
            warn "cannot fetch grammar $lang from $url"
        fi
    done
}

# ---------------------------------------------------------------------------
# 4. Python wheels for lsp-bridge
# ---------------------------------------------------------------------------
pack_wheels() {
    local pip=$REPO_DIR/lsp.bridge.pyenv/bin/pip
    [ -x "$pip" ] || die "no pip at $pip (needed to download cp38 wheels)"
    log "downloading cp38 wheels"
    "$pip" download --quiet --only-binary=:all: --python-version 38 \
        --platform manylinux2014_x86_64 --platform manylinux_2_28_x86_64 \
        --platform manylinux_2_17_x86_64 \
        -d "$STAGE/wheels" -r "$DEPLOY_DIR/manifests/python-wheels.txt" \
        || die "wheel download failed"
}

# ---------------------------------------------------------------------------
# 5. Tab display fix
# ---------------------------------------------------------------------------
pack_patch() {
    local src=$REPO_DIR/../emacs
    local commit=8a81ef94438f1cafd49f7a678097f16493422f1b
    [ -d "$src/.git" ] || die "cannot find local emacs repo at $src"
    git -C "$src" cat-file -e "$commit^{commit}" || die "commit $commit missing in $src"
    git -C "$src" format-patch -1 "$commit" --stdout \
        > "$STAGE/repos/patches/0001-fix-tab-dispaly.patch"
    git -C "$src" diff "$commit^" "$commit" -- src/term.c src/xdisp.c \
        > "$STAGE/repos/patches/0001-fix-tab-dispaly.diff"
    {
        echo "* Tab display fix patch"
        echo
        echo "Source commit: =$commit= (local emacs repo, branch emacs30)"
        echo "Author: Arto Young <arto.young@outlook.com> (authored 2022-06-23)"
        echo "Files: src/term.c, src/xdisp.c (2 files, 16 insertions)"
        echo
        echo "Applied to Emacs ${EMACS_VERSION} before =./configure= by install.sh."
        echo "=git apply --check= against the bundled Emacs tree is verified at bundle time."
    } > "$STAGE/repos/patches/README.org"
    if [ -d "$WORK/src/emacs" ]; then
        git -C "$WORK/src/emacs" apply --check -v "$STAGE/repos/patches/0001-fix-tab-dispaly.diff" \
            && log "tab patch applies cleanly to Emacs $EMACS_VERSION" \
            || die "tab patch does not apply to Emacs $EMACS_VERSION"
    fi
    printf '%s\t%s\n' "$commit" "$(sha256_file "$STAGE/repos/patches/0001-fix-tab-dispaly.diff")" \
        > "$STAGE/manifests/patches.txt"
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
    [ "$SKIP_TOOLS" = 1 ]    || pack_tools
    [ "$SKIP_PACKAGES" = 1 ] || { pack_packages; build_dotemacs_tree; }
    [ "$SKIP_GRAMMARS" = 1 ] || pack_grammars
    [ "$SKIP_WHEELS" = 1 ]   || pack_wheels
    pack_patch
    pack_clangd_prebuilt
    assemble
    ( cd "$DIST" && tar -cJf "$BUNDLE_NAME.tar.xz" "$BUNDLE_NAME" )
    sha256sum "$DIST/$BUNDLE_NAME.tar.xz" > "$DIST/$BUNDLE_NAME.tar.xz.sha256"
    log "bundle: $DIST/$BUNDLE_NAME.tar.xz"
    cat "$DIST/$BUNDLE_NAME.tar.xz.sha256"
    [ "$DO_VERIFY" = 1 ] && { "$DEPLOY_DIR/lib/verify.sh" "$DIST/$BUNDLE_NAME.tar.xz" \
                                  || die "verification failed"; }
    [ "$KEEP_WORK" = 1 ] || true
}

main "$@"
