//Exam//
////  File.swift
////  PianoTuna
////
////  Created by Flavio de Oliveira Stutz on 3/22/18.
////  Copyright © 2018 StutzLab. All rights reserved.
////
//
//import Foundation
//
//inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
//    self.recognitionRequest?.append(buffer)
//
//    let data =  buffer.floatChannelData?[0]
//    let arrayOfData = Array(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
//    let fftData = self.performFFT(arrayOfData)
//}
//
//
//
//
//func performFFT(_ input: [Float]) -> [Float] {
//
//    var real = [Float](input)
//    var imag = [Float](repeating: 0.0, count: input.count)
//    var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
//
//    let length = vDSP_Length(floor(log2(Float(input.count))))
//    let radix = FFTRadix(kFFTRadix2)
//    let weights = vDSP_create_fftsetup(length, radix)
//    vDSP_fft_zip(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
//
//
//    var magnitudes = [Float](repeating: 0.0, count: input.count)
//    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
//
//    var normalizedMagnitudes = [Float](repeating: 0.0, count: input.count)
//
//    vDSP_vsmul(sqrt(magnitudes), 1, [2.0 / Float(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
//
//    vDSP_destroy_fftsetup(weights)
//    return normalizedMagnitudes
//}
//
//public func sqrt(_ x: [Float]) -> [Float] {
//    var results = [Float](repeating: 0.0, count: x.count)
//    vvsqrtf(&results, x, [Int32(x.count)])
//    return results
//}
//
//
//
//
//
//
//
//
//
//
//
//
//https://blog.metova.com/audio-manipulation-using-avaudioengine
//
//
//do {
//    // Here recordingSession is just a shared instance of AVAudioSession
//
//    try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers, .defaultToSpeaker]) // There are several options here - choose what best suits your needs
//    try recordingSession.setActive(true)
//
//    // I suggest adding notifications here for route and configuration changes
//}
//catch {
//    // Handle the error
//}
//
//let audioEngine = AVAudioEngine()
//
//let audioMixer = AVAudioMixerNode()
//let micMixer = AVAudioMixerNode()
//let reverb = AVAudioUnitReverb()
//let echo = AVAudioUnitDelay()
//let audioPlayerNode = AVAudioPlayerNode()
//
//audioEngine.attach(audioPlayerNode)
//audioEngine.attach(reverb)
//audioEngine.attach(echo)
//audioEngine.attach(audioMixer)
//audioEngine.attach(micMixer)
//
//
//// Sound effect connections
//
//audioEngine.connect(audioMixer, to: audioEngine.mainMixerNode, format: audioFormat)
//audioEngine.connect(echo, to: audioMixer, fromBus: 0, toBus: 0, format: audioFormat)
//audioEngine.connect(reverb, to: echo, fromBus: 0, toBus: 0, format: audioFormat)
//audioEngine.connect(micMixer, to: reverb, format: audioFormat)
//
//// Here we're making multiple output connections from the player node 1) to the main mixer and 2) to another mixer node we're using for adding effects.
//
//let playerConnectionPoints = [
//    AVAudioConnectionPoint(node: audioEngine.mainMixerNode, bus: 0),
//    AVAudioConnectionPoint(node: audioMixer, bus: 1)
//]
//
//audioEngine.connect(audioPlayerNode, to: playerConnectionPoints, fromBus: 0, format: audioFormat)
//
//// Finally making the connection for the mic input
//
//
//guard let micInput = audioEngine.inputNode else { return }
//
//let micFormat = micInput.inputFormat(forBus: 0)
//audioEngine.connect(micInput, to: micMixer, format: micFormat)
//
//
//{
//    // Here trackURL is our audio track
//    if let trackURL = trackURL {
//        audioPlayerFile = try AVAudioFile.init(forReading: trackURL)
//    }
//}
//catch {
//    // HANDLE THE ERROR
//}
//
//// Schedule track audio immediately if read is successful
//
//guard let audioPlayerFile = audioPlayerFile else { return }
//
//audioPlayerNode.scheduleFile(audioPlayerFile, at: nil, completionHandler: nil)
//
//audioURL = URL(fileURLWithPath: <YOUR_OUTPUT_URL>)
//
//if let audioURL = audioURL {
//    do {
//        self.recordedOutputFile = try AVAudioFile(forWriting:  audioURL, settings: audioMixer.outputFormat(forBus: 0).settings)
//    }
//    catch {
//        // HANDLE THE ERROR
//    }
//}
//
//
//// Prepare and start audioEngine
//audioEngine.prepare()
//do {
//    try audioEngine.start()
//}
//catch {
//    // HANDLE ERROR
//}
//
//guard let recordedOutputFile = recordedOutputFile,
//    let audioPlayerFile = audioPlayerFile else { return }
//
//let tapFormat = audioMixer.outputFormat(forBus: 0)
//
//// The data is collected from the buffer using a block
//audioMixer.installTap(onBus: 0, bufferSize: AVAudioFrameCount(recordedOutputFile.length), format: tapFormat)
//{ buffer, _ in
//
//    do {
//        if recordedOutputFile.length < audioPlayerFile.length {
//            try self.recordedOutputFile?.write(from: buffer)
//        }
//        else {
//            self.audioMixer.removeTap(onBus: 0)
//            self.resetAudioEngine()
//            // Handle your UI changes here
//        }
//
//    }
//    catch {
//        // Handle error
//    }
//
//}
//
//
//
//
//
//
//
//
//
////LINEAR INTERPOLATION
////https://stackoverflow.com/questions/1125666/how-do-you-do-bicubic-or-other-non-linear-interpolation-of-re-sampled-audio-da
//
//int newlength = (int)Math.Round(rawdata.Length * lengthMultiplier);
//float[] output = new float[newlength];
//
//for (int i = 0; i < newlength; i++)
//{
//    float realPos = i / lengthMultiplier;
//    int iLow = (int)realPos;
//    int iHigh = iLow + 1;
//    float remainder = realPos - (float)iLow;
//
//    float lowval = 0;
//    float highval = 0;
//    if ((iLow >= 0) && (iLow < rawdata.Length))
//    {
//        lowval = rawdata[iLow];
//    }
//    if ((iHigh >= 0) && (iHigh < rawdata.Length))
//    {
//        highval = rawdata[iHigh];
//    }
//
//    output[i] = (highval * remainder) + (lowval * (1 - remainder));
//}
//
