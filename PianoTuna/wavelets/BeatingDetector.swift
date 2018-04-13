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
    
    var lastConvoluted: [Double]!
    var lastPeaks: [Double]!
    
    var useEach: Int!
    var useCount: Int = 0
    
    var averager: MovingAverage!
    
    var buffer: CircularArray<Double>!
    
    init(baseFrequency: Double, signalSampleRate: Double, fftSize: Int, fftOverlapRatio: Double = 0.3) {
        self.signalSampleRate = signalSampleRate
        self.baseFrequency = baseFrequency
        let convolutedSampleRate = 128.0
        self.useEach = Int((self.signalSampleRate/WaveletUtils.wavelength(frequency: self.baseFrequency, sampleRate: self.signalSampleRate))/convolutedSampleRate)
        self.fftLoader = FFTLoader(sampleRate: convolutedSampleRate, samplesSize: fftSize, overlapRatio: fftOverlapRatio)
        self.averager = MovingAverage(numberOfSamples: 1)
        self.buffer = CircularArray<Double>()
    }
    
    func addSamples(samples: [Double]) -> TempiFFT! {
        for s in samples {
            self.buffer.append(s)
        }
        if self.buffer.count>=2048 {
            let bufferSamples = self.buffer.map { (elem) -> Double in
                return elem
            }
            self.buffer.removeAll()
            let morlet = Morlet(sampleRate: self.signalSampleRate, s: 1)
            let convoluted = morlet.convolve(signal: bufferSamples, frequency: self.baseFrequency)
            
            let wavelength = Int(WaveletUtils.wavelength(frequency: self.baseFrequency, sampleRate: self.signalSampleRate))
            var peaks = Array<Double>()
            var lastPeak = 0.0
            var lastConv = 0.0
            var c = 0
            for conv in convoluted {
                //ignore the edges because they were modified by the gaussian window of the morlet
                if c>wavelength && c<convoluted.count-wavelength {
                    if conv > lastConv {
                        if conv > lastPeak {
                            lastPeak = conv
                        }
                    } else {
                        if lastPeak != 0.0 {
                            useCount += 1
                            //downsampling
                            if useCount%useEach == 0 {
                                self.averager.addSample(value: lastPeak)
                                let avg = self.averager.getAverage()
                                if avg != nil {
                                    peaks.append(avg!)
                                }
                            }
                            lastPeak = 0.0
                        }
                    }
                    lastConv = conv
                }
                c += 1
            }
            //        if peaks.count > 0 {
            //            print("=============")
            //            print(peaks)
            //        }
            self.lastConvoluted = convoluted
            self.lastPeaks = peaks
            return self.fftLoader.addSamples(samples: peaks)
        } else {
            return nil
        }
    }

}
