//
//  FFTAnalyser.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/13/18.
//  Copyright © 2018 John Scalo. All rights reserved.
//

import Foundation

class FFTPitchAnalyser {

    static func detectFundamentalFrequenciesHPS(fft: TempiFFT, harmonics: Int=3, minMagnitude: Float=1) -> [(frequency: Float, magnitude: Float)] {
        let hpsSpectrum = calculateHPSSpectrum(spectrum: fft.spectrum(), harmonics: harmonics)
        let hpsPeaks = FFTUtils.calculateFrequencyPeaks(spectrum: hpsSpectrum, binWidth: fft.bandwidth, minMagnitude: minMagnitude)
        return hpsPeaks
    }

    static func calculateScoreForFundamentalFrequencyCandidate(frequency: Float, fft: TempiFFT) -> Float {
        let harmonicsMask = FFTUtils.calculateHarmonicsMask(fundamentalFrequency: frequency, binCount: fft.magnitudes.count, binWidth: fft.bandwidth)
        var score: Float = 0.0
        for i in 0..<fft.magnitudes.count {
            score += harmonicsMask[i] * fft.magnitudes[i]
        }
        return score
    }
    
    static func calculateHPSSpectrum(spectrum: [Float], harmonics: Int=3) -> [Float] {
        //using Harmonic Product Spectrum (HPS) for now
        //more at https://cnx.org/contents/i5AAkZCP@2/Pitch-Detection-Algorithms
        
        let minIndex = 20
        
        var spectrum0 = Array<Float>(spectrum)
        let maxIndex = spectrum0.count - 1
        var maxHIndex = spectrum0.count / harmonics
        
        if maxHIndex*harmonics > maxIndex {
            maxHIndex = Int(Float(maxIndex/harmonics).rounded())
        }
        
        for j in minIndex...maxHIndex {
            for i in 1...harmonics {
                spectrum0[j] *= spectrum0[j * i]
            }
        }
        
        return spectrum0
    }

}


