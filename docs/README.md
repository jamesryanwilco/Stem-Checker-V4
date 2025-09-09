# Stem Checker MVP

## Overview

Stem Checker is a lightweight macOS utility designed for audio professionals, including music producers, mixing engineers, and mastering engineers. It provides a quick and seamless way to check bounced audio stems for synchronization issues directly from Finder, without the need to open a full-featured Digital Audio Workstation (DAW).

The core goal is to accelerate the quality assurance workflow, saving valuable time when verifying exports before they are sent to clients, collaborators, or mastering houses.

## Core Features

- **Synchronized Playback:** Select multiple audio files (`.wav`, `.aiff`) and play them back simultaneously.
- **Minimalist UI:** A simple player window with basic transport controls (Play/Stop/Load).
- **Efficiency:** Drastically reduces the time it takes to perform routine stem checks by avoiding the overhead of launching a DAW.

## How It Works

1.  **Select Stems:** In Finder, select two or more audio files (`.wav`, `.aiff`).
2.  **Right-Click:** Right-click on the selected files and navigate to the `Quick Actions` menu.
3.  **Check Stems:** Choose the "Check Stems" action.
4.  **Playback:** The Stem Checker application will launch automatically with your selected files loaded and ready for synchronized playback.

This repository contains the source code for the MVP version of the application, built natively for macOS using Swift and SwiftUI.
