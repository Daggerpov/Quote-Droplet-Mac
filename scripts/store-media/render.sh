#!/bin/zsh
# Renders the menu bar card offscreen (dark and light) for a category and quote:
#   scripts/store-media/render.sh <out dir> <Category> <quote id>
# e.g. render.sh /tmp/mac-shots/wisdom Wisdom 634
# It is wrapped in a minimal .app because SwiftUI needs a bundle to run.
set -e
here=${0:A:h}
src=$here/../../Quote-Droplet
build=${TMPDIR:-/tmp}/QuoteDropletRender.app
mkdir -p $build/Contents/MacOS "$1"
cat > $build/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.daggerpov.quotedroplet.render</string>
<key>CFBundleExecutable</key><string>render</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
(cd $src && swiftc -o $build/Contents/MacOS/render QuoteView.swift QuoteClassification.swift Quote.swift New-Quote-Retrieval/*.swift $here/MenuRenderer/main.swift)
codesign -s - --force $build >/dev/null 2>&1
$build/Contents/MacOS/render $src/QuotesBackup.json "$1" "$2" "$3"
