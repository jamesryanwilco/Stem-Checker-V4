//
//  ContentView.swift
//  StemChecker
//
//  Created by James Ryan Wilkins on 04/09/2025.
//

import SwiftUI
import os.log

struct ContentView: View {
    @EnvironmentObject var urlHandler: URLHandler
    @State private var audioEngine = AudioEngine()
    @State private var loadedURLs: [URL] = []
    private let logger = Logger(subsystem: "com.example.Stem-Checker-V3", category: "ContentView")

    var body: some View {
        VStack {
            Text("Stem Checker")
                .font(.largeTitle)
                .padding()

            if loadedURLs.isEmpty {
                Text("No stems loaded.")
                    .foregroundColor(.gray)
            } else {
                List(loadedURLs, id: \.self) { url in
                    Text(url.lastPathComponent)
                }
            }

            HStack {
                Button("Load Stems") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.audio]
                    
                    if panel.runModal() == .OK {
                        self.loadedURLs = panel.urls
                        audioEngine.load(urls: self.loadedURLs)
                    }
                }

                Button("Play") {
                    audioEngine.play()
                }
                .disabled(loadedURLs.isEmpty)

                Button("Stop") {
                    audioEngine.stop()
                }
                .disabled(loadedURLs.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onChange(of: urlHandler.urlsToLoad) { newURLs in
            logger.log("ContentView detected a change in urlHandler.urlsToLoad.")
            if !newURLs.isEmpty {
                logger.log("New URLs are not empty. Loading \(newURLs.count) stems.")
                self.loadedURLs = newURLs
                audioEngine.load(urls: self.loadedURLs)
                
                // Stop accessing security-scoped resources after they have been loaded.
                for url in newURLs {
                    url.stopAccessingSecurityScopedResource()
                }
                
                // DO NOT clear the handler's URLs here. This causes a race condition.
                // urlHandler.urlsToLoad = []
            } else {
                logger.log("Received an empty URL list. Nothing to load.")
            }
        }
    }
}

#Preview {
    ContentView()
}
