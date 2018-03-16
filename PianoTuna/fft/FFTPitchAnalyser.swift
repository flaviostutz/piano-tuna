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

    func detectFrequencyPeaksFFT(minMagnitude: Float=0.1, cutoutFreq: Float=50) -> [(frequency: Float, magnitude: Float)] {
        let spectrum = fft.spectrum()
        return detectFrequencyPeaks(spectrum: spectrum, minMagnitude:minMagnitude, cutoutFreq:cutoutFreq)
    }

    private func detectFrequencyPeaks(spectrum: [Float], minMagnitude: Float=0.1, cutoutFreq: Float=50) -> [(frequency: Float, magnitude: Float)] {
        var peakFreqs = Array<(frequency: Float, magnitude: Float)>()
        var lastMag: Float = 0
        var lastLastMag: Float = 0
        var currentPeakMag: Float = 0
        var spectrumIndex = 0
        for mag in spectrum {
            
            //climbing peak
            if mag>=currentPeakMag && mag>minMagnitude && self.fft.spectrumFreqAtIndex(spectrumIndex)>=cutoutFreq {
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
//                    print(freqDiff)
                    
                    let peakFreq = self.fft.spectrumFreqAtIndex(spectrumIndex-1) + freqDiff

                    peakFreqs.append((frequency:peakFreq, magnitude:currentPeakMag))
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
    
    func detectFundamentalFrequencies(harmonics: Int=3, minMagnitude: Float=1) -> [(frequency: Float, magnitude: Float)] {
        //using Harmonic Product Spectrum (HPS) for now
        //more at https://cnx.org/contents/i5AAkZCP@2/Pitch-Detection-Algorithms

        let minIndex = 20

        var spectrum = fft.spectrum()
        let maxIndex = spectrum.count - 1
        var maxHIndex = spectrum.count / harmonics
        
        if maxHIndex*harmonics > maxIndex {
            maxHIndex = Int(Float(maxIndex/harmonics).rounded())
        }
        
        for j in minIndex...maxHIndex {
            for i in 1...harmonics {
                spectrum[j] *= spectrum[j * i]
            }
        }
        
        let hpsPeaks = detectFrequencyPeaks(spectrum: spectrum, minMagnitude: minMagnitude)
        return hpsPeaks
    }
}


