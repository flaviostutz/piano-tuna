//
//  StutzFFT.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/21/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

//This is the entrypoint for FFT analysis for input buffer accumulation and other tools over the resulting FFT matrix, like averaging and linear regression for better stability
class FFTLoader {
    
    private var buffer: CircularArray<Double>!
    
    private var samplesSize: Int!
    private var sampleRate: Double!
    
    let forwardFrequency = FrequencyMeasure()
    
    init(sampleRate: Double, samplesSize: Int) {
        self.buffer = CircularArray<Double>(maxSize: samplesSize)
        self.sampleRate = sampleRate
        self.samplesSize = samplesSize
    }
    
    func addSamples(samples: [Double]) -> TempiFFT! {
        for s in samples {
            self.buffer.append(s)
            if self.buffer.count == self.buffer.maxSize {
                let bufferSamples = self.buffer.map({ (element) -> Double in
                    return element
                })
                let fft = TempiFFT(withSize: self.samplesSize, sampleRate: self.sampleRate)
                fft.windowType = TempiFFTWindowType.gaussian
                fft.fftForward(bufferSamples, useLogScale: false)
                forwardFrequency.tick()
                self.buffer.removeAll(keepingCapacity: false)
                return fft
            }
        }
        return nil
    }
    
}
