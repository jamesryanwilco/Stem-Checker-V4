# Stem Checker: Initial Idea

_Created: 30/08/2025_

## 1. Concept

A macOS utility that allows a user to select multiple audio files (stems) in Finder and play them back simultaneously without needing to open a Digital Audio Workstation (DAW). This provides a quick and efficient way to check bounced stems for synchronization, latency, or other issues.

## 2. Target Audience

- Music Producers
- Audio Engineers
- Mix & Mastering Engineers

The primary goal is to save time for professionals who regularly work with large numbers of stems and need a fast way to verify exports before sending them to clients, labels, or mastering.

## 3. Core Features

- **Simultaneous Playback:** Plays multiple audio files in sync, starting from `0:00`.
- **Latency-Free:** Ensures no drift or delay between tracks, as this is a primary check.
- **Finder Integration:** Accessible via a right-click Quick Action ("Check Stems").
- **Simple Transport:** A minimal player window with basic Play/Stop controls.
- **Format Support:** Initial support for `.wav` and `.aiff`, with potential for `.mp3` later.

## 4. User Experience (UX) Flow

1.  The user selects multiple stem files in Finder.
2.  They right-click and choose the "Check Stems" action.
3.  A small, non-intrusive player window appears.
4.  The user clicks "Play," and all stems begin playing in sync.
5.  After verifying the audio, the user clicks "Stop" and closes the window.

## 5. Market Comparison

The workflow is similar to tools like [Snapper](https://www.audioease.com/snapper/), which integrates with Finder to preview single audio files. However, Snapper does not support the simultaneous playback of multiple files, which is the core value proposition of Stem Checker.