//
//  BeatingDetector.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 4/6/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class BeatingDetector {

    var fftLoader: FFTLoader!
    var baseFrequency: Double!
    var signalSampleRate: Double!
    
    var useEach: Int!
    var useCount: Int = 0
    
    init(baseFrequency: Double, signalSampleRate: Double, fftSize: Int, fftOverlapRatio: Double = 0.0) {
        self.signalSampleRate = signalSampleRate
        self.baseFrequency = baseFrequency
        let convolutedSampleRate = 128.0
        self.useEach = Int((self.signalSampleRate/WaveletUtils.wavelength(frequency: self.baseFrequency, sampleRate: self.signalSampleRate))/convolutedSampleRate)
        self.fftLoader = FFTLoader(sampleRate: convolutedSampleRate, samplesSize: fftSize, overlapRatio: fftOverlapRatio)
    }
    
    func addSamples(samples: [Double]) -> TempiFFT! {
        let morlet = Morlet(sampleRate: self.signalSampleRate, s: 1)
        let convoluted = morlet.convolve(signal: samples, frequency: self.baseFrequency)
        
        var peaks = Array<Double>()
        var lastPeak = 0.0
        var lastConv = 0.0
        var c = 0
        for conv in convoluted {
            if conv > lastConv {
                if conv > lastPeak {
                    lastPeak = conv
                }
            } else {
                if lastPeak != 0.0 {
                    useCount += 1
                    if useCount%useEach == 0 {
                        peaks.append(lastPeak)
                    }
                    lastPeak = 0.0
                }
            }
            lastConv = conv
            c += 1
        }
        if peaks.count > 0 {
//            print("=============")
//            print(peaks)
        }
        return self.fftLoader.addSamples(samples: peaks)
    }

}
