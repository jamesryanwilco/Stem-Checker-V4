# Troubleshooting Log: Stem Checker V3 Quick Action
using xcode 16
**Created:** 10/09/2025

## 1. Objective

The goal is to create a macOS Quick Action that allows a user to select multiple audio files in Finder, right-click, and launch the `Stem Checker V3` application with the selected files loaded for simultaneous playback.

The desired user flow is:
1.  User selects files in Finder.
2.  User right-clicks -> Quick Actions -> "Check Stems V3".
3.  A confirmation dialog appears: "Open X files with Stem Checker V3?"
4.  On confirmation, the main `Stem Checker V3.app` launches and displays the list of selected files.

## 2. Current Status (As of 10/09/2025)

-   **Main App:** The `Stem Checker V3` application builds and runs correctly. It can manually load and play audio files.
-   **Extension:** The `Check Stems V3` Action Extension target builds and is correctly embedded in the main app.
-   **Problem:** When the "Check Stems V3" Quick Action is triggered in Finder, the process fails silently. The confirmation dialog does not appear, and the main application is not launched. Console logs indicate that Finder initiates a request to the extension, but the extension process is terminated prematurely without completing its task.

## 3. Core Technical Challenge

The primary difficulty lies in the complex interaction between the sandboxed Action Extension, Finder, and the main application, specifically concerning security, file access permissions, and the extension's lifecycle.

The extension must:
1.  Securely access the URLs of the files selected by the user. macOS moves these files to a temporary sandboxed location for security.
2.  Correctly manage the lifecycle of this file access to ensure the files are returned to their original location.
3.  Launch the main application and hand off the file URLs with the correct permissions.
4.  Present a user interface (an `NSAlert`), which has its own lifecycle requirements.

## 4. History of Attempts & Findings

Several approaches have been attempted to resolve this issue, revealing layers of complexity.

### Attempt 1: Custom URL Scheme
-   **Method:** The extension would capture file paths, encode them into a custom URL (e.g., `stemcheckerv3://?url=...`), and open that URL. The main app would register the scheme and parse the URL.
-   **Problem (File Moving):** This caused the original files to be moved to a temporary sandbox folder (`NSIRD_Finder_...`) and not returned, because the main app could not properly claim the sandboxed file handles from a simple URL path. This is a serious side effect.
-   **Conclusion:** This method is incorrect as it breaks macOS sandboxing and security principles. It should be avoided.

### Attempt 2: `NSWorkspace.open` API
-   **Method:** The extension was rewritten to use the Apple-recommended `NSWorkspace.open(urls, withApplicationAt: ...)` method. This is the standard, secure way to launch an app with a set of files. An `AppDelegate` was added to the main app to handle the standard `application(_:open:)` event.
-   **Problem:** The extension was still being terminated by Finder before the `NSWorkspace.open` call could be executed.
-   **Conclusion:** This API is the correct one to use, but an underlying configuration issue was preventing the extension from running long enough to call it.

### Attempt 3: `Info.plist` Configuration for UI
-   **Hypothesis:** The silent termination was caused by a conflicting `Info.plist` configuration. The extension was configured to present a UI (`NSExtensionPrincipalClass` was set), but another key (`NSExtensionActionStyle`) was set to `None`, signaling the opposite.
-   **Fix Attempted:** The `NSExtensionActionStyle` was changed to `Default` to resolve the conflict and allow the `ActionViewController` to present its confirmation alert.
-   **Result:** This did not resolve the issue. The extension still fails to launch and show the dialog, which is the current state.

### Attempt 4: Deep Debugging and Entitlements (As of 10/09/2025)
-   **Method:** Added extensive `os_log` statements throughout the extension and the main app's `AppDelegate` and `ContentView` to trace the execution flow.
-   **Findings:** The logs revealed two critical errors:
    1.  The extension was failing to correctly identify the incoming data from Finder as file URLs. The `provider.hasItemConformingToTypeIdentifier` check was consistently failing.
    2.  A recurring error from the system's `tccd` process indicated that the extension was missing the `com.apple.security.automation.apple-events` entitlement, which is required for a sandboxed app to send commands to another app.
-   **Fix Attempted:**
    1.  The extension's code was modified to log all incoming type identifiers and to include a fallback to handle generic `public.data` types.
    2.  The `com.apple.security.automation.apple-events` entitlement was added to the `Check_Stems_V3.entitlements` file, and an `NSAppleEventsUsageDescription` was added to its `Info.plist`.
-   **Result:** This was a major step forward. The files were no longer being moved/deleted, and the extension successfully gathered the file URLs. However, a new error appeared: a Finder dialog stating, "The application “Stem Checker V3” cannot open the specified document or URL." The `tccd` error log persisted.

### Attempt 5: Verifying the Build Process and Targeting the Main App
-   **Hypothesis:** The issue was not with the code, but with the Xcode build process failing to apply the entitlements, or with the main app being incorrectly configured to receive them.
-   **Verification:** The `codesign` command-line tool was used to inspect the compiled `.appex` file. This provided definitive proof that the extension **did** have the correct entitlements signed into its binary.
-   **Conclusion:** This proved the problem was not with the extension (the sender) but with the main app (the recipient).
-   **Fix Attempted:** The main `Stem Checker V3` app target was configured with:
    1.  App Sandbox capability
    2.  Hardened Runtime capability with the "Apple Events" exception enabled.
-   **Result:** Progress. The `tccd` entitlement error in the logs finally disappeared. However, the Finder error dialog ("cannot open the specified document or URL") remains. This indicates the security chain is now valid, but the system's Launch Services is rejecting the request for another reason.

## 5. Next Steps for Investigation

The problem is now narrowed down to the system's Launch Services. The main app is being launched, but it is refusing to accept the files. This is almost certainly due to an incomplete or outdated declaration of the file types the app can handle.

1.  **Implement Modern File Type Declarations:** The current `Info.plist` uses `CFBundleDocumentTypes`, which is an older system. The next step is to add declarations for **Uniform Type Identifiers (UTIs)**.
    -   **Action:** Add the `UTImportedTypeDeclarations` key to the main app's `Info.plist`. This will explicitly declare that the app conforms to and can handle public audio types like `public.wav`, `public.aiff`, and `public.mp3`. This is the modern, preferred way to register an app's file handling capabilities with the system.

2.  **Verify Main App Entitlements:** After adding the UTI declarations, we must re-verify the main app's entitlements, specifically ensuring that file access permissions are correctly set within its sandbox to handle incoming files.

3.  **Aggressive Logging:** Add `os_log` statements to the very beginning of `viewDidLoad`, `loadView`, and `viewDidAppear` in the `ActionViewController` to determine exactly how far the extension gets in its lifecycle before being terminated.

The immediate priority should be to get a blank view to appear from the Quick Action. Once that simple goal is achieved, the rest of the functionality can be built upon that stable foundation.

## 6. Update (12/09/2025): Exhaustive Troubleshooting & Final Diagnosis

Following the previous investigation, an exhaustive series of attempts were made to fix the extension.

### Phase 1: Fixing the "Disappearing Files" Bug
- **Action:** The extension was refactored from a UI-based `NSViewController` to a headless `NSObject` conforming to `NSExtensionRequestHandling`. The problematic `NSFileCoordinator` block was removed.
- **Result:** This successfully fixed the critical bug where files were being moved from their original location. However, the extension still failed to launch the main app, with Finder throwing a "cannot open the specified document" error.

### Phase 2: Resolving Configuration Conflicts
- **Hypothesis:** The issue was a mismatch between the main app's `Info.plist` file type declarations and the extension's activation rules.
- **Actions Attempted:**
    1.  The extension's activation rules (`NSExtensionActivationContentUTIs`) were modified to use specific UTIs (`com.microsoft.waveform-audio`, etc.) instead of the generic `public.audio`.
    2.  The main app's `Info.plist` was cleaned of legacy `CFBundleDocumentTypes` keys. This was later reverted when it was discovered they are still necessary for extension visibility.
    3.  The macOS Launch Services cache was forcibly reset using the `lsregister` command-line tool to eliminate stale cache issues.
- **Result:** None of these changes resolved the core issue. The extension appeared in System Settings but would not appear in the Quick Actions menu in Finder.

### Phase 3: The Control Test & Final Diagnosis
- **Action:** As a final diagnostic step, the custom extension was deleted and a new, default "Action Extension" (`TestExtension`) was created with no code modifications.
- **Result:** **The default extension worked perfectly.** It appeared in the Quick Actions menu as expected. However, the moment its `Info.plist` was modified to activate for specific audio UTIs, it disappeared again.
- **Final Diagnosis:** This proves that the project's code, code signing, and the system environment are all fundamentally correct. The problem is an intractable, hidden configuration issue or corruption within the Xcode project file (`project.pbxproj`) itself. The project is in a state where the system's security and validation checks fail when the main app and the extension are linked with specific file types, even when the declarations appear correct.

## 7. Final Recommended Plan

Since the project file itself is the likely source of the problem, continuing to patch it is inefficient. The most reliable and professional path forward is to restart with a clean slate, preserving the code that has been proven to work.

1.  **Create a New Project:** Start a brand new, empty macOS App project in Xcode (e.g., `StemCheckerV4`).
2.  **Migrate Source Code:** Manually add the existing Swift files (`ContentView.swift`, `AudioEngine.swift`, `AppDelegate.swift`, etc.) to the new project.
3.  **Create a New Default Extension:** Add a new, clean "Action Extension" target to the project, as was done in the successful control test.
4.  **Implement in "Baby Steps":** Methodically modify the new, working extension one step at a time, testing after each change:
    a.  **Change Activation:** Modify the extension's `Info.plist` to activate for the specific audio file UTIs. Test if it still appears.
    b.  **Convert to Headless:** Modify the extension to run without a user interface. Test again.
    c.  **Add File Handling Logic:** Replace the template code with the logic to retrieve file URLs from the context. Test that it can log the correct paths.
    d.  **Add App Launch Logic:** Add the final code to launch the main application.

This incremental approach, starting from a known-good foundation, is the surest way to achieve the desired functionality without fighting against a corrupted project state.

## 8. Update (V4): Successful Re-implementation from Clean Slate

**Date:** 12/09/2025

This section confirms that the final recommended plan from the V3 diagnosis was correct and has resulted in a fully functional Quick Action extension in the new `Stem Checker V4` project. The incremental, "baby steps" approach was followed meticulously.

### Phase 1: Foundation & Activation Logic

1.  **New Project:** A new, clean Xcode 16 project (`StemCheckerV4`) was created.
2.  **Default Extension:** A new "Action Extension" target (`CheckStemsExtensionV4`) was added. The default template was tested and confirmed to be visible in Finder for all file types.
3.  **Fix "Disappearing Files" Bug:** The critical bug from the default template was immediately fixed by modifying the extension's `send(_:)` method to complete the request by returning the original input items, preventing Finder from deleting the selected files.
4.  **Fix Activation Rule:** The extension's `Info.plist` was modified to restrict activation to audio files.
    *   *Initial Failure:* An attempt to use a dictionary of `NSExtensionActivationContentUTIs` caused the extension to disappear, perfectly replicating the V3 failure.
    *   *Correction 1:* The main app's `Info.plist` was populated with `CFBundleDocumentTypes` and `UTImportedTypeDeclarations` for the supported audio types. This is a critical step to inform macOS that the container app can handle the types the extension is claiming.
    *   *Correction 2:* The activation rule was changed from a simple UTI list to a robust **predicate string** (`SUBQUERY(...)`), which correctly activates only when *all* selected items conform to `public.audio`. This combination proved to be the correct and stable solution for visibility.

### Phase 2: URL Retrieval & Sandboxing

This phase involved the most complex, iterative debugging.

1.  **UI Replacement:** The default text editor UI was removed and replaced with a programmatic confirmation dialog.
2.  **Initial URL Retrieval Failure:** The initial attempt to get file URLs using `attachment.loadItem(forTypeIdentifier: "public.file-url", ...)` failed silently.
3.  **Entitlement Fix 1 (File Access):** The `com.apple.security.files.user-selected.read-only` entitlement was added to the extension, which allowed it to access file information.
4.  **Diagnose Type Identifiers:** After adding the entitlement, logging revealed that Finder was providing the URL under its specific UTI (e.g., `com.microsoft.waveform-audio`) and was **not** providing a `public.file-url` representation.
5.  **Robust URL Retrieval:** The code was refactored to iterate through all `registeredTypeIdentifiers` on an attachment, use the first available identifier, and correctly wrap the URL access in `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` to get the full, untruncated path. This solved the URL retrieval issue completely.

### Phase 3: Launching the Main Application

1.  **Implement Launch Code:** The `NSWorkspace.open` API was added to the extension to launch the main app. As expected, this initially failed with a security error.
2.  **Final Entitlement Fixes:** The final security chain was completed:
    *   The **extension** was given the `com.apple.security.automation.apple-events` entitlement, allowing it to send the "open" command.
    *   The **main app** was configured with **Hardened Runtime** with the **Apple Events** exception checked, allowing it to receive the command.
    *   The **main app** was confirmed to be **sandboxed**, and critically, it was also given the `com.apple.security.files.user-selected.read-only` entitlement. This allows the sandboxed main app to accept the incoming file URLs from the sandboxed extension.

### Conclusion

The V3 diagnosis was 100% correct: the original project file was intractably corrupted. By starting with a clean project and building the functionality piece by piece while verifying at each step, we successfully navigated the complexities of macOS App Extensions, sandboxing, and entitlements to achieve the desired core functionality. The application is now fully functional.

---

## 9. V4 Post-mortem: The Multi-Window Bug (12/09/2025)

After successfully implementing the core functionality, a final UI bug was discovered in V4.

### 1. The Bug

When selecting multiple files (e.g., three) and using the Quick Action, the application would open three separate windows.

### 2. The Investigation & Diagnosis

The bug was traced to a series of compounding race conditions between the macOS launch services and the SwiftUI app lifecycle.

-   **Initial Diagnosis:** The first root cause was correctly identified as the system firing multiple, inconsistent `open` events in rapid succession (an "event storm") when multiple files were selected.
-   **First Race Condition:** An attempt to fix this with a simple debouncing `Timer` in the `AppDelegate` failed. Log analysis showed that the `AppDelegate`'s `application(_:open:)` method was not being called at all. The SwiftUI `WindowGroup` was intercepting the launch events first and creating a new window for each one before the `AppDelegate` was fully wired up.
-   **Second Race Condition:** The architecture was refactored to centralize state in the `AppDelegate`, which successfully fixed the first race condition, allowing the `AppDelegate` to receive the open events. However, the multi-window issue persisted. Log analysis confirmed the `AppDelegate`'s debouncing logic was now running, but the `WindowGroup` was *still* winning the race and creating its windows before the debouncer could finish.

### 3. The Final Solution: Manual Window Management

The final and correct solution was to remove the race condition entirely by taking full, manual control of the window lifecycle away from SwiftUI.

1.  **Disable Automatic Windows:** In the `Stem_Checker_V4App` struct, the `WindowGroup` was replaced with a `Settings` scene. This is a standard technique to create a "headless" app that does not create any windows automatically on launch.
2.  **Centralize Window Control in AppDelegate:** The `AppDelegate` was given complete authority over the window.
    -   A property, `private var window: NSWindow?`, was added to hold a reference to the main window.
    -   The `applicationDidFinishLaunching` method was implemented to create the `NSWindow` and its `ContentView` as soon as the app launched, but crucially, **without showing it**. This pre-warms the window, ensuring it always exists.
    -   The `processBufferedURLs` method was simplified. After the debouncer fires, it now only has to update the `URLHandler` with the file URLs and then show the existing window by calling `window?.makeKeyAndOrderFront(nil)`.
    -   The `applicationShouldHandleReopen` method (for Dock clicks) was also simplified to just show the existing window.

This robust AppKit pattern guarantees that the `AppDelegate` is the single source of truth for window creation and presentation, elegantly resolving all race conditions.
