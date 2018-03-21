//
//  FFTUtils.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class FFTUtils {

    static func calculateFrequencyPeaks(spectrum: [Double], binWidth: Double, minMagnitude: Double=0.1, fromFrequency: Double! = nil, toFrequency: Double! = nil) -> [(frequency: Double, magnitude: Double)] {
        var peakFreqs = Array<(frequency: Double, magnitude: Double)>()
        var lastMag: Double = 0
        var lastLastMag: Double = 0
        var spectrumIndex = 0
        
        for mag in spectrum {
            
            var filter = mag>minMagnitude
            if filter {
                let currentFrequency = (binWidth * (Double(spectrumIndex)-1))
                if fromFrequency != nil && currentFrequency<fromFrequency {
                    filter = false
                } else if toFrequency != nil && currentFrequency>toFrequency {
                    filter = false
                }
            }
            
            //climbing peak
            if mag>=lastMag && filter {

                
            //just after the peak
            } else {
                
                if lastLastMag>0 && lastMag>0 && mag<=lastMag {
                    
                    //calculate best frequency fit between (possible) peak elements
                    //see other methods at https://dspguru.com/dsp/howtos/how-to-interpolate-fft-peak/
                    let peak1 = lastLastMag
                    let peak2 = lastMag
                    let peak3 = mag
                    
                    //Barycentric method
                    let indexDiff: Double = (peak3 - peak1) / (peak1 + peak2 + peak3)
                    let freqDiff = (indexDiff * binWidth)
//                    print(freqDiff)
                    
                    let peakFreq = (binWidth * (Double(spectrumIndex)-1)) + freqDiff
                    
                    peakFreqs.append((frequency:peakFreq, magnitude:lastMag))
                }
            }
            
            lastLastMag = lastMag
            lastMag = mag
            
            spectrumIndex = spectrumIndex+1
        }
        return peakFreqs
    }

    //returns a ratio from -1 to 1 on how near are the values
    //valuesNearRatio(5, 10, 20) returns 0.75 because their diff is 25% of 20
    //valuesNearRatio(0, 0.1, 1) returns 0.1 because their diff is 90% of 1
    //valuesNearRatio(100, 1000, 20) returns 0.1 because their diff is 90% of 1
    static func valuesNearRatio(value1: Double, value2: Double, zeroDiff: Double) -> Double {
        let diff = abs(value1 - value2)
        let diff2 = zeroDiff - diff
        return max(-1, diff2/zeroDiff)
    }
    
    /// A convenience function that converts a linear magnitude (like those stored in ```magnitudes```) to db (which is log 10).
    static func toDB(_ inMagnitude: Double) -> Double {
        // ceil to 128db in order to avoid log10'ing 0
        let magnitude = max(inMagnitude, 0.000000000001)
        return 10 * log10(magnitude)
    }

}
