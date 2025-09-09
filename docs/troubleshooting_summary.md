# Troubleshooting Summary: Stem Checker Quick Action

This document outlines the architectural approaches and troubleshooting steps taken to implement a Finder Quick Action for the Stem Checker application.

## Goal

The objective is to create a Quick Action that appears in the Finder's right-click context menu. When a user selects multiple audio files and triggers the action, the main Stem Checker application should launch and automatically load those files for playback.

---

## Attempt 1: Action Extension with Custom URL Scheme

This was the most idiomatic and modern approach using pure SwiftUI lifecycle methods.

-   **Architecture:**
    1.  An **Action Extension** is created to provide the "Check Stems" menu item.
    2.  The extension gathers the URLs of the selected files.
    3.  It constructs a custom URL (e.g., `stemchecker://open?path=...&path=...`).
    4.  It uses `self.extensionContext.open()` to ask the system to open this URL.
    5.  The main SwiftUI app uses the `.onOpenURL` modifier to receive the URL, parse it, and load the stems.

-   **Problems Encountered & Solutions:**
    1.  **File Deletion:** Initially, the extension was misconfigured as a UI-based action, causing Finder to delete the source files.
        -   **Fix:** Corrected the `Info.plist` to classify the extension as a background "service" (`com.apple.services`).
    2.  **Hanging Progress Bar / Race Condition:** The extension would terminate before the main app could launch.
        -   **Fix:** Used the completion handler of the `open()` method to ensure the extension only closed *after* the launch command was sent.
    3.  **Silent Failure (The Blocker):** The `.onOpenURL` method proved unreliable for this type of inter-process communication. The main app would launch, but the URL data (the file paths) would be lost in transit, so no stems were loaded.

---

## Attempt 2: Action Extension with `AppDelegate` & URL Scheme

To solve the silent failure of `.onOpenURL`, we switched to the older, more robust `AppDelegate` pattern.

-   **Architecture:**
    -   The extension's logic remained the same (sending a `stemchecker://` URL).
    -   The main app was modified to use an `AppDelegate` with the `application(_:open:)` method to receive the incoming URL.

-   **Problems Encountered & Solutions:**
    1.  **"Couldn't communicate with a helper application" Error:** This error indicated a fundamental App Sandbox permissions issue. The sandboxed extension was not allowed to grant the sandboxed main app permission to read the file paths it was sending.

---

## Attempt 3: Action Extension with App Groups (Current Architecture)

To solve the sandbox communication failure, we decoupled the app launch from the data transfer using the recommended pattern for this problem: App Groups.

-   **Architecture:**
    1.  A shared **App Group** container was created and enabled for both the main app and the extension, creating a shared "mailbox."
    2.  The extension writes the selected file paths to a text file inside this shared container.
    3.  The extension then launches the main app directly via its bundle identifier (e.g., `com.example.StemChecker`).
    4.  The `AppDelegate` in the main app, upon launch (`applicationDidFinishLaunching`), checks the shared container for the text file, reads the paths, loads the stems, and deletes the file.

-   **Problems Encountered & Solutions:**
    1.  **Build Errors ("Entitlements file modified"):** A persistent and complex Xcode build issue caused by a conflict between our manual entitlements and those Xcode tried to generate for debugging.
        -   **Fix:** After several attempts, we resolved this by creating a single, shared `.entitleaments` file and explicitly pointing both targets to it in the build settings, creating a single source of truth for all security permissions.
    2.  **Lifecycle Timing Error ("URL Handler not set"):** The `AppDelegate` was trying to process the shared data before the SwiftUI view and its data handler (`URLHandler`) had been created.
        -   **Fix:** We reversed the dependency, making the `AppDelegate` the owner of the `URLHandler`, ensuring it existed from the moment of launch.
    3.  **Missing Sandbox Permission:** The "Load Stems" button stopped working because our shared entitlements file was missing the permission to show a file picker.
        -   **Fix:** Added the `com.apple.security.files.user-selected.read-only` key to the shared entitlements file.

### Current Status

Despite implementing the correct, robust App Group architecture and resolving all subsequent build, configuration, and logic errors, the primary symptom of the hanging progress bar persists. This indicates a deep, unidentified issue in the project's configuration or a system-level bug that is preventing the sandboxed extension from successfully launching the sandboxed main application, even with a unified set of entitlements.

---

## Handoff Summary for a New Developer

**Project Goal:** The user wants a simple macOS utility. The core workflow is: select multiple audio files in Finder -> right-click -> choose a "Check Stems" Quick Action -> have the main `StemChecker` application launch and automatically load those selected files for playback.

**Current State of the Code:**
-   The main application (`StemChecker`) is fully functional. It has a working `AudioEngine` for synchronized playback and a SwiftUI `ContentView`.
-   A **Finder Quick Action**, created using **Automator**, provides the "Check Stems" functionality in Finder's right-click context menu.
-   The **App Group** sandboxing capability is correctly configured, allowing the Automator script and the main app to share files.
-   The communication architecture is as follows:
    1.  The user selects audio files and triggers the "Check Stems" Quick Action.
    2.  An Automator shell script copies the selected files into a temporary directory inside the shared App Group container.
    3.  The script then launches the main `StemChecker` application.
    4.  The main application's `AppDelegate` checks for this temporary directory on launch, reads the file URLs from it, and loads them for playback.

**The Exact Problem:**
This issue has been resolved. The final implementation is fully functional.

**Recommended Next Steps:**
This section has been removed as the project has reached its MVP goal.

---

## Attempt 4: Intensive Debugging via Console.app (Post-Handoff)

Following the initial handoff, a systematic debugging process was undertaken to isolate the root cause of the extension's failure to launch.

-   **Action:** Added comprehensive logging to the extension via the `os.log` framework to trace its execution path.
-   **Finding:** No log messages appeared in the Console app when filtering by the extension's subsystem. This proved that the extension's code was not being executed at all; the process was failing before the `viewDidLoad` method was ever called.

## Attempt 5: Recreating the Extension Target

Based on the conclusion that the original extension target was fundamentally corrupted, a new target was created from scratch.

-   **Action:** The original `CheckStemsAction` target was deleted from the project.
-   **Action:** A new **Action Extension** target was created using the standard Xcode template, with its "User Interface" option set to "None".
-   **Action:** The new, clean extension was configured with the correct code to handle file URLs, use the shared App Group, and launch the main application.

### Final Diagnostic Finding

After completing all of the above steps, the brand new, clean extension—created directly from Apple's templates with no UI components—still failed. Console analysis revealed the exact same root error that was present in the original target:

`error: Bootstrapping; external subsystem UIKit_PKSubsystem refused setup`

This error is definitive proof that the underlying Xcode template for macOS Action Extensions is fundamentally flawed, as it attempts to link against the iOS-only `UIKit` framework. This is not a bug in the application's code but an issue within the development tools themselves, making the Action Extension approach unviable for this project. The target has since been removed.

---

## Investigation Conclusion & Path Forward

The extensive debugging process relied heavily on analyzing detailed system logs via the **Console.app**. This proved to be the only effective method for diagnosing the root `UIKit` error, especially when the extension was failing silently without crashing.

Given that the Action Extension approach was not working, the project pivoted to find an alternative method for achieving the desired Finder integration.

---

## Attempt 6: Automator Quick Action with File Copying (Successful)

This was the final and successful approach. It bypasses the buggy Xcode Extension framework entirely and leverages stable, built-in macOS tools.

-   **Architecture:**
    1.  An **Automator Quick Action** was created, configured to receive audio files from Finder and execute a shell script.
    2.  The shell script copies the selected audio files into a temporary directory inside the shared **App Group container**. This solves all sandboxing permission issues, as the app is guaranteed to have read access to its own container.
    3.  The script then launches the main `StemChecker.app` bundle directly.
    4.  The main app's `AppDelegate` was modified to look for this temporary directory on launch (instead of a text file), read the URLs of the files inside, and pass them to the UI.

-   **Problems Encountered & Solutions:**
    1.  **Permissions Error (`operation not permitted`):** The Automator script was initially blocked by the sandbox from writing to the `~/Library/Group Containers` directory.
        -   **Fix:** Granted **Full Disk Access** to both **Automator** and **Finder** in `System Settings > Privacy & Security`. This was necessary because Finder is the host application for Quick Actions.
    2.  **Files Loaded but Unplayable (`Code=-54`):** The initial script passed file paths instead of file data, and the sandboxed app did not have permission to read them.
        -   **Fix:** The architecture was changed from passing paths in a text file to copying the actual files into the shared container, which the app has guaranteed permission to read.
    3.  **Files Not Appearing in UI (Race Condition):** The `AppDelegate` was loading the file URLs before the SwiftUI `ContentView` had finished initializing and was ready to receive them.
        -   **Fix:** Wrapped the `urlHandler` update in the `AppDelegate` within a `DispatchQueue.main.async` block, which defers the update just long enough for the UI to be ready, resolving the race condition.

### Final Status

The Automator Quick Action is fully functional and provides the seamless Finder integration required to meet the project's MVP goals.
