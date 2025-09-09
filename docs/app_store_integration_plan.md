# Plan for Mac App Store Integration

This document outlines the architectural changes required to refactor the Stem Checker application for distribution on the Mac App Store.

## 1. Objective

To modify the Stem Checker application so that it fully complies with the sandboxing and security requirements of the Mac App Store, enabling a future release on that platform.

## 2. Background & Problem Statement

The current version of Stem Checker achieves Finder integration via an **Automator Quick Action** that runs a shell script. While effective for private distribution, this approach is fundamentally incompatible with the Mac App Store for two primary reasons:

1.  **External File Installation:** It requires the user to manually install a `.workflow` file, which is not permitted. App Store apps must be entirely self-contained.
2.  **Broad Permissions:** It relies on the user granting Full Disk Access to system services (Finder and Automator), a requirement that would cause an app to be immediately rejected during App Store review.

## 3. Proposed Solution: Finder Sync Extension

The correct, Apple-sanctioned method for this level of Finder integration is a **Finder Sync Extension**. This is a modern, robust, and App Store-compliant framework that allows an application to safely extend Finder's functionality.

The new architecture will replace the Automator workflow entirely with a self-contained extension that lives inside the main application bundle.

## 4. New Architecture Workflow

1.  **User Action:** The user selects multiple audio files in Finder and right-clicks.
2.  **Context Menu:** The `StemChecker` Finder Sync Extension, running in the background, adds a "Check Stems" item to the context menu.
3.  **Get File URLs:** When the user clicks "Check Stems," the extension's code is executed and receives a list of the selected file URLs.
4.  **Create Secure Bookmarks:** To grant the main app permission to read these files, the extension creates a **Security-Scoped Bookmark** for each URL. This is a secure, sandboxed token that represents a temporary permission grant.
5.  **Data Transfer:** The extension serializes these bookmarks into raw `Data` and writes this data to a file in the shared **App Group container**.
6.  **Launch App:** The extension then launches the main `StemChecker.app`.
7.  **Resolve Bookmarks:** The `AppDelegate` in the main app launches, detects the data file in the shared container, reads the raw bookmark data, and resolves it back into secure, usable file URLs.
8.  **Load Audio:** These securely resolved URLs are passed to the `AudioEngine`, which now has temporary, sandboxed permission to read the files and load them for playback.

## 5. Key Development Tasks

Refactoring the application will involve the following distinct steps:

1.  **Add New Target:** In Xcode, add a new **"Finder Sync Extension"** target to the project. This will create the necessary boilerplate and link it to the main application.

2.  **Implement Extension Logic:** Write the Swift code for the extension itself. This includes:
    *   Registering the "Check Stems" menu item.
    *   Implementing the logic to only show the menu item when audio files are selected.
    *   Writing the handler that is called when the user clicks the menu item.

3.  **Handle Permissions (Security-Scoped Bookmarks):**
    *   Inside the extension handler, write the code to iterate through the selected file URLs and generate `Data` from a security-scoped bookmark for each one.

4.  **Refactor Data Transfer:**
    *   Modify the extension to write the bookmark `Data` into the shared App Group container.
    *   Modify the `AppDelegate`'s `checkForSharedData` function to read this raw data instead of looking for copied files.

5.  **Refactor `AppDelegate`:**
    *   Implement the logic to resolve the bookmark data back into usable URLs.
    *   Ensure the app properly begins and ends access to the security-scoped resources.
    *   Pass the resolved, secure URLs to the `URLHandler`.

6.  **Testing and Debugging:**
    *   Thoroughly test the end-to-end workflow. Debugging extensions requires attaching the Xcode debugger to the Finder process, which can be complex.

7.  **Final App Store Submission:**
    *   Configure the App Store Connect record.
    *   Ensure all entitlements (App Groups, sandboxing, etc.) are correctly configured for both the main app and the extension.
    *   Archive and upload the build for review.

This plan represents a significant but necessary refactoring effort to prepare Stem Checker for a successful launch on the Mac App Store.
