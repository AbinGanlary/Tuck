# Tuck design: the card wallet

Tuck's screens are the inside of a leather wallet. Folders are pockets, apps are cards tucked into them. The app icons are the only saturated colour on screen; everything else is leather.

All tokens live in `App/Theme.swift`. Views never branch on the colour scheme: every colour adapts on its own.

## Colour

| Token | Light | Dark | Use |
|---|---|---|---|
| `ground` | #E6D6C2 | #14100D | Screen background, behind lists and forms |
| `pocket` | #F1E6D8 | #221A15 | Panels, list rows, pocket backs |
| `pocketFront` | #F7EEE3 | #2B211B | Pocket fronts that sit over the icons |
| `stitch` | #A27B55 | #8C6A4C | Dashed stitch inside panel edges (75% opacity) |
| `emboss` | #3B2A1E | #F3E2C7 | Names and primary text on leather |
| `embossSoft` | #7A5E47 | #B79C80 | Secondary text, captions, slider end icons, section headers |
| `cognac` | #9A5B26 | #D9944F | The only tint: buttons, checkmarks, slider fills |

Rules:
- One accent. Cognac marks everything pressable and nothing else.
- No grey secondary text. Use `embossSoft`, tinted from the leather.
- A folder's own colour appears only as the pocket liner and in its widget, never as chrome.
- Destructive actions stay system red.

## Surfaces

- **StitchedPanel**: a continuous rounded rectangle (radius 22, cards 24, fronts 20) filled with `pocket`, a dashed stitch inset 5 pt (1.2 pt, dash 5/4), and a soft drop shadow (black 28%, radius 6, y 3).
- **walletList()**: lists and forms hide their background and sit on `ground`; their rows use `.listRowBackground(Theme.pocket)`.
- Elevation is two steps: ground, then pocket. The pocket front and the lifted widget preview are the only things above that.

## Components

- **Folder pocket card** (Folders grid, two columns, 140 pt tall): the folder colour liner at the top, the first three icons (44 pt) peeking out, and a stitched front from 54 pt carrying the name (headline, `emboss`, a 0.5 pt pressed shadow), the app count (caption, `embossSoft`), and the widget number (large title, rounded, light).
- **Desk mat** (folder editor): one StitchedPanel holding the size picker and the labelled Icon size and Spacing sliders. Below it, the widget preview at real Home Screen size with a deep shadow (black 35%, radius 14, y 8), then a two-line caption in `embossSoft`.
- **Pick row** (Add apps): 40 pt icon, name, and a bundle ID or seller in caption `embossSoft`, with a cognac `checkmark.circle.fill` / `plus.circle` trailing.

## Native first

Navigation bars, toolbars, segmented pickers, sliders, sheets, context menus and confirmation dialogs stay the system ones, so Liquid Glass buttons and the selected segment keep their iOS look. The leather sits behind them and colours them only through the tint.

## Type

System font throughout, at Dynamic Type sizes. The widget numeral uses the rounded design. Don't add custom fonts.
