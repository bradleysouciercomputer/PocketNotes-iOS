# Pocket Notes for iOS

A small native SwiftUI note-taking app for iPhone and iPad.

## Features

- Create, edit, and delete notes
- Notes save locally on the device as you leave the editor
- Search note titles and content
- Pin important notes
- Sort pinned notes first, then by most recently edited
- Native iOS interface with light/dark appearance support
- No account, server, or internet connection required

Notes are stored in the app's private Documents folder. They are not automatically synced to iCloud or another device.

## Build an IPA without owning a Mac

This repository includes `.github/workflows/build-ipa.yml`. GitHub Actions runs Xcode on a hosted macOS machine, builds an unsigned iOS app, and packages it as `PocketNotes.ipa`. Sideloadly signs the IPA for your Apple ID when you install it.

1. Open the **Actions** tab in this repository.
2. Select **Build Pocket Notes IPA**. The workflow also starts automatically whenever you push to `main`.
3. Open the completed workflow run and download the **PocketNotes-IPA** artifact.
4. Extract the downloaded ZIP to get `PocketNotes.ipa`.
5. Use Sideloadly on Windows to sign and install the IPA on your iPhone.

The workflow uses GitHub-hosted macOS runners. No Apple signing certificate or provisioning profile needs to be stored in GitHub.

## Xcode project

Open `PocketNotes.xcodeproj` in Xcode on a Mac, select the `PocketNotes` scheme, and build for an iOS device. The GitHub Actions workflow is the easier route when working from Windows.
