#!/usr/bin/env bash
# dotemacs offline installer.
#
# Builds the whole stack from the bundled sources, in user space, without
# network access and without sudo:
#
#   GCC 13.5.0 -> CMake 4.5.0 -> libtree-sitter -> Emacs 31.1 (+ tab fix)
#   -> ctags -> GNU global -> clangd (LLVM) -> dotemacs + submodules
#   -> lsp-bridge python venv -> tree-sitter grammars -> launcher
#
# Usage: ./install.sh [options]
#   --prefix DIR        install prefix (default: ~/.local/opt/dotemacs)
#   --emacs-dir DIR     config location (default: ~/.emacs.d)
#   --repos-dir DIR     source/build area (default: ~/repos)
#   --bin-dir DIR       launcher directory (default: ~/.local/bin)
#   --jobs N            parallel build jobs (default: nproc)
#   --no-clangd         skip clangd entirely
#   --prebuilt-clangd   use bundled prebuilt clangd instead of building LLVM
#   --no-native-comp    configure Emacs without native compilation
#   --keep-build        keep build trees after install
#   --yes               do not ask for confirmation
#   --no-profile        do not modify ~/.profile
#   --rollback          restore a previous install
#   --purge             remove an installation (config, prefix, launchers)
#   --dry-run           print the plan and exit

set -euo pipefail

BUNDLE_DIR=$(cd "$(dirname "$0")" && pwd)

PREFIX=${PREFIX:-$HOME/.local/opt/dotemacs}
EMACS_DIR=${EMACS_DIR:-$HOME/.emacs.d}
REPOS_DIR=${REPOS_DIR:-$HOME/repos}
BIN_DIR=${BIN_DIR:-$HOME/.local/bin}
JOBS=${JOBS:-$(nproc)}
SKIP_CLANGD=0
PREBUILT_CLANGD=0
NATIVE_COMP=1
KEEP_BUILD=0
ASSUME_YES=0
NO_PROFILE=0
DRY_RUN=0
SKIP_PREFLIGHT=0
ACTION=install

GCC_PREFIX=$PREFIX/gcc-13.5
CMAKE_PREFIX=$PREFIX/cmake-4.5.0
EMACS_PREFIX=$PREFIX/emacs-31.1
BUILD=$REPOS_DIR/build
MIRRORS=$REPOS_DIR/mirrors
STATE=$PREFIX/install-state

log()  { printf '\033[1;32m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn ]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX=$2; GCC_PREFIX=$PREFIX/gcc-13.5; CMAKE_PREFIX=$PREFIX/cmake-4.5.0
                  EMACS_PREFIX=$PREFIX/emacs-31.1; STATE=$PREFIX/install-state; shift 2 ;;
        --emacs-dir) EMACS_DIR=$2; shift 2 ;;
        --repos-dir) REPOS_DIR=$2; BUILD=$REPOS_DIR/build; MIRRORS=$REPOS_DIR/mirrors; shift 2 ;;
        --bin-dir) BIN_DIR=$2; shift 2 ;;
        --jobs) JOBS=$2; shift 2 ;;
        --no-clangd) SKIP_CLANGD=1; shift ;;
        --prebuilt-clangd) PREBUILT_CLANGD=1; shift ;;
        --no-native-comp) NATIVE_COMP=0; shift ;;
        --keep-build) KEEP_BUILD=1; shift ;;
        --yes) ASSUME_YES=1; shift ;;
        --no-profile) NO_PROFILE=1; shift ;;
        --rollback) ACTION=rollback; shift ;;
        --purge) ACTION=purge; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --skip-preflight) SKIP_PREFLIGHT=1; shift ;;
        -h|--help) usage ;;
        *) die "unknown option: $1" ;;
    esac
done

export PATH="$GCC_PREFIX/bin:$CMAKE_PREFIX/bin:$BIN_DIR:$HOME/.local/bin:$PATH"

export LD_LIBRARY_PATH="$GCC_PREFIX/lib64:$GCC_PREFIX/lib:$PREFIX/lib:$HOME/.local/lib64:$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EMACS_BIN=$EMACS_PREFIX/bin/emacs
VENV=$EMACS_DIR/lsp.bridge.pyenv
TREE_SITTER_DIR=$EMACS_DIR/tree-sitter

# ---------------------------------------------------------------------------
# Rollback / purge
# ---------------------------------------------------------------------------
remove_profile_block() {
    [ -f "$HOME/.profile" ] || return 0
    awk '
        /^# dotemacs offline launcher$/ { skip = 1; next }
        skip == 1 && /^case .*\.local\/bin/ { skip = 0; next }
        { print }
    ' "$HOME/.profile" > "$HOME/.profile.tmp" && mv "$HOME/.profile.tmp" "$HOME/.profile"
}

do_rollback() {
    [ -f "$STATE" ] || die "no install state at $STATE"
    # shellcheck disable=SC1090
    . "$STATE"
    local ts; ts=$(date '+%Y%m%d-%H%M%S')
    if [ -n "${EMACS_BACKUP:-}" ] && [ -e "$EMACS_BACKUP" ]; then
        if [ -e "$EMACS_DIR" ] || [ -L "$EMACS_DIR" ]; then
            mv "$EMACS_DIR" "$EMACS_DIR.pre-rollback.$ts"
        fi
        mv "$EMACS_BACKUP" "$EMACS_DIR"
        log "restored $EMACS_DIR from $EMACS_BACKUP"
    fi
    if [ -n "${REPOS_BACKUP:-}" ] && [ -e "$REPOS_BACKUP" ]; then
        if [ -e "$REPOS_DIR" ]; then
            mv "$REPOS_DIR" "$REPOS_DIR.pre-rollback.$ts"
        fi
        mv "$REPOS_BACKUP" "$REPOS_DIR"
        log "restored $REPOS_DIR from $REPOS_BACKUP"
    fi
    if [ -f "$PREFIX/launcher-backups.txt" ]; then
        while IFS=$'\t' read -r dst bak; do
            [ -e "$dst" ] || [ -L "$dst" ] && rm -f "$dst"
            [ -e "$bak" ] && mv "$bak" "$dst"
        done < "$PREFIX/launcher-backups.txt"
    fi
    remove_profile_block
    log "rollback complete"
}

do_purge() {
    rm -f "$BIN_DIR/emacs" "$BIN_DIR/emacs31" "$BIN_DIR/emacsclient" "$BIN_DIR/dotemacs"
    if [ -L "$EMACS_DIR" ]; then rm -f "$EMACS_DIR"; fi
    rm -rf "$PREFIX"
    remove_profile_block
    log "purged prefix and launchers (config dir and backups are kept)"
}

if [ "$DRY_RUN" = 1 ]; then
    echo "dry-run: action=$ACTION prefix=$PREFIX emacs-dir=$EMACS_DIR repos=$REPOS_DIR jobs=$JOBS"
    exit 0
fi
[ "$ACTION" = rollback ] && { do_rollback; exit 0; }
[ "$ACTION" = purge ] && { do_purge; exit 0; }

# ---------------------------------------------------------------------------
# 0. preflight
# ---------------------------------------------------------------------------
check_tool() {
    local t=$1 pkg=${2:-$1}
    have "$t" || MISSING="$MISSING $pkg"
}

preflight() {
    if [ "$SKIP_PREFLIGHT" = 1 ]; then
        warn "skipping prerequisite checks (--skip-preflight)"
        mkdir -p "$PREFIX" "$REPOS_DIR" "$BIN_DIR"
        [ -f "$BUNDLE_DIR/SHA256SUMS" ] || die "bundle is incomplete (missing SHA256SUMS)"
        return 0
    fi
    MISSING=""
    [ -f /etc/os-release ] || die "cannot detect OS"
    # shellcheck disable=SC1091
    . /etc/os-release
    [ "${ID:-}" = ubuntu ] || warn "not Ubuntu ($ID); continuing anyway"
    [ "${VERSION_ID:-}" = "20.04" ] || warn "not Ubuntu 20.04 ($VERSION_ID); continuing anyway"
    [ "$(uname -m)" = x86_64 ] || die "only x86_64 is supported"

    for t in git tar xz make python3 gcc g++ autoconf automake libtoolize pkg-config makeinfo flex bison bzip2 awk; do
        check_tool "$t" "$t"
    done
    { [ -f /usr/include/gnutls/gnutls.h ] || [ -f /usr/local/include/gnutls/gnutls.h ]; } \
        || MISSING="$MISSING libgnutls28-dev"
    { [ -f /usr/include/zlib.h ] || [ -f /usr/local/include/zlib.h ]; } \
        || MISSING="$MISSING zlib1g-dev"
    { [ -f /usr/include/ncurses.h ] || [ -f /usr/local/include/ncurses.h ] \
      || [ -f "$HOME/.local/include/ncurses.h" ]; } \
        || MISSING="$MISSING libncurses-dev libtinfo-dev"
    [ -n "$MISSING" ] && die "missing build tools (install them first):$MISSING
On Ubuntu 20.04: sudo apt install build-essential git autoconf automake libtool pkg-config texinfo flex bison bzip2 zlib1g-dev libncurses-dev libtinfo-dev libffi-dev libgnutls28-dev python3 python3-venv"

    mkdir -p "$PREFIX" "$REPOS_DIR" "$BIN_DIR"
    local free_kb
    free_kb=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
    if [ "$free_kb" -lt $((25 * 1024 * 1024)) ]; then
        warn "less than 25GB free on $HOME (${free_kb}KB); build may fail"
    fi
    [ -f "$BUNDLE_DIR/SHA256SUMS" ] || die "bundle is incomplete (missing SHA256SUMS)"
    log "preflight OK (prefix=$PREFIX, emacs-dir=$EMACS_DIR, jobs=$JOBS)"
}

verify_bundle() {
    log "verifying bundle checksums"
    ( cd "$BUNDLE_DIR" && sha256sum -c --quiet SHA256SUMS ) || die "bundle checksum verification failed"
}

confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    printf 'About to build GCC 13.5, CMake, Emacs 31.1 and friends in %s (this takes 1-2 hours). Continue? [y/N] ' "$HOME"
    read -r ans
    case "$ans" in y|Y|yes|YES) ;; *) die "aborted" ;; esac
}

# ---------------------------------------------------------------------------
# 1. backup existing installation
# ---------------------------------------------------------------------------
backup_existing() {
    local ts prev_emacs prev_repos
    ts=$(date '+%Y%m%d-%H%M%S')
    prev_emacs=""; prev_repos=""
    if [ -f "$STATE" ]; then
        prev_emacs=$(sed -n 's/^EMACS_BACKUP=//p' "$STATE" | tail -1)
        prev_repos=$(sed -n 's/^REPOS_BACKUP=//p' "$STATE" | tail -1)
        warn "existing install state found; the original backups stay authoritative"
    fi

    if [ -e "$EMACS_DIR" ] || [ -L "$EMACS_DIR" ]; then
        if [ -L "$EMACS_DIR" ] && [ -n "$prev_emacs" ]; then
            run rm -f "$EMACS_DIR"
            log "removed previous install symlink $EMACS_DIR"
        else
            run mv "$EMACS_DIR" "$EMACS_DIR.bak.$ts"
            log "backed up $EMACS_DIR -> $EMACS_DIR.bak.$ts"
            [ -n "$prev_emacs" ] || prev_emacs="$EMACS_DIR.bak.$ts"
        fi
    fi
    if [ -e "$REPOS_DIR/emacs" ] || [ -e "$REPOS_DIR/dotemacs" ]; then
        run mv "$REPOS_DIR" "$REPOS_DIR.old.$ts"
        log "moved previous $REPOS_DIR to $REPOS_DIR.old.$ts"
        [ -n "$prev_repos" ] || prev_repos="$REPOS_DIR.old.$ts"
    fi
    mkdir -p "$REPOS_DIR" "$PREFIX"
    {
        echo "EMACS_BACKUP=$prev_emacs"
        echo "REPOS_BACKUP=$prev_repos"
        echo "EMACS_DIR=$EMACS_DIR"
        echo "REPOS_DIR=$REPOS_DIR"
        echo "PREFIX=$PREFIX"
        echo "INSTALL_DATE=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    } > "$STATE"
}

# ---------------------------------------------------------------------------
# 2. component builds
# ---------------------------------------------------------------------------
extract_tar() { # tar path dest
    mkdir -p "$2"
    tar -xf "$1" -C "$2"
}

build_gcc() {
    local g=$BUILD/gcc
    log "unpacking and building GCC 13.5.0"
    extract_tar "$BUNDLE_DIR/repos/gcc.tar" "$g"
    extract_dep() { # tarball-file name
        rm -rf "$g/$2"; mkdir -p "$g/$2"
        tar -xf "$BUNDLE_DIR/tarballs/$1" -C "$g/$2" --strip-components=1
    }
    extract_dep gmp-6.2.1.tar.bz2 gmp
    extract_dep mpfr-4.1.0.tar.bz2 mpfr
    extract_dep mpc-1.2.1.tar.gz mpc
    extract_dep isl-0.24.tar.bz2 isl
    (
        set -e
        cd "$g"
        ./configure --prefix="$GCC_PREFIX" --enable-languages=c,c++,jit \
            --enable-host-shared --disable-multilib --disable-bootstrap \
            --with-system-zlib --with-pkgversion='dotemacs offline gcc 13.5.0' \
            CFLAGS='-O2 -march=native -pipe' CXXFLAGS='-O2 -march=native -pipe'
        make -j"$JOBS"
        make install
    ) || die "GCC build failed (see $g)"
    "$GCC_PREFIX/bin/gcc" --version | head -1 | grep -q '13\.5\.0' || die "GCC did not install correctly"
    [ -f "$GCC_PREFIX/include/libgccjit.h" ] || die "libgccjit headers missing"
    { [ -e "$GCC_PREFIX/lib64/libgccjit.so" ] || [ -e "$GCC_PREFIX/lib/libgccjit.so" ]; } \
        || die "libgccjit shared library missing"
    log "GCC 13.5.0 installed at $GCC_PREFIX"
}

build_cmake() {
    local c=$BUILD/cmake
    log "unpacking and building CMake 4.5.0"
    extract_tar "$BUNDLE_DIR/repos/cmake.tar" "$c"
    (
        set -e
        cd "$c"
        CC=$GCC_PREFIX/bin/gcc CXX=$GCC_PREFIX/bin/g++ \
        CFLAGS='-O2 -march=native -pipe' CXXFLAGS='-O2 -march=native -pipe' \
        ./bootstrap --prefix="$CMAKE_PREFIX" --parallel="$JOBS" \
            -- -DCMAKE_BUILD_TYPE=Release -DBUILD_CursesDialog=OFF \
               -DCMAKE_USE_OPENSSL=OFF \
               -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,$GCC_PREFIX/lib64"
        [ -f Makefile ] || die "CMake bootstrap failed (see the output above)"
        make -j"$JOBS"
        make install
    ) || die "CMake build failed (see $c)"
    "$CMAKE_PREFIX/bin/cmake" --version | head -1 | grep -q '4\.5\.0' || die "CMake did not install correctly"
    log "CMake 4.5.0 installed at $CMAKE_PREFIX"
}

build_tree_sitter() {
    local s=$BUILD/tree-sitter
    log "building libtree-sitter"
    extract_tar "$BUNDLE_DIR/repos/tree-sitter.tar" "$s"
    "$CMAKE_PREFIX/bin/cmake" -S "$s" -B "$s/build" \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_PREFIX_PATH="$HOME/.local;/usr/local" \
        -DCMAKE_C_COMPILER="$GCC_PREFIX/bin/gcc" \
        -DCMAKE_CXX_COMPILER="$GCC_PREFIX/bin/g++" \
        -DCMAKE_C_FLAGS='-O2 -march=native -pipe' >/dev/null
    "$CMAKE_PREFIX/bin/cmake" --build "$s/build" -j"$JOBS" >/dev/null
    "$CMAKE_PREFIX/bin/cmake" --install "$s/build" >/dev/null
    ls "$PREFIX"/lib/libtree-sitter.so* >/dev/null 2>&1 || die "libtree-sitter not installed"
    if [ ! -f "$PREFIX/lib/pkgconfig/tree-sitter.pc" ]; then
        mkdir -p "$PREFIX/lib/pkgconfig"
        cat > "$PREFIX/lib/pkgconfig/tree-sitter.pc" <<EOF
prefix=$PREFIX
libdir=$PREFIX/lib
includedir=$PREFIX/include

Name: tree-sitter
Description: An incremental parsing system for programming tools
Version: 0.27.2
Libs: -L\${libdir} -ltree-sitter
Cflags: -I\${includedir}
EOF
    fi
    log "libtree-sitter installed"
}

apply_emacs_patch() {
    local e=$REPOS_DIR/emacs
    extract_tar "$BUNDLE_DIR/repos/emacs.tar" "$e"
    (
        set -e
        cd "$e"
        git am --abort >/dev/null 2>&1 || true
        git checkout -q -B offline/emacs-31.1 emacs-31.1
        if git am "$BUNDLE_DIR/repos/patches/0001-fix-tab-dispaly.patch" >/dev/null 2>&1; then
            log "applied tab fix patch with git am"
        else
            git am --abort >/dev/null 2>&1 || true
            git apply --check "$BUNDLE_DIR/repos/patches/0001-fix-tab-dispaly.diff" \
                || die "tab fix patch does not apply to the bundled Emacs tree"
            git apply "$BUNDLE_DIR/repos/patches/0001-fix-tab-dispaly.diff"
            git -c user.name='Arto Young' -c user.email='arto.young@outlook.com' \
                -c commit.gpgsign=false commit -qam 'fix tab dispaly'
            log "applied tab fix patch with git apply + commit"
        fi
        [ "$(git log -1 --format=%s)" = "fix tab dispaly" ] || die "tab fix commit missing"
        git show --stat --oneline HEAD | grep -q '2 files changed, 16 insertions' \
            || die "tab fix patch has unexpected content"
        grep -q 'dpvec_index' src/term.c || die "tab fix missing in src/term.c"
        grep -q 'dpvec_index' src/xdisp.c || die "tab fix missing in src/xdisp.c"
    ) || die "applying the tab fix patch failed"
}

build_emacs() {
    local e=$REPOS_DIR/emacs
    log "building Emacs 31.1 (this takes a while)"
    local ncomp=(--with-native-compilation=aot)
    [ "$NATIVE_COMP" = 1 ] || ncomp=(--with-native-compilation=no)
    (
        set -e
        cd "$e"
        CC=$GCC_PREFIX/bin/gcc CXX=$GCC_PREFIX/bin/g++ \
        CFLAGS='-O2 -march=native -pipe' \
        PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$GCC_PREFIX/lib64/pkgconfig:$GCC_PREFIX/lib/pkgconfig:$HOME/.local/lib/pkgconfig:$HOME/usr/local/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig" \
        CPPFLAGS="-I$GCC_PREFIX/include -I$PREFIX/include -I$HOME/.local/include -I$HOME/usr/local/include -I/usr/local/include" \
        LDFLAGS="-L$PREFIX/lib -L$GCC_PREFIX/lib64 -L$GCC_PREFIX/lib -L$HOME/.local/lib -L$HOME/usr/local/lib -L$HOME/usr/local/lib64 -L/usr/local/lib -L/usr/local/lib64 -Wl,-rpath,$PREFIX/lib -Wl,-rpath,$GCC_PREFIX/lib64 -Wl,-rpath,$GCC_PREFIX/lib" \
        ./autogen.sh >/dev/null
        CC=$GCC_PREFIX/bin/gcc CXX=$GCC_PREFIX/bin/g++ \
        CFLAGS='-O2 -march=native -pipe' \
        PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$GCC_PREFIX/lib64/pkgconfig:$GCC_PREFIX/lib/pkgconfig:$HOME/.local/lib/pkgconfig:$HOME/usr/local/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig" \
        CPPFLAGS="-I$GCC_PREFIX/include -I$PREFIX/include -I$HOME/.local/include -I$HOME/usr/local/include -I/usr/local/include" \
        LDFLAGS="-L$PREFIX/lib -L$GCC_PREFIX/lib64 -L$GCC_PREFIX/lib -L$HOME/.local/lib -L$HOME/usr/local/lib -L$HOME/usr/local/lib64 -L/usr/local/lib -L/usr/local/lib64 -Wl,-rpath,$PREFIX/lib -Wl,-rpath,$GCC_PREFIX/lib64 -Wl,-rpath,$GCC_PREFIX/lib" \
        ./configure --prefix="$EMACS_PREFIX" --without-x "${ncomp[@]}" \
            --with-gnutls=ifavailable \
            --with-tree-sitter --with-modules --without-compress-install \
            --with-sound=no --without-gsettings --without-libsystemd
        [ -f Makefile ] || die "Emacs configure failed (no Makefile)"
        make -j"$JOBS"
        make install
    ) || die "Emacs build failed (see $e)"
    "$EMACS_BIN" --version | head -1 | grep -q '31\.1' || die "Emacs did not install correctly"
    log "Emacs 31.1 installed at $EMACS_PREFIX"
}

build_ctags_global() {
    local d
    for d in ctags global; do
        log "building $d"
        extract_tar "$BUNDLE_DIR/repos/$d.tar" "$BUILD/$d"
        (
            set -e
            cd "$BUILD/$d"
            if [ -x ./autogen.sh ]; then ./autogen.sh >/dev/null 2>&1 || true; fi
            [ -x ./configure ] || autoreconf -fi >/dev/null 2>&1 || die "$d: autoreconf failed"
            CC=$GCC_PREFIX/bin/gcc CXX=$GCC_PREFIX/bin/g++ \
            CFLAGS='-O2 -march=native -pipe' \
            CPPFLAGS="-I$HOME/.local/include -I$HOME/usr/local/include -I/usr/local/include" \
            LDFLAGS="-L$GCC_PREFIX/lib -L$HOME/.local/lib -L$HOME/usr/local/lib -L$HOME/usr/local/lib64 -L/usr/local/lib -L/usr/local/lib64" \
            ./configure --prefix="$PREFIX" >/dev/null
            make -j"$JOBS" >/dev/null
            make install >/dev/null
        ) || die "$d build failed"
    done
    "$PREFIX/bin/ctags" --version >/dev/null 2>&1 || die "ctags missing"
    "$PREFIX/bin/global" --version >/dev/null 2>&1 || die "global missing"
    log "ctags and global installed"
}

build_clangd() {
    if [ "$SKIP_CLANGD" = 1 ]; then
        warn "skipping clangd (--no-clangd)"
        return 0
    fi
    if [ "$PREBUILT_CLANGD" = 1 ]; then
        install_prebuilt_clangd || die "--prebuilt-clangd requested but the bundle has no prebuilt clangd"
        return 0
    fi
    if [ ! -f "$BUNDLE_DIR/repos/llvm-project.tar" ]; then
        install_prebuilt_clangd || die "no llvm-project sources and no prebuilt clangd in the bundle"
        return 0
    fi
    log "building clangd from LLVM sources (this takes 40-90 minutes)"
    local l=$BUILD/llvm-project b=$BUILD/llvm-build
    extract_tar "$BUNDLE_DIR/repos/llvm-project.tar" "$l"
    "$CMAKE_PREFIX/bin/cmake" -S "$l/llvm" -B "$b" -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
        -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_TERMINFO=OFF \
        -DCMAKE_C_COMPILER="$GCC_PREFIX/bin/gcc" \
        -DCMAKE_CXX_COMPILER="$GCC_PREFIX/bin/g++" \
        -DCMAKE_C_FLAGS='-O2 -march=native -pipe' \
        -DCMAKE_CXX_FLAGS='-O2 -march=native -pipe' \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,$GCC_PREFIX/lib64" >/dev/null \
        || die "clangd configure failed"
    if ! "$CMAKE_PREFIX/bin/cmake" --build "$b" --target clangd -j"$JOBS"; then
        warn "clangd build failed; falling back to prebuilt if available"
        install_prebuilt_clangd || die "clangd build failed and no prebuilt fallback"
        return 0
    fi
    install -m 755 "$b/bin/clangd" "$PREFIX/bin/clangd"
    "$PREFIX/bin/clangd" --version >/dev/null 2>&1 || die "clangd not runnable"
    log "clangd installed"
}

install_prebuilt_clangd() {
    [ -d "$BUNDLE_DIR/tools/clangd-prebuilt/bin" ] || return 1
    cp -a "$BUNDLE_DIR/tools/clangd-prebuilt/." "$PREFIX/"
    chmod +x "$PREFIX/bin/clangd"
    log "installed prebuilt clangd"
}

# ---------------------------------------------------------------------------
# 3. config + submodules
# ---------------------------------------------------------------------------
install_config() {
    local d=$REPOS_DIR/dotemacs
    log "unpacking dotemacs and submodules"
    extract_tar "$BUNDLE_DIR/repos/dotemacs.tar" "$d"
    rm -rf "$MIRRORS"; mkdir -p "$MIRRORS"
    local name path commit tarfile url mirror
    while IFS=$'\t' read -r name path commit tarfile url; do
        [ -n "$name" ] || continue
        [ -f "$BUNDLE_DIR/repos/submodules/$tarfile" ] \
            || die "missing submodule mirror: $tarfile"
        mirror=$MIRRORS/$(basename "$tarfile" .git.tar).git
        extract_tar "$BUNDLE_DIR/repos/submodules/$tarfile" "$mirror"
    done < "$BUNDLE_DIR/manifests/submodules.txt"
    (
        cd "$d"
        git submodule init >/dev/null
        while IFS=$'\t' read -r name path commit tarfile url; do
            [ -n "$name" ] || continue
            mirror=$MIRRORS/$(basename "$tarfile" .git.tar).git
            git config --local "submodule.$name.url" "file://$mirror"
        done < "$BUNDLE_DIR/manifests/submodules.txt"
        git -c protocol.file.allow=always submodule update --init --recursive >/dev/null 2>&1 \
            || die "submodule checkout failed"
        if git status --porcelain | grep -v '^??' | grep -q .; then
            die "dotemacs working tree is dirty after submodule checkout"
        fi
    ) || die "config/submodule installation failed"
    ln -sfn "$d" "$EMACS_DIR"
    log "dotemacs installed at $EMACS_DIR -> $d"
}

install_python_env() {
    log "creating lsp-bridge python environment (using $(python3 -V 2>&1))"
    rm -rf "$VENV"
    mkdir -p "$VENV/bin"
    local site
    if python3 -m venv --without-pip "$VENV" >/dev/null 2>&1; then
        site=$(ls -d "$VENV"/lib/python*/site-packages 2>/dev/null | head -1)
    fi
    if [ -z "${site:-}" ] || [ ! -d "$site" ]; then
        rm -rf "$VENV"
        mkdir -p "$VENV/bin" "$VENV/lib/site-packages"
        site=$VENV/lib/site-packages
        cat > "$VENV/bin/python" <<EOF
#!/bin/sh
export PYTHONPATH="$site\${PYTHONPATH:+:\$PYTHONPATH}"
exec python3 "\$@"
EOF
        chmod +x "$VENV/bin/python"
        warn "python3 -m venv unavailable; using a python3 wrapper at $VENV/bin/python"
    fi

    log "installing wheels compatible with $(python3 -V 2>&1) into $site"
    python3 - "$BUNDLE_DIR/wheels" "$site" <<'PY' || die "wheel installation failed"
import os, re, sys, zipfile

wheels_dir, site = sys.argv[1], sys.argv[2]
target = sys.version_info[:2]
target_cp = "cp%d%d" % target

def parse(fn):
    parts = fn[:-4].split("-")
    if len(parts) < 5:
        return None
    return parts[0], parts[-3], parts[-2], parts[-1]

def py_ok(pytag):
    for t in pytag.split("."):
        if t in ("py3", "py2", "py2.py3"):
            return True
        m = re.fullmatch(r"cp(\d)(\d+)", t)
        if m and (int(m.group(1)), int(m.group(2))) <= target:
            return True
    return False

def abi_ok(abitag):
    if abitag == "none":
        return True
    m = re.fullmatch(r"cp(\d)(\d+).*", abitag)
    return bool(m) and (int(m.group(1)), int(m.group(2))) <= target

cands = {}
for fn in sorted(os.listdir(wheels_dir)):
    if not fn.endswith(".whl"):
        continue
    info = parse(fn)
    if not info:
        continue
    name, pytag, abitag, plat = info
    if "linux" not in plat and plat != "any":
        continue
    if not py_ok(pytag) or not abi_ok(abitag):
        continue
    cands.setdefault(name, []).append((fn, pytag, abitag))

chosen = {}
for name, lst in cands.items():
    exact = [c for c in lst if target_cp in c[1].split(".")]
    if exact:
        chosen[name] = exact[0]
        continue
    abi3 = [c for c in lst if c[2] == "abi3"]
    if abi3:
        def ver(c):
            m = re.search(r"cp(\d)(\d+)", c[1])
            return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
        chosen[name] = max(abi3, key=ver)
        continue
    pure = [c for c in lst if c[2] == "none"]
    if pure:
        chosen[name] = pure[0]

for name, (fn, pytag, abitag) in sorted(chosen.items()):
    with zipfile.ZipFile(os.path.join(wheels_dir, fn)) as z:
        z.extractall(site)
    print("installed", fn)
PY

    "$VENV/bin/python" - <<'PY' || die "required python dependencies are incomplete"
import epc, sexpdata, six, watchdog
print("required python deps OK")
PY
    "$VENV/bin/python" - <<'PY' || true
import importlib.util
mods = ["orjson", "rapidfuzz", "paramiko", "packaging"]
missing = [m for m in mods if not importlib.util.find_spec(m)]
if missing:
    print("optional python deps missing (fine): " + ", ".join(missing))
else:
    print("all optional python deps available")
PY
}

build_grammars() {
    log "compiling tree-sitter grammars"
    mkdir -p "$TREE_SITTER_DIR"
    local tar lang tmp
    for tar in "$BUNDLE_DIR"/repos/grammars/*.tar; do
        [ -e "$tar" ] || continue
        lang=$(basename "$tar" .tar)
        tmp=$BUILD/grammar-$lang
        rm -rf "$tmp"; mkdir -p "$tmp"
        tar -xf "$tar" -C "$tmp"
        local out=$TREE_SITTER_DIR/libtree-sitter-$lang.so
        if [ -f "$tmp/src/parser.c" ]; then
            local sources=("$tmp/src/parser.c")
            [ -f "$tmp/src/scanner.c" ] && sources+=("$tmp/src/scanner.c")
            "$GCC_PREFIX/bin/gcc" -O2 -fPIC -shared -std=c11 -I "$tmp/src" \
                "${sources[@]}" -o "$out" >/dev/null 2>&1 \
                || { warn "grammar $lang failed"; continue; }
        elif [ -f "$tmp/src/parser.cc" ]; then
            local srcs=("$tmp/src/parser.cc")
            [ -f "$tmp/src/scanner.cc" ] && srcs+=("$tmp/src/scanner.cc")
            "$GCC_PREFIX/bin/g++" -O2 -fPIC -shared -std=c++17 -I "$tmp/src" \
                "${srcs[@]}" -o "$out" >/dev/null 2>&1 \
                || { warn "grammar $lang failed"; continue; }
        else
            warn "grammar $lang has no parser source"; continue
        fi
    done
}

install_launcher() {
    log "installing launcher"
    mkdir -p "$PREFIX/bin" "$BIN_DIR"
    cat > "$PREFIX/bin/dotemacs" <<EOF
#!/bin/sh
PREFIX="$PREFIX"
export PATH="\$PREFIX/gcc-13.5/bin:\$PREFIX/cmake-4.5.0/bin:\$PREFIX/bin:\$HOME/.local/bin:\$PATH"
export LD_LIBRARY_PATH="\$PREFIX/gcc-13.5/lib64:\$PREFIX/gcc-13.5/lib:\$PREFIX/lib:\${LD_LIBRARY_PATH:-}"
export DOTEMACS_OFFLINE=1
export GTAGSCONF="\$PREFIX/share/gtags/gtags.conf"
exec "\$PREFIX/emacs-31.1/bin/emacs" "\$@"
EOF
    chmod +x "$PREFIX/bin/dotemacs"
    : > "$PREFIX/launcher-backups.txt"
    local ts name target dst
    ts=$(date '+%Y%m%d-%H%M%S')
    for name in emacs emacs31 emacsclient; do
        dst=$BIN_DIR/$name
        case "$name" in
            emacsclient) target=$EMACS_PREFIX/bin/emacsclient ;;
            *) target=$PREFIX/bin/dotemacs ;;
        esac
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            if [ "$(readlink -f "$dst" 2>/dev/null)" != "$(readlink -f "$target" 2>/dev/null)" ]; then
                mv "$dst" "$dst.bak.$ts"
                printf '%s\t%s\n' "$dst" "$dst.bak.$ts" >> "$PREFIX/launcher-backups.txt"
            fi
        fi
        ln -sfn "$target" "$dst"
    done
    if [ "$NO_PROFILE" = 0 ] && ! grep -q 'dotemacs offline launcher' "$HOME/.profile" 2>/dev/null; then
        {
            echo ''
            echo '# dotemacs offline launcher'
            echo 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH"; export PATH ;; esac'
        } >> "$HOME/.profile"
        log "added ~/.local/bin to ~/.profile"
    fi
}

# ---------------------------------------------------------------------------
# 4. self checks
# ---------------------------------------------------------------------------
self_check() {
    log "running self checks"
    local fail=0
    check() { if "$@" >/dev/null 2>&1; then printf '  ok   %s\n' "${*: -1}"; else printf '  FAIL %s\n' "$*"; fail=1; fi; }

    "$EMACS_BIN" --version | head -1 | grep -q '31\.1' || { echo "  FAIL emacs version"; fail=1; }
    ( cd "$REPOS_DIR/emacs" && [ "$(git log -1 --format=%s)" = "fix tab dispaly" ] ) || { echo "  FAIL tab fix"; fail=1; }
    ( cd "$REPOS_DIR/emacs" && git show --stat --oneline HEAD | grep -q '2 files changed, 16 insertions' ) \
        || { echo "  FAIL tab fix content"; fail=1; }
    ( cd "$REPOS_DIR/dotemacs" && git submodule status | grep -q '^-' ) \
        && { echo "  FAIL submodules not initialized"; fail=1; }

    local out
    out=$("$PREFIX/bin/dotemacs" --batch -Q --eval '(princ (list (treesit-language-available-p (quote c)) (treesit-language-available-p (quote cpp))))' 2>/dev/null || true)
    case "$out" in *"(t t)"*) ;; *) echo "  FAIL tree-sitter grammars: $out"; fail=1 ;; esac

    out=$("$PREFIX/bin/dotemacs" --batch -l "$EMACS_DIR/init.el" --eval '(princ "INIT-OK")' 2>/dev/null || true)
    case "$out" in *INIT-OK*) ;; *) echo "  FAIL config init"; fail=1 ;; esac

    local cf=$HOME/.cache/dotemacs-selfcheck.c
    mkdir -p "$(dirname "$cf")"
    printf 'int main(void){return 0;}\n' > "$cf"
    out=$("$PREFIX/bin/dotemacs" --batch -l "$EMACS_DIR/init.el" \
          --eval "(progn (run-hooks 'after-init-hook) (find-file \"$cf\") (princ (format \"%s\" major-mode)))" 2>/dev/null || true)
    case "$out" in *c-ts-mode*) ;; *) echo "  FAIL c-ts-mode: $out"; fail=1 ;; esac
    rm -f "$cf"

    check "$PREFIX/bin/ctags" --version
    check "$PREFIX/bin/global" --version
    [ "$SKIP_CLANGD" = 1 ] || check "$PREFIX/bin/clangd" --version
    check "$VENV/bin/python" -c 'import epc, sexpdata, six, watchdog'
    [ "$fail" = 0 ] || die "self checks failed; run '$0 --rollback' to restore the previous state"
    log "all self checks passed"
}

# ---------------------------------------------------------------------------
main() {
    confirm
    preflight
    verify_bundle
    if [ "${RESUME:-0}" = 1 ]; then
        mkdir -p "$PREFIX" "$REPOS_DIR" "$BIN_DIR"
    else
        backup_existing
    fi
    if [ "${RESUME:-0}" = 1 ] && [ -x "$GCC_PREFIX/bin/gcc" ]; then
        log "resuming: reusing GCC at $GCC_PREFIX"
    else
        build_gcc
    fi
    if [ "${RESUME:-0}" = 1 ] && [ -x "$CMAKE_PREFIX/bin/cmake" ]; then
        log "resuming: reusing CMake at $CMAKE_PREFIX"
    else
        build_cmake
    fi
    if [ "${RESUME:-0}" = 1 ] && ls "$PREFIX"/lib/libtree-sitter.so* >/dev/null 2>&1; then
        log "resuming: reusing libtree-sitter"
    else
        build_tree_sitter
    fi
    if [ "${RESUME:-0}" = 1 ] && [ -x "$EMACS_BIN" ]; then
        log "resuming: reusing Emacs at $EMACS_PREFIX"
    else
        apply_emacs_patch
        build_emacs
    fi
    if [ "${RESUME:-0}" = 1 ] && [ -x "$PREFIX/bin/ctags" ] && [ -x "$PREFIX/bin/global" ]; then
        log "resuming: reusing ctags/global"
    else
        build_ctags_global
    fi
    build_clangd
    install_config
    install_python_env
    build_grammars
    install_launcher
    self_check
    [ "$KEEP_BUILD" = 1 ] || rm -rf "$BUILD"
    log "done. Start Emacs with: $BIN_DIR/emacs (or re-login and run 'emacs')"
    log "log file: $HOME/dotemacs-deploy.log"
}

main "$@" 2>&1 | tee "$HOME/dotemacs-deploy.log"
