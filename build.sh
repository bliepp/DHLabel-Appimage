#!/usr/bin/env bash
set -euo pipefail

# Reproducible Linux AppImage builder for DHLabel.
# No Windows build tools or Wine prefix are required on the build host.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DHLABEL_ICON_URL="https://raw.githubusercontent.com/manfred-mueller/DHLabel/refs/heads/master/Program/Resources/Package.png"
DOWNLOAD_DIR="${ROOT_DIR}/build/downloads"
WINE_DIR="${ROOT_DIR}/build/wine"
APPDIR="${ROOT_DIR}/build/DHLabel.AppDir"
BUILD_PREFIX="${ROOT_DIR}/build/wine-prefix"
DIST_DIR="${ROOT_DIR}/dist"

DHLABEL_RELEASE_API="https://api.github.com/repos/manfred-mueller/DHLabel/releases/latest"
WINE_RELEASE_API="https://api.github.com/repos/Kron4ek/Wine-Builds/releases/latest"
APPIMAGE_TOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "Missing '$1'. $2"
}

download() {
    local url="$1"
    local output="$2"
    echo "Downloading $(basename "$output")..."
    curl -fL --retry 3 --retry-delay 2 -o "$output" "$url"
}

need curl "Install curl."
need python3 "Install python3."
need tar "Install tar."

mkdir -p "$DOWNLOAD_DIR" "$DIST_DIR"

# extract download urls
echo "Resolving latest DHLabel release..."
DHLABEL_RELEASE_META=$(curl -fsSL "$DHLABEL_RELEASE_API")
DHLABEL_RELEASE_VERSION=$(echo "$DHLABEL_RELEASE_META" | python3 "$ROOT_DIR/release-version-info.py")
readarray -t DHLABEL_ASSET < <(echo "$DHLABEL_RELEASE_META" | python3 "$ROOT_DIR/release-assets-info.py" dhlabel)
[ "${#DHLABEL_ASSET[@]}" -eq 2 ] || die "No DHLabel Setup .exe asset found."
DHLABEL_SETUP_URL="${DHLABEL_ASSET[1]}"
DHLABEL_SETUP="${DOWNLOAD_DIR}/${DHLABEL_ASSET[0]}"

echo "Resolving latest portable Wine build..."
readarray -t WINE_ASSET < <(curl -fsSL "$WINE_RELEASE_API" | python3 "$ROOT_DIR/release-assets-info.py" wine)
[ "${#WINE_ASSET[@]}" -eq 2 ] || die "No portable Wine amd64 archive found."
WINE_ARCHIVE_URL="${WINE_ASSET[1]}"
WINE_ARCHIVE="${DOWNLOAD_DIR}/${WINE_ASSET[0]}"

# download both assets if not already downloaded
[ -f "$DHLABEL_SETUP" ] || download "$DHLABEL_SETUP_URL" "$DHLABEL_SETUP"
[ -f "$WINE_ARCHIVE" ] || download "$WINE_ARCHIVE_URL" "$WINE_ARCHIVE"

# reset .AppDir, wine directory and wine build prefix
rm -rf "$APPDIR" "$WINE_DIR" "$BUILD_PREFIX"
mkdir -p "$APPDIR/usr/share" "$WINE_DIR" "$BUILD_PREFIX"

# extracting downloaded Wine
echo "Extracting portable Wine..."
tar -xf "$WINE_ARCHIVE" -C "$WINE_DIR"
WINE_ROOT="$(find "$WINE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -n "${WINE_ROOT:-}" ] && [ -x "$WINE_ROOT/bin/wine" ] || die "Unexpected Wine archive layout."
cp -a "$WINE_ROOT" "$APPDIR/usr/share/wine"

# extract DHLabel by installing it using the build prefix and copying the result to the AppDir
echo "Extracting DHLabel installer..."
mkdir -p "$APPDIR/usr/share/dhlabel"
export WINEPREFIX="$BUILD_PREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
"$APPDIR/usr/share/wine/bin/wineboot" --init >/dev/null 2>&1 || true
"$APPDIR/usr/share/wine/bin/wine" "$DHLABEL_SETUP" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
DHLABEL_EXE="$(find "$BUILD_PREFIX" -type f -iname 'DHLabel.exe' -print -quit)"
[ -n "$DHLABEL_EXE" ] || die "DHLabel.exe was not found after extracting the installer."
cp -a "$(dirname "$DHLABEL_EXE")/." "$APPDIR/usr/share/dhlabel/"

# copy mandatory AppDir stuff
cp "$ROOT_DIR/AppRun" "$APPDIR/AppRun"
cp "$ROOT_DIR/DHLabel.desktop" "$APPDIR/DHLabel.desktop"
chmod 0755 "$APPDIR/AppRun"

download "$DHLABEL_ICON_URL" "$APPDIR/DHLabel.png"
ln -sf DHLabel.png "$APPDIR/.DirIcon"
chmod 0644 "$APPDIR/DHLabel.desktop" "$APPDIR/DHLabel.png"

APPIMAGE_NAME="${DIST_DIR}/DHLabel-${DHLABEL_RELEASE_VERSION}-x86_64.AppImage"
APPIMAGETOOL="${DOWNLOAD_DIR}/appimagetool-x86_64.AppImage"
[ -f "$APPIMAGETOOL" ] || download "$APPIMAGE_TOOL" "$APPIMAGETOOL"
chmod 0755 "$APPIMAGETOOL"

echo "Building $APPIMAGE_NAME..."
rm -f "$APPIMAGE_NAME"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$APPIMAGE_NAME"
chmod 0755 "$APPIMAGE_NAME"

echo "Built: $APPIMAGE_NAME"
python3 -c "import hashlib; print(hashlib.sha256(open('$APPIMAGE_NAME', 'rb').read()).hexdigest())" > "$APPIMAGE_NAME.sha256"
"$APPIMAGE_NAME" --appimage-help >/dev/null 2>&1 || true
