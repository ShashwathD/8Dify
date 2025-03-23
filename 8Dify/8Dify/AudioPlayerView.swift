//
//  AudioPlayerView.swift
//  8Dify
//
//  Created by Shashwath Dinesh on 3/22/25.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var timer: Timer?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Processed Audio")
                .font(.title)
                .fontWeight(.bold)
            
            // Player controls
            HStack(spacing: 40) {
                Button(action: {
                    if isPlaying {
                        pauseAudio()
                    } else {
                        playAudio()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    resetAudio()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
            }
            
            // Progress bar
            VStack {
                Slider(value: $playbackProgress, in: 0...1, onEditingChanged: sliderChanged)
                    .accentColor(.blue)
                
                if let player = audioPlayer {
                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            timer?.invalidate()
            audioPlayer?.stop()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
    
    private func setupAudioPlayer() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("ProcessedAudio.m4a")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.prepareToPlay()
                print("Audio player set up successfully")
            } else {
                errorMessage = "Audio file not found"
                showError = true
                print("Audio file not found at: \(fileURL.path)")
            }
        } catch {
            errorMessage = "Failed to set up audio player: \(error.localizedDescription)"
            showError = true
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func playAudio() {
        guard let player = audioPlayer else { return }
        
        player.play()
        isPlaying = true
        
        // Start a timer to update the progress
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                playbackProgress = player.currentTime / player.duration
                
                // Check if playback has ended
                if !player.isPlaying && playbackProgress >= 1.0 {
                    resetAudio()
                }
            }
        }
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func resetAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        playbackProgress = 0
        isPlaying = false
        timer?.invalidate()
    }
    
    private func sliderChanged(editing: Bool) {
        if let player = audioPlayer {
            if editing {
                pauseAudio()
            }
            
            player.currentTime = player.duration * playbackProgress
            
            if !editing && isPlaying {
                playAudio()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
