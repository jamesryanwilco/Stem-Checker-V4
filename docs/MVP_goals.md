# 🎯 MVP Goals

## Must-Haves
- **Multi-file Sync Playback:** Select multiple stems and play them starting at `0:00` with no drift.
- **Simple UI:** A minimal transport with only Play/Stop controls (Pause/Resume can come later).
- **Finder Integration:** Implement a right-click "Check Stems" Quick Action that opens the player window.
- **Basic Format Support:** Prioritize `.wav` and `.aiff` files.
- **Scoped Performance:** Optimize for playing up to 10 simultaneous files.

## 🛠️ Technical Approach (macOS)
- **Finder Integration:** Use an Action Extension (Quick Action) to create a right-click context menu item.
- **Audio Engine:** Use `AVAudioEngine` from AVFoundation for sample-accurate, multi-file synchronized playback. Avoid the complexity of Core Audio for the MVP.
- **UI:** A small, floating player window built with SwiftUI.

### Workflow
1. User selects stems in Finder.
2. User right-clicks and selects "Check Stems" from the `Quick Actions` menu.
3. The Stem Checker player window appears with the selected stems automatically loaded.
4. User clicks "Play" to hear all stems in sync.
5. User clicks "Stop" and closes the window.

## 🚫 What to Exclude from MVP
- Waveform previews.
- Volume, EQ, or mixing controls.
- Cross-platform support (focus on macOS first).
- Batch automation or cloud drive integrations.

## 🚀 MVP Roadmap
1.  **Prototype:** Build a minimal app that can load and play multiple WAV files in sync.
2.  **Finder Quick Action:** Integrate the prototype's logic into a right-click workflow.
3.  **Polish UI:** Refine the user interface into a simple, clean transport.
4.  **User Testing:** Get feedback from 2–3 producers/engineers to validate the workflow and sync accuracy.