import Cocoa
import os.log
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.example.Stem-Checker-V3", category: "AppDelegate")
    
    // The AppDelegate now owns the single source of truth for file URLs.
    let urlHandler = URLHandler()
    
    private var urlBuffer = Set<URL>()
    private var debounceTimer: Timer?
    
    // We now hold a reference to the main window to manage its lifecycle manually.
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the window instance as soon as the app launches, but keep it hidden.
        // This ensures a window object exists before any 'open' events are received.
        let contentView = ContentView().environmentObject(urlHandler)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        self.window = window
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        logger.log("AppDelegate received \(urls.count) URLs. Buffering and scheduling processing.")
        
        // Cancel any existing timer to reset the debounce period.
        debounceTimer?.invalidate()
        
        // Add the new URLs to our buffer. Using a Set automatically handles duplicates.
        urlBuffer.formUnion(urls)
        
        // Schedule the processing to run after a short delay.
        debounceTimer = Timer.scheduledTimer(
            timeInterval: 0.1, // A short delay to wait for subsequent open events.
            target: self,
            selector: #selector(processBufferedURLs),
            userInfo: nil,
            repeats: false
        )
    }

    @objc private func processBufferedURLs() {
        // Make a copy of the buffered URLs and clear the buffer for the next events.
        let urlsToProcess = Array(urlBuffer)
        urlBuffer.removeAll()

        logger.log("Debounce timer fired. Processing \(urlsToProcess.count) unique URLs.")
        logger.log("URLs: \(urlsToProcess.map { $0.path }.joined(separator: ", "))")
        
        let accessibleURLs = urlsToProcess.compactMap { url -> URL? in
            guard url.startAccessingSecurityScopedResource() else {
                logger.error("Failed to gain access to security-scoped resource: \(url.path)")
                return nil
            }
            return url
        }
        
        logger.log("Successfully gained access to \(accessibleURLs.count) security-scoped URLs.")

        // --- Manual Window Management ---
        // Pass the URLs to the handler, which will update the view.
        urlHandler.urlsToLoad = accessibleURLs
        
        // The window is guaranteed to exist now, so we just need to show it.
        self.window?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // This handles clicking the Dock icon. The window is guaranteed to exist.
        self.window?.makeKeyAndOrderFront(nil)
        return true
    }
}
