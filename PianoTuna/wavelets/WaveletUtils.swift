//
//  TransformWavelet.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/28/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation
import Darwin

class WaveletUtils {
    
//    static func frequencyPeaksSearch(signal: [Double], sampleRate: Double, fromFrequency: Double, toFrequency: Double, expectedPeaks: Int = 3, iterationsPerPeak: Int = 5) -> [Double] {
//        var levels = Array<(level: Double, diff: Double)>()
//        
//    }
    
    static func frequencyMatchLevel(signal: [Double], sampleRate: Double, frequency: Double) -> (frequency: Double, level: Double, measuredFrequency: Double, debug: [Double])! {
        
//        let analysisPeriods = 10.0
        let morlet = Morlet(sampleRate:sampleRate, s: 1)
        
//        let signalPeriods = floor(Double(signal.count)/wl)

//        print("[0:\(Int(wl*analysisPeriods))] [\(Int((signalPeriods-analysisPeriods)*wl)):\(signal.count)]")
        
//        //find best match location at the beginning of the signal
//        let convoluted1 = morlet.convolve(signal: Array(signal[...Int(wl*analysisPeriods)]), frequency: frequency)
//        let sum1 = convoluted1.reduce(0, { (elem1, elem2) -> Double in
//            return elem1 + abs(elem2)
//        })
//
//        let peaks1 = MathUtils.findPeaks(data: convoluted1)
//        var periodsSum = 0.0
//        var last: (index:Int, preciseIndex:Double, value:Double)!
////        print("peaks1 \(peaks1)")
//        for p in peaks1 {
//            if last != nil {
//                periodsSum += (p.preciseIndex-last.preciseIndex)
//            }
//            last = p
//        }
//        let period1Length = (periodsSum/Double(peaks1.count-1))
//        let baseIndex1 = peaks1[0].preciseIndex + period1Length
//
//        //find best match location at the end of the signal
//        let convoluted2 = morlet.convolve(signal: Array(signal[(Int((signalPeriods-analysisPeriods)*wl))...]), frequency: frequency)
//        let peaks2 = MathUtils.findPeaks(data: convoluted2)
//        periodsSum = 0.0
//        last = nil
////        print("peaks2 \(peaks2)")
//        for p in peaks2 {
//            if last != nil {
//                periodsSum += (p.preciseIndex-last.preciseIndex)
//            }
//            last = p
//        }
//        let period2Length = (periodsSum/Double(peaks2.count-1))
//        let baseIndex2 = Double(Int((signalPeriods-analysisPeriods)*wl)) + peaks2[0].preciseIndex + period2Length
//        print("period1=\(period1Length) baseIndex1=\(baseIndex1) period2=\(period2Length) baseIndex2=\(baseIndex2)")
        
        
        
//        let signalShifted = signal.map { (elem) -> Double in
//            print(elem)
//            return elem// - 1.0
//        }
        let convoluted = morlet.convolve(signal: signal, frequency: frequency)
        let sum = convoluted.reduce(0, { (elem1, elem2) -> Double in
            return elem1 + max(0, elem2)
        })
        let peaks = MathUtils.findPeaks(data: convoluted)
        
//        print("wl=\(wl)")
        //measure peaks frequency
        var last: (index:Int, preciseIndex:Double, value:Double)!
        let debug = signal
//        var sumPeriods = 0.0
//        var debug = Array<Double>()
//          let debug = signal
//        let debug = convoluted.map { (elem) -> Double in
//            return elem+0.5
//        }
        var c = 0
        let referenceWavelength = WaveletUtils.wavelength(frequency: frequency, sampleRate: sampleRate)
        let lr = LinearRegression(numberOfSamples: peaks.count)
        var artificialCount = 0
        for p in peaks {
            //use only center samples. edge samples have wrong values
            //            if c>Int(Double(peaks.count)*0.2) && c<Int(Double(peaks.count)*0.8) {
            if c>Int(Double(peaks.count)*0.1) && c<Int(Double(peaks.count)*0.9) {
                if last != nil {
                    var wl = (p.preciseIndex-last.preciseIndex)
                    //ignore this sample. seems like noise
                    if abs(referenceWavelength-wl)>(referenceWavelength*0.1) {
//                        print("ignoring wavelength. seems like noise. diff=\(referenceWavelength-wl)")
                        wl = referenceWavelength
                        artificialCount += 1
                    }
                    lr.addSample(y:wl)
//                    sumPeriods += wl
//                    debug.append(wl)
                }
                last = p
            }
            c += 1
        }
//        let measuredFrequency = WaveletUtils.frequency(wavelength: (sumPeriods/Double(peaks.count-1)), sampleRate: sampleRate)
        let wavelength = lr.calculateBestYValue()
        if wavelength != nil && artificialCount<peaks.count/2 {
            let measuredFrequency = WaveletUtils.frequency(wavelength: wavelength!, sampleRate: sampleRate)
            return (frequency: frequency, level: sum, measuredFrequency: measuredFrequency, debug: debug)
        } else {
            return nil
        }

//        let diff = measuredFrequency-frequency
        
//        var diff = MathUtils.remaining(value: (baseIndex2-baseIndex1), divisor: wl)
//        if diff > wl/2.0 {
//            diff = diff - wl
//        }

    }

//    static func beatFrequenciesDetection(baseFrequency: Double, signal: [Double], sampleRate: Double) -> [(level: Double, measuredFrequency: Double, debug: [Double])] {
//        let morlet = Morlet(sampleRate: sampleRate, s: 1)
//        let convoluted = morlet.convolve(signal: signal, frequency: baseFrequency)
//
//        var peaks = Array<Double>()
//        var lastPeak = 0.0
//        var lastConv = 0.0
//        for conv in convoluted {
//            if conv > lastConv {
//                if conv > lastPeak {
//                    lastPeak = conv
//                }
//            } else {
//                if lastPeak != 0.0 {
//                    peaks.append(lastPeak)
//                    lastPeak = 0.0
//                }
//            }
//            lastConv = conv
//            if peaks.count == 64 {
//                break
//            }
//        }
//        
////        print(peaks)
//        
//        var freqs = Array<(level: Double, measuredFrequency: Double, debug: [Double])>()
//        
//        if peaks.count == 64 {
//            let tfft = TempiFFT(withSize: peaks.count, sampleRate: Double(sampleRate/wavelength(frequency: baseFrequency, sampleRate: sampleRate)))
//            tfft.fftForward(peaks)
//            
//            for i in 0..<tfft.magnitudes.count {
//                freqs.append((level: tfft.spectrum()[i], measuredFrequency: Double(i+1), debug: peaks))
//            }
//        }
//        
//        return freqs
//    }
    
//    static func frequencyMatchLevel(signal: [Double], sampleRate: Double, frequency: Double) -> Double {
//        let wl = WaveletUtils.wavelength(frequency: frequency, sampleRate: sampleRate)
//        let s = max(1, (signal.count/wl) - 3)
//        let morlet = Morlet(sampleRate:sampleRate, s:s)
//        let convoluted = morlet.convolve(signal: Array(signal), frequency: frequency)
//        let sum = convoluted.reduce(0, { (elem1, elem2) -> Double in
//            return elem1 + abs(elem2)
//        })
//        return sum
//    }

    static func wavelength(frequency: Double, sampleRate: Double) -> Double {
        return sampleRate/frequency
    }
    
    static func frequency(wavelength: Double, sampleRate: Double) -> Double {
        return sampleRate/wavelength
    }
    
}
