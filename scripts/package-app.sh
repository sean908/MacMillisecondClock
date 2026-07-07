#!/bin/sh
set -eu

APP_NAME="MacMillisecondClock"
BUNDLE_ID="eu.2088.MacMillisecondClock"
APP_VERSION="0.4.0"
APP_BUILD="alpha.1"
CONFIGURATION="release"
APP_DIR="dist/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICON_SOURCE="assets/AppIcon.png"
ICONSET_DIR="dist/AppIcon.iconset"
ICON_FILE="${RESOURCES_DIR}/AppIcon.icns"

swift build -c "${CONFIGURATION}" --product "${APP_NAME}"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp ".build/${CONFIGURATION}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [ -f "${ICON_SOURCE}" ]; then
    ICON_WIDTH="$(sips -g pixelWidth "${ICON_SOURCE}" | awk '/pixelWidth/ { print $2 }')"
    ICON_HEIGHT="$(sips -g pixelHeight "${ICON_SOURCE}" | awk '/pixelHeight/ { print $2 }')"

    if [ "${ICON_WIDTH}" != "${ICON_HEIGHT}" ]; then
        echo "App icon source must be square: ${ICON_SOURCE}" >&2
        exit 1
    fi

    rm -rf "${ICONSET_DIR}"
    mkdir -p "${ICONSET_DIR}"

    sips -z 16 16 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null
    sips -z 32 32 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null
    sips -z 64 64 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null
    sips -z 256 256 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null
    sips -z 512 512 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null

    iconutil -c icns "${ICONSET_DIR}" -o "${ICON_FILE}"
fi

cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "${APP_DIR}" >/dev/null

echo "${APP_DIR}"
