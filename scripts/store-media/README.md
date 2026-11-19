# Mac App Store screenshots

The menu bar card is rendered offscreen (no screen recording or clicking needed), then framed
at 2880x1800 with a caption, a menu bar and the card dropping down from the status item.

```
./render.sh /tmp/mac-shots/wisdom Wisdom 634
./render.sh /tmp/mac-shots/motivation Motivation 24
./render.sh /tmp/mac-shots/uplift Upliftment 221
python3 make_store_screens.py /tmp/mac-shots /tmp/mac-framed
```

`render.sh <out dir> <Category> <quote id>` builds `MenuRenderer/main.swift` together with the
app's views into a minimal .app (SwiftUI needs a bundle) and writes `menu_dark.png` and
`menu_light.png` (680x680, the 340pt card at 2x). Quote ids are from `Quote-Droplet/QuotesBackup.json`.
