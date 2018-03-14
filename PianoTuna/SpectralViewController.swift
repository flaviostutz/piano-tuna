//
//  SpectralViewController.swift
//  TempiHarness
//
//  Created by John Scalo on 1/7/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit
import AVFoundation

class SpectralViewController: UIViewController {
    
    var audioInput: TempiAudioInput!
    var spectralView: SpectralView!
    
    //PARAMETERS
    var sampleRate: Float = 16000//piano max frequency is 8kHz
    var circularBufferSize: Int = 1024
    
    var lastTimeStamp: Double = 0
    var lastTimeStampCircularBuffer: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let bounds = CGRect(origin:self.view.bounds.origin, size:CGSize(width:view.bounds.width, height:self.view.bounds.height - 50))
        spectralView = SpectralView(frame: bounds)
        spectralView.backgroundColor = UIColor.black
        self.view.addSubview(spectralView)
        
        var circularSamplesBuffer = CircularArray<Float>()
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
//            print("audio frame count=\(numberOfFrames) freq=\(1/(timeStamp-self.lastTimeStamp))Hz (\((timeStamp-self.lastTimeStamp)*1000)ms)")
            self.lastTimeStamp = timeStamp
//            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)

            //expand FFT size with an internal buffer
            for sample in samples {
                circularSamplesBuffer.append(sample)
                //keep buffer with a maximum size
                if circularSamplesBuffer.count>self.circularBufferSize {
                    circularSamplesBuffer.removeFirst()
                }
            }
            let bufferSamples = circularSamplesBuffer.map({ (element) -> Float in
                return element
            })
            
            if(circularSamplesBuffer.count==self.circularBufferSize) {
//                print("buffer frame count=\(bufferSamples.count) freq=\(1/(timeStamp-self.lastTimeStampCircularBuffer))Hz (\((timeStamp-self.lastTimeStampCircularBuffer)*1000)ms)")
                self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: circularSamplesBuffer.count, samples: bufferSamples)
                circularSamplesBuffer.removeAll(keepingCapacity:false)
                self.lastTimeStampCircularBuffer = timeStamp
            }
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: sampleRate, numberOfChannels: 1)
        audioInput.startRecording()
    }

    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: sampleRate)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
        
        // Interpolate the FFT data so there's one band per pixel.
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
//        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))
//        print("numberOfBands=\(Int(screenWidth))")
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))

        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.setNeedsDisplay()
        }
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

