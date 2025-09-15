# Stem Checker V4

## Overview

Stem Checker is a lightweight macOS utility designed for audio professionals, including music producers, mixing engineers, and mastering engineers. It provides a quick and seamless way to check bounced audio stems for synchronization issues directly from Finder, without the need to open a full-featured Digital Audio Workstation (DAW).

The core goal is to accelerate the quality assurance workflow, saving valuable time when verifying exports before they are sent to clients, collaborators, or mastering houses.

## Core Features

-   **Synchronized Playback:** Select multiple audio files (`.wav`, `.aiff`, `.mp3`) and play them back simultaneously.
-   **Finder Integration:** A Quick Action in the right-click context menu allows you to open stems directly from a Finder selection.
-   **Minimalist UI:** A simple player window with basic transport controls (Play/Stop/Load).
-   **Efficiency:** Drastically reduces the time it takes to perform routine stem checks by avoiding the overhead of launching a DAW.

## How It Works

1.  **Select Stems:** In Finder, select two or more audio files.
2.  **Right-Click:** Right-click on the selected files and navigate to the `Quick Actions` menu.
3.  **Check Stems:** Choose the "CheckStemsExtensionV4" action.
4.  **Confirm:** A dialog will appear asking you to confirm opening the files. Click "Open".
5.  **Playback:** The Stem Checker application will launch with a single window, with your selected files loaded and ready for synchronized playback.

## Technology

This repository contains the source code for the application, built natively for macOS using a modern technology stack:
-   **UI:** SwiftUI for the main application interface.
-   **App Lifecycle:** A hybrid approach using a SwiftUI `App` lifecycle with an AppKit `AppDelegate` for advanced behaviors like handling file opening events.
-   **Audio Engine:** `AVFoundation` (`AVAudioEngine`) for robust, multi-track audio playback.
-   **Finder Integration:** A macOS Action Extension provides the "Quick Action" functionality.
