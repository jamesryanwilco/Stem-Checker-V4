# Stem Checker: Technical Log

## 1. Core Application Architecture

The application is composed of two main targets: the main `StemChecker` application and a `CheckStemsAction` (an Action Extension).

### `StemChecker` (Main App)

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Audio Engine (`AudioEngine.swift`):**
  - Built on `AVFoundation` and `AVAudioEngine`.
  - Manages a collection of `AVAudioPlayerNode` instances, one for each audio file.
  - Connects all player nodes to the engine's `mainMixerNode` to ensure synchronized output.
  - Handles loading, playing, and stopping/resetting audio files.
- **URL Handling:**
  - The app registers a custom URL scheme: `stemchecker://`.
  - A singleton `URLHandler` class parses incoming URLs to extract file paths, which are then published to the UI using `@Published` properties.
  - The main `StemCheckerApp.swift` uses the `.onOpenURL` modifier to capture incoming URLs and pass them to the `URLHandler`.
- **View (`ContentView.swift`):**
  - A simple SwiftUI view that displays the list of loaded stems and provides "Play"/"Stop" buttons.
  - Observes the `URLHandler` via `@EnvironmentObject` and automatically loads new stems when they are received from the Action Extension.

### `CheckStemsAction` (Action Extension) - DEPRECATED

- **Status:** This approach has been abandoned.
- **Reason:** After extensive troubleshooting, it was determined that the Xcode template for macOS Action Extensions is fundamentally flawed, as it incorrectly attempts to link against the iOS-only `UIKit` framework. This causes a non-recoverable error (`UIKit_PKSubsystem refused setup`) that prevents the extension from launching, even when created from a clean, non-UI template. The `CheckStemsAction` target has been removed from the project.

## 2. Key Development Milestones

1.  **Prototype:** Successfully built a standalone macOS app that could load and play multiple audio files in sync.
2.  **Action Extension:** Added and subsequently removed a `CheckStemsAction` extension target after diagnosing an unresolvable issue with the Xcode template.
3.  **Automator Quick Action:** Successfully implemented a Finder context menu item using an Automator Quick Action that runs a shell script. This script copies selected files to a shared App Group container and launches the main application, providing a seamless and robust workflow that bypasses the issues with native Action Extensions.

## 3. Final Architecture

- **Finder Integration:** An Automator Quick Action provides the "Check Stems" right-click menu item in Finder.
- **Data Transfer:** The Automator script copies selected audio files into a temporary directory within a shared App Group container. This approach resolves all sandbox permission issues. The final script is as follows:
  ```sh
  #!/bin/zsh

  # --- Configuration ---
  APP_GROUP_NAME="group.com.example.StemChecker"
  TEMP_STEMS_DIR_NAME="TemporaryStems"
  APP_PATH="/Users/James/Library/Developer/Xcode/DerivedData/StemChecker-hdzibtpypbcodofaotbpupurmxhy/Build/Products/Debug/StemChecker.app"

  # --- Logic ---
  # 1. Find the shared container directory.
  CONTAINER_DIR=$(/usr/bin/find ~/Library/Group\ Containers/ -maxdepth 1 -type d -name "$APP_GROUP_NAME" 2>/dev/null | head -n 1)

  # Exit silently if the container isn't found.
  if [[ -z "$CONTAINER_DIR" ]]; then
      exit 1
  fi

  # 2. Define the path for our temporary directory, clean up any old one,
  # and create a fresh one.
  TEMP_DIR_PATH="$CONTAINER_DIR/$TEMP_STEMS_DIR_NAME"
  rm -rf "$TEMP_DIR_PATH"
  mkdir -p "$TEMP_DIR_PATH"

  # 3. Copy each selected audio file into the temporary directory.
  for file in "$@"; do
      cp "$file" "$TEMP_DIR_PATH/"
  done

  # 4. Launch the main application.
  open "$APP_PATH"
  ```
- **App Launch:** The main application is launched by the script after the file copy is complete.
- **Data Handling:** The `AppDelegate` checks for the temporary directory on launch, reads the files it contains, passes the URLs to the UI, and schedules the directory for cleanup. A `DispatchQueue.main.async` call is used to prevent a race condition between the data being loaded and the UI being ready to display it.
