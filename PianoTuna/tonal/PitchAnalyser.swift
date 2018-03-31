//
//  PitchAnalyser.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/13/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class PitchAnalyser {

    static func detectFundamentalFrequencies(fft: TempiFFT, harmonics: Int=4, minMagnitude: Double=0.1) -> [(frequency: Double, score: Double, magnitude: Double)] {
        //apply HPS
        let hpsSpectrum = calculateHPSSpectrum(spectrum: fft.spectrum(), harmonics: harmonics)
        let hpsPeaks = MathUtils.calculateFrequencyPeaks(spectrum: hpsSpectrum, binWidth: fft.bandwidth, minMagnitude: minMagnitude)

        let peakFundamentalFreqsScore = hpsPeaks.map { (peak) -> (frequency: Double, score: Double, magnitude: Double) in
            //get fundamental frequency in raw spectrum related to HPS detection
            let fp = MathUtils.calculateFrequencyPeaks(spectrum: fft.spectrum(), binWidth: fft.bandwidth)
            let closest = fp.sorted(by: { (elem1, elem2) -> Bool in
                return abs(elem1.frequency-peak.frequency)<abs(elem2.frequency-peak.frequency)
            })

            //calculate how close to a rich tonal sound does this seems to be
            let score = calculatePerfectOvertonesScore(frequency: closest[0].frequency, fft: fft)

            return (frequency: closest[0].frequency, score: score, magnitude: closest[0].magnitude)
        }
        
        return peakFundamentalFreqsScore
    }

    static func calculatePerfectOvertonesScore(frequency: Double, fft: TempiFFT) -> Double {
        let harmonicsMask = calculateHarmonicsMask(fundamentalFrequency: frequency, binCount: fft.magnitudes.count, binWidth: fft.bandwidth)
        var score: Double = 0.0
        for i in 0..<fft.magnitudes.count {
            score += harmonicsMask[i] * fft.magnitudes[i]
        }
        return score
    }
    
    //calculates a matrix that describes (from -1 to 1) in which parts of the spectrum it is expected to detect a peak for a specified fundamental frequency
    static func calculateHarmonicsMask(fundamentalFrequency: Double, binCount: Int, binWidth: Double) -> [Double] {
        var mask = Array<Double>()
        var freq: Double = 0
        var currentOvertone = fundamentalFrequency
        for _ in 0..<binCount {
            if freq >= currentOvertone + (fundamentalFrequency/2) {
                currentOvertone = currentOvertone + fundamentalFrequency
            }
            mask.append(MathUtils.valuesNearRatio(value1:freq, value2:currentOvertone, zeroDiff:fundamentalFrequency/4))
            freq = freq + binWidth
        }
        //        print(mask)
        return mask
    }
    
    static func calculateHPSSpectrum(spectrum: [Double], harmonics: Int=3) -> [Double] {
        //using Harmonic Product Spectrum (HPS) for now
        //more at https://cnx.org/contents/i5AAkZCP@2/Pitch-Detection-Algorithms
        
        let minIndex = 20
        
        var spectrum0 = Array<Double>(spectrum)
        let maxIndex = spectrum0.count - 1
        var maxHIndex = spectrum0.count / harmonics
        
        if maxHIndex*harmonics > maxIndex {
            maxHIndex = Int(Double(maxIndex/harmonics).rounded())
        }
        
        for j in minIndex...maxHIndex {
            for i in 1...harmonics {
                spectrum0[j] *= spectrum0[j * i]
            }
        }
        
        return spectrum0
    }

}


