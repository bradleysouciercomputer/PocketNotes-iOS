# Pocket Notes for iOS

A native SwiftUI notes app for iPhone and iPad, with an adaptive full-screen interface and modern iOS styling.

## Features

- Create, edit, duplicate, share, and delete notes
- Local note storage with backward-compatible data migration
- Search titles, note content, and tags
- Organize notes into Personal, Work, and Ideas folders
- Add multiple tags to notes
- Choose a color for each note
- Pin notes and mark favorites
- Recently Deleted with restore, individual permanent deletion, and empty-trash confirmation
- Sort by recently edited, oldest first, or title
- Start quickly with Meeting Notes, Daily Journal, and To-Do List templates
- Insert checkboxes, bullets, numbered items, headings, quotes, dividers, and dates
- Word and character counts in the editor
- Adaptive one-, two-, and three-column layouts based on available screen width
- Full-height note editor and a registered adaptive launch storyboard
- Liquid Glass controls on supported iOS versions, with compatible material fallbacks
- Local-only: no account, server, or internet connection required

Notes are stored in the app's private Documents folder. They are not automatically synced to iCloud or another device. Reinstalling or deleting the app can remove its local data, so export or share important notes before doing so.

## Build an IPA without owning a Mac

This repository includes `.github/workflows/build-ipa.yml`. GitHub Actions runs Xcode on a hosted macOS machine, builds an unsigned iOS app, verifies the registered launch storyboard, and packages it as `PocketNotes.ipa`. Sideloadly signs the IPA for your Apple ID when you install it.

1. Open the **Actions** tab in this repository.
2. Select **Build Pocket Notes IPA**. The workflow also starts automatically whenever you push to `main`.
3. Open the completed workflow run and download the `PocketNotes-iOS-27-IPA` artifact.
4. Extract the downloaded ZIP to get `PocketNotes.ipa`.
5. Use Sideloadly on Windows to sign and install the IPA on your iPhone.

The workflow uses GitHub-hosted macOS runners. No Apple signing certificate or provisioning profile needs to be stored in GitHub.

## Xcode project

Open `PocketNotes.xcodeproj` in Xcode on a Mac, select the `PocketNotes` scheme, and build for an iOS device. The GitHub Actions workflow is the easier route when working from Windows.
