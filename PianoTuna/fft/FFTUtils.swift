//
//  FFTUtils.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class FFTUtils {

    static func calculateFrequencyPeaks(spectrum: [Double], binWidth: Double, minMagnitude: Double=0.001, fromFrequency: Double! = nil, toFrequency: Double! = nil) -> [(frequency: Double, magnitude: Double)] {
        var peakFreqs = Array<(frequency: Double, magnitude: Double)>()
        var climbing: Bool = true
        
        if spectrum.count<3 {
            return peakFreqs
        }
        
        for i in 2..<spectrum.count {
            var filter = true
            let currentFrequency = (binWidth * (Double(i)-1))
            if fromFrequency != nil && currentFrequency<fromFrequency {
                filter = false
            } else if toFrequency != nil && currentFrequency>toFrequency {
                filter = false
            }
            
            if filter &&
               climbing &&
               spectrum[i-1]>minMagnitude &&
               spectrum[i]<spectrum[i-1] {
                //calculate best frequency fit between (possible) peak elements
                //see other methods at https://dspguru.com/dsp/howtos/how-to-interpolate-fft-peak/

                //Barycentric method
                let indexDiff: Double = (spectrum[i] - spectrum[i-2]) / (spectrum[i-2] + spectrum[i-1] + spectrum[i])
                
                let freqDiff = (indexDiff * binWidth)
                let peakFreq = currentFrequency + freqDiff
                peakFreqs.append((frequency:peakFreq, magnitude:spectrum[i-1]))
            }
            
            climbing = spectrum[i]>spectrum[i-1]
            
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
