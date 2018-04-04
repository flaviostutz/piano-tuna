//
//  MathUtils.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/28/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class MathUtils {
    
    static func remaining(value: Double, divisor: Double) -> Double {
        let di = Int(value)/Int(divisor)
        return value - Double(di)*divisor
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
    
    static func gaussianWindow(windowSize:Int, sigma: Double) -> [Double] {
        var window = Array<Double>(repeating:0.0, count: windowSize)
        let windowSizeHalf = windowSize/2
        for i in 0..<windowSizeHalf {
            //calculate with x from -1 to 1
            let x = Double(i)/Double(windowSize)
            let ax = sigma * x
            let one = exp(-0.5 * ax*ax)
            
            //expand to windowSize and mirror copy the result to halves of the window
            window[i+windowSizeHalf] = one
            window[windowSize-(i+windowSizeHalf)] = one
        }
        
        return window
    }

    
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
                
                let max_bin = i-1
                let s0 = log(spectrum[max_bin-1])
                let s1 = log(spectrum[max_bin])
                let s2 = log(spectrum[max_bin+1])
                
                //Barycentric method
                //                let indexDiff: Double = (s2 - s0) / (s0 + s1 + s2)
                
                //Gaussian interpolation (err<=0.4Hz)
                //                let indexDiff = log(s2/s0)*0.5/log(s1*s1/(s2*s0))
                
                //Quadratic interpolation
                //                let indexDiff = (1/2) * ((s0-s2)/(s0 - 2*s1 + s2))
                
                //Parabolic interpolation (best err<=0.25Hz; fft with gaussian window and magnitudes in log to match vectorial field)
                let indexDiff = (s2-s0)/(2*(2*s1 - s0 - s2))
                
                if !indexDiff.isNaN {
                    let freqDiff = (indexDiff * binWidth)
                    let peakFreq = currentFrequency + freqDiff
                    peakFreqs.append((frequency:peakFreq, magnitude:spectrum[i-1]))
                } else {
                    //                    print("NOT A NUMBER FOUND!")
                }
            }
            
            climbing = spectrum[i]>spectrum[i-1]
            
        }
        return peakFreqs
    }

    static func findPeaks(data: [Double], minValue: Double=0.0001) -> [(index: Int, preciseIndex: Double, value: Double)] {
        var peaks = Array<(index: Int, preciseIndex: Double, value: Double)>()
        var climbing: Bool = true
        
        if data.count<3 {
            return peaks
        }
        
        for i in 2..<data.count {
            if climbing &&
                data[i-1]>minValue &&
                data[i]<data[i-1] {
                //calculate best index diff fit between (possible) peak elements
                //see other methods at https://dspguru.com/dsp/howtos/how-to-interpolate-fft-peak/
                
                let max_i = i-1
                let s0 = data[max_i-1]
                let s1 = data[max_i]
                let s2 = data[max_i+1]
                
                //Barycentric method
                //                let indexDiff: Double = (s2 - s0) / (s0 + s1 + s2)
                
                //Gaussian interpolation (err<=0.4Hz)
                //                let indexDiff = log(s2/s0)*0.5/log(s1*s1/(s2*s0))
                
                //Quadratic interpolation
                //                let indexDiff = (1/2) * ((s0-s2)/(s0 - 2*s1 + s2))
                
                //Parabolic interpolation
                let indexDiff = (s2-s0)/(2*(2*s1 - s0 - s2))
                
                peaks.append((index:max_i, preciseIndex:Double(max_i)+indexDiff, value:s1))
            }
            climbing = data[i]>data[i-1]
        }
        return peaks
    }

}
