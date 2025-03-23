//
//  UploadView.swift
//  8Dify
//
//  Created by Shashwath Dinesh on 3/22/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct UploadView: View {
    @State private var isImporting = false
    @State private var audioURL: URL?
    @State private var processing = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("8D Audio Processor")
                .font(.title)
            
            if let audioURL = audioURL {
                Text("Selected file: \(audioURL.lastPathComponent)")
            } else {
                Text("No file selected")
            }
            
            Button("Select Audio File") {
                isImporting = true
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.audio],
                onCompletion: handleFileImport
            )
            
            Button("Process Audio") {
                if let url = audioURL {
                    processing = true
                    statusMessage = "Processing..."
                    DispatchQueue.global(qos: .userInitiated).async {
                        processAudio(inputURL: url)
                        DispatchQueue.main.async {
                            processing = false
                            statusMessage = "Processing complete. Check the Files tab."
                        }
                    }
                }
            }
            .disabled(audioURL == nil || processing)
            
            if processing {
                ProgressView("Processing...")
            }
            
            Text(statusMessage)
                .padding()
            
            Spacer()
        }
        .padding()
    }
    
    func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            audioURL = url
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
    
    func processAudio(inputURL: URL) {
        let fileManager = FileManager.default
        // Get the app's Documents directory
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Create a local URL in Documents using the same file name as the input file
        let localInputURL = documentsURL.appendingPathComponent(inputURL.lastPathComponent)
        
        // Begin security-scoped access on the original file URL (if supported)
        var inputNeedsStopAccessing = false
        if inputURL.startAccessingSecurityScopedResource() {
            inputNeedsStopAccessing = true
        }
        defer {
            if inputNeedsStopAccessing {
                inputURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Copy the input file into our Documents folder if it doesn't already exist
        if !fileManager.fileExists(atPath: localInputURL.path) {
            do {
                try fileManager.copyItem(at: inputURL, to: localInputURL)
                print("✅ Copied file to local directory: \(localInputURL)")
            } catch {
                print("E: Error copying file: \(error.localizedDescription)")
                return
            }
        } else {
            print("✅ Local file already exists at: \(localInputURL)")
        }
        
        guard fileManager.fileExists(atPath: localInputURL.path) else {
            print("E: Local input file not found at: \(localInputURL.path)")
            return
        }
        
        // No need to security-access the local copy (Documents folder is in our sandbox)
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let reverb = AVAudioUnitReverb()
        let mixer = engine.mainMixerNode
        
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 60
        
        engine.attach(player)
        engine.attach(reverb)
        engine.connect(player, to: reverb, format: nil)
        engine.connect(reverb, to: mixer, format: nil)
        
        do {
            let audioFile = try AVAudioFile(forReading: localInputURL)
            print("✅ Successfully loaded input file from: \(localInputURL.path)")
            
            // Schedule the file for playback
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
            
            // Enable offline rendering
            try engine.enableManualRenderingMode(.offline, format: audioFile.processingFormat, maximumFrameCount: 4096)
            try engine.start()
            player.play()
            
            // Prepare the output file URL in Documents
            let outputURL = documentsURL.appendingPathComponent("ProcessedAudio.m4a")
            print("📂 Output file will be saved to: \(outputURL)")
            
            if fileManager.fileExists(atPath: outputURL.path) {
                do {
                    try fileManager.removeItem(at: outputURL)
                    print("✅ Existing output file removed.")
                } catch {
                    print("E: Could not remove existing file: \(error.localizedDescription)")
                    return
                }
            }
            
            let outputFormat = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: audioFile.fileFormat.sampleRate,
                AVNumberOfChannelsKey: audioFile.fileFormat.channelCount,
                AVEncoderBitRateKey: 128000
            ] as [String: Any]
            
            let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputFormat)
            
            let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                          frameCapacity: engine.manualRenderingMaximumFrameCount)!
            
            // Process and apply the 8D-like panning effect
            while engine.manualRenderingSampleTime < audioFile.length {
                let phase = Float(engine.manualRenderingSampleTime) / Float(audioFile.processingFormat.sampleRate) * 2.0 * Float.pi * 0.5
                let newPan = sin(phase)
                DispatchQueue.main.async {
                    mixer.pan = newPan
                }
                
                let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(audioFile.length - engine.manualRenderingSampleTime))
                let status = try engine.renderOffline(framesToRender, to: buffer)
                
                if status == .success {
                    try outputFile.write(from: buffer)
                } else {
                    print("W: Offline rendering failed at sample time \(engine.manualRenderingSampleTime)")
                    break
                }
            }
            
            engine.stop()
            print("✅ Processed audio saved at: \(outputURL)")
            
        } catch {
            print("E: Error processing audio: \(error.localizedDescription)")
        }
    }
}
