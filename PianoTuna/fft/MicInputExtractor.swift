////
////  MicInputWorker.swift
////  PianoTuna
////
////  Created by Flavio de Oliveira Stutz on 3/22/18.
////  Copyright © 2018 StutzLab. All rights reserved.
////
//
//import Foundation
//import AVFoundation
//
////reference https://blog.metova.com/audio-manipulation-using-avaudioengine
//
//class MicInputWorker {
// 
//    init() {
//        // Here recordingSession is just a shared instance of AVAudioSession
//        try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers, .defaultToSpeaker]) // There are several options here - choose what best suits your needs
//        try recordingSession.setActive(true)
//        
//        // I suggest adding notifications here for route and configuration changes
//        
//        let audioEngine = AVAudioEngine()
//        
//        let audioMixer = AVAudioMixerNode()
//        let micMixer = AVAudioMixerNode()
//        let reverb = AVAudioUnitReverb()
//        let echo = AVAudioUnitDelay()
//        let audioPlayerNode = AVAudioPlayerNode()
//
//        
//        let pitchEffect: AVAudioUnitTimePitch = AVAudioUnitTimePitch()
//        
//        // Set the pitch-shift amount (100 cents = 1 semitone)
//        pitchEffect.pitch = 100.0 // +1 semitone
//        pitchEffect.overlap = 12.0 // more overlapping windows
//        
//        // Add nodes to engine
//        engine.attachNode(player)
//        engine.attachNode(pitchEffect)
//        
//        // Connect the player's output to the effect's input
//        engine.connect(player, to: pitchEffect, format: file.processingFormat)
//        // Connect the effect's output to the main mixer's input
//        engine.connect(pitchEffect, to: engine.mainMixerNode, format: file.processingFormat)
//        
//        
//        
//        audioEngine.attach(audioPlayerNode)
//        audioEngine.attach(reverb)
//        audioEngine.attach(echo)
//        audioEngine.attach(audioMixer)
//        audioEngine.attach(micMixer)
//        
//        
//        // Sound effect connections
//        
//        audioEngine.connect(audioMixer, to: audioEngine.mainMixerNode, format: audioFormat)
//        audioEngine.connect(echo, to: audioMixer, fromBus: 0, toBus: 0, format: audioFormat)
//        audioEngine.connect(reverb, to: echo, fromBus: 0, toBus: 0, format: audioFormat)
//        audioEngine.connect(micMixer, to: reverb, format: audioFormat)
//        
//        // Here we're making multiple output connections from the player node 1) to the main mixer and 2) to another mixer node we're using for adding effects.
//        
//        let playerConnectionPoints = [
//            AVAudioConnectionPoint(node: audioEngine.mainMixerNode, bus: 0),
//            AVAudioConnectionPoint(node: audioMixer, bus: 1)
//        ]
//        
//        audioEngine.connect(audioPlayerNode, to: playerConnectionPoints, fromBus: 0, format: audioFormat)
//        
//        // Finally making the connection for the mic input
//        
//        
//        guard let micInput = audioEngine.inputNode else { return }
//        
//        let micFormat = micInput.inputFormat(forBus: 0)
//        audioEngine.connect(micInput, to: micMixer, format: micFormat)
//
//    }
//    
//    func startListening(bufferCallback: FUNC_HERE, pitchCents: Double, rate: Double) {
//        let tapFormat = audioMixer.outputFormat(forBus: 0)
//        
//        // The data is collected from the buffer using a block
//        audioMixer.installTap(onBus: 0, bufferSize: AVAudioFrameCount(recordedOutputFile.length), format: tapFormat)
//        { buffer, _ in
//            
//            if recordedOutputFile.length < audioPlayerFile.length {
//                try self.recordedOutputFile?.write(from: buffer)
//            }
//            else {
//                self.audioMixer.removeTap(onBus: 0)
//                self.resetAudioEngine()
//                // Handle your UI changes here
//            }
//                
//        }
//        
//        // Prepare and start audioEngine
//        audioEngine.prepare()
//        try audioEngine.start()
//    }
//    
//}
//
//
