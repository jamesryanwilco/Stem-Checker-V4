import AVFoundation

class AudioEngine {
    private var engine = AVAudioEngine()
    private var playerNodes = [AVAudioPlayerNode]()
    private var audioFiles = [AVAudioFile]()

    func load(urls: [URL]) {
        // Stop and reset the engine before loading new files
        engine.stop()
        engine.reset()
        playerNodes.removeAll()
        audioFiles.removeAll()

        let mainMixer = engine.mainMixerNode
        
        for url in urls {
            do {
                let file = try AVAudioFile(forReading: url)
                let player = AVAudioPlayerNode()
                
                engine.attach(player)
                engine.connect(player, to: mainMixer, format: file.processingFormat)
                
                playerNodes.append(player)
                audioFiles.append(file)
            } catch {
                print("Error loading audio file \(url.lastPathComponent): \(error)")
            }
        }
        
        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func play() {
        guard !playerNodes.isEmpty, !audioFiles.isEmpty else {
            print("No audio files loaded.")
            return
        }
        
        for (index, player) in playerNodes.enumerated() {
            player.scheduleFile(audioFiles[index], at: nil, completionHandler: nil)
        }
        
        playerNodes.forEach { $0.play() }
    }

    func stop() {
        playerNodes.forEach {
            $0.stop()
            $0.reset()
        }
    }
}
