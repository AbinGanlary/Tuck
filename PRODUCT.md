# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

People who sideload apps onto their iPhone and want a tidier Home Screen, mostly in dark mode. It should look ready to share. The job: keep many apps out of the Home Screen grid and reach any of them in one tap from a widget.

## Product Purpose

Tuck groups apps into folders and shows each folder as a Home Screen widget whose icons open the app directly. It exists because iOS folders take two taps and can't be styled. Success: the user stops using iOS folders and the widgets look like they belong on a well-kept Home Screen.

## Positioning

Opens any installed app straight from the widget by bundle ID, sideloaded apps included, with no ads and nothing locked behind a purchase.

## Operating Context

- Setup happens in the app: Folders grid → folder editor (widget-shaped preview, size picker, icon size and spacing sliders, drag to arrange) → Add apps sheet (App Store search, Installed, Apple, Custom).
- Daily use happens on the Home Screen widgets, not in the app.
- Widgets are "Folder 1" to "Folder 6" by position (per-widget configuration doesn't load when sideloaded).

## Capabilities and Constraints

- SwiftUI + WidgetKit, iOS 18 minimum; built unsigned on GitHub Actions, signed on the phone.
- Folders live in the shared keychain; no App Group, no server.
- Private APIs (open by bundle ID, installed check, system icons) mean it can't ship on the App Store as is.
- Third-party app icons come from App Store artwork; Apple's apps from the phone.

## Brand Commitments

- Name: Tuck. App icon: the teal "pocket" icon (branding/icon-tuck.svg). The user didn't make the teal palette binding for the app's interface.
- Keep the current screen structure and a native iOS feel: standard navigation, sheets and controls.
- The interface must not look plain (default Settings-list look) and must not be too colourful: app icons inside folders are the colour, the chrome stays out of their way.

## Evidence on Hand

Real folders and apps on the user's phone (screenshots in this session). No users, reviews or metrics; none may be invented.

## Product Principles

1. The widget is the product; the app is the workshop that shapes it.
2. Show it as it will look: every editor preview matches the Home Screen exactly.
3. Icons carry the colour; the interface frames them quietly.
4. Native first: anything iOS already does well, Tuck uses.
