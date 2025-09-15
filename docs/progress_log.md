# Progress Log: Stem Checker

_This log tracks the development progress of the Stem Checker application._

---

### **V1 - V3: Initial Development & Roadblock (August - Early September 2025)**

-   **Initial Concept:** Prototyped a macOS utility to play multiple audio stems simultaneously, aimed at audio professionals.
-   **Core Audio Engine:** Successfully built a playback engine using `AVAudioEngine` for synchronized, multi-file playback.
-   **Finder Integration Attempt:** The primary goal was to integrate the app with Finder's right-click Quick Actions menu. This proved to be a major technical challenge.
-   **Troubleshooting (V3):** Encountered a series of deep, intractable issues related to Xcode project configuration, sandboxing, and inter-process communication between the Action Extension and the main app. After exhaustive debugging, the `project.pbxproj` file was identified as the likely source of corruption.
-   **Decision:** The V3 project was abandoned in favor of a clean rebuild to avoid fighting against a corrupted project state.

---

### **V4: Clean Rebuild & Successful Implementation (12th September 2025)**

-   **New Project:** Started a brand new, clean Xcode 16 project named `Stem Checker V4`.
-   **Incremental Extension Build:** Methodically re-implemented the Finder Quick Action extension, following the step-by-step plan derived from the V3 troubleshooting log.
    -   **Step 1 (Foundation):** Created a default Action Extension and immediately fixed the template's "disappearing files" bug.
    -   **Step 2 (Activation):** Successfully configured the extension to only appear for audio files by using a robust predicate string in the `Info.plist` and correctly declaring document types in the main app's `Info.plist`. This overcame the primary V3 roadblock.
    -   **Step 3 (UI):** Replaced the default UI with a clean, programmatic confirmation dialog.
    -   **Step 4 (URL Retrieval):** After extensive debugging, implemented a resilient method to retrieve full, security-scoped file URLs from the extension context, handling various `NSItemProvider` representations.
    -   **Step 5 (App Launch):** Successfully implemented the `NSWorkspace.open` call and configured the complete chain of security entitlements (`App Sandbox`, `Apple Events`, `Hardened Runtime`, `User-Selected File Access`) for both the extension and the main app, resulting in a successful launch.
-   **Final Bug Fix (14th September 2025):** Successfully resolved a complex multi-window bug. The issue was traced to a series of race conditions between the system's file-opening events and the SwiftUI app lifecycle. The final, robust solution involved:
    -   Implementing a debouncing mechanism in the `AppDelegate` to handle the "event storm" from Finder.
    -   Taking full manual control of the app's window lifecycle within the `AppDelegate` to prevent SwiftUI's `WindowGroup` from automatically creating unwanted windows.
-   **Current Status:** The application is now fully functional and stable, correctly handling single and multi-file selections from the Finder Quick Action.
