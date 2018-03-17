//
//  FFTUtils.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class FFTUtils {

    static func calculateFrequencyPeaks(spectrum: [Float], binWidth: Float, minMagnitude: Float=0.1) -> [(frequency: Float, magnitude: Float)] {
        var peakFreqs = Array<(frequency: Float, magnitude: Float)>()
        var lastMag: Float = 0
        var lastLastMag: Float = 0
        var currentPeakMag: Float = 0
        var spectrumIndex = 0
        
        for mag in spectrum {
            
            //climbing peak
            if mag>=currentPeakMag && mag>minMagnitude {
                currentPeakMag = mag
                
            //just after the peak
            } else {
                
                if lastLastMag>0 && lastMag>0 && currentPeakMag>0 {
                    
                    //calculate best frequency fit between (possible) peak elements
                    //see other methods at https://dspguru.com/dsp/howtos/how-to-interpolate-fft-peak/
                    let peak1 = lastLastMag
                    let peak2 = currentPeakMag
                    let peak3 = mag
                    
                    //Barycentric method
                    let indexDiff: Float = (peak3 - peak1) / (peak1 + peak2 + peak3)
                    let freqDiff = (indexDiff * binWidth)
//                    print(freqDiff)
                    
                    let peakFreq = (binWidth * (Float(spectrumIndex)-1)) + freqDiff
                    
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
    
    //calculates a matrix that describes (from -1 to 1) in which parts of the spectrum it is expected to detect a peak for a specified fundamental frequency
    static func calculateHarmonicsMask(fundamentalFrequency: Float, binCount: Int, binWidth: Float) -> [Float] {
        var mask = Array<Float>()
        var freq: Float = 0
        var currentOvertone = fundamentalFrequency
        for i in 0..<binCount {
            if freq >= currentOvertone + (fundamentalFrequency/2) {
                currentOvertone = currentOvertone + fundamentalFrequency
            }
            mask.append(FFTUtils.valuesNearRatio(value1:freq, value2:currentOvertone, zeroDiff:fundamentalFrequency/4))
            freq = freq + binWidth
        }
//        print(mask)
        return mask
    }
    
    //returns a ratio from -1 to 1 on how near are the values
    //valuesNearRatio(5, 10, 20) returns 0.75 because their diff is 25% of 20
    //valuesNearRatio(0, 0.1, 1) returns 0.1 because their diff is 90% of 1
    //valuesNearRatio(100, 1000, 20) returns 0.1 because their diff is 90% of 1
    static func valuesNearRatio(value1: Float, value2: Float, zeroDiff: Float) -> Float {
        let diff = abs(value1 - value2)
        let diff2 = zeroDiff - diff
        return max(-1, diff2/zeroDiff)
    }
    
    /// A convenience function that converts a linear magnitude (like those stored in ```magnitudes```) to db (which is log 10).
    static func toDB(_ inMagnitude: Float) -> Float {
        // ceil to 128db in order to avoid log10'ing 0
        let magnitude = max(inMagnitude, 0.000000000001)
        return 10 * log10f(magnitude)
    }

}
