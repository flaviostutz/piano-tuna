//
//  FFTAnalyser.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/13/18.
//  Copyright © 2018 John Scalo. All rights reserved.
//

import Foundation

class FFTPitchAnalyser {

    var fft: TempiFFT
    
    init(_ fft: TempiFFT) {
        self.fft = fft
    }

    func detectFrequencyPeaks(minMagnitude: Float) -> [Float] {
        var peakFreqs = Array<Float>()
        let spectrum = fft.spectrum()
        var lastMag: Float = 0
        var lastLastMag: Float = 0
        var currentPeakMag: Float = 0
        var spectrumIndex = 0
        for mag in spectrum {
            
            //climbing peak
            if mag>=currentPeakMag && mag>minMagnitude{
                currentPeakMag = mag
                
            //just after the peak
            } else {
                
                if lastLastMag>0 && lastMag>0 && currentPeakMag>0 {
                    
                    //calculate best frequency fit between (possible) peak elements
                    //see other methods at https://dspguru.com/dsp/howtos/how-to-interpolate-fft-peak/
                    var peak1 = currentPeakMag
                    //FIXME verify if when we have only two peaks, the accuracy gets OK with this strategy
                    if abs(lastLastMag-currentPeakMag)/currentPeakMag < 0.5 {
                        peak1 = lastLastMag
                    }
                    
                    let peak2 = currentPeakMag

                    var peak3 = currentPeakMag
                    if abs(mag-currentPeakMag)/currentPeakMag < 0.5 {
                        peak3 = mag
                    }
                    
                    //Barycentric method
                    let indexDiff: Float = (peak3 - peak1) / (peak1 + peak2 + peak3)
                    let freqDiff = (indexDiff * self.fft.bandwidth)
                    print(freqDiff)
                    
                    let peakFreq = self.fft.spectrumFreqAtIndex(index: spectrumIndex-1) + freqDiff

                    peakFreqs.append(peakFreq)
                }
                
                currentPeakMag = 0
                lastLastMag = 0
                lastMag = 0
            }
            
            lastLastMag = lastMag
            lastMag = mag
            spectrumIndex = spectrumIndex+1
        }
        return peakFreqs
    }
    
    func detectFundamentalFrequencies(minHarmonics:Int) -> [Float] {
        return [3.2,32.0]
    }
}


