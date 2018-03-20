//
//  StrechedBandFFT.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class ScaledBandsFFT {

    var fft: TempiFFT!
    
    /// The number of calculated bands (must call calculateLinearBands() or calculateLogarithmicBands() first).
    private(set) var numberOfBands: Int = 0
    
    /// The minimum and maximum frequencies in the calculated band spectrum (must call calculateLinearBands() or calculateLogarithmicBands() first).
    private(set) var bandMinFreq, bandMaxFreq: Double!

    /// After calling calculateLinearBands() or calculateLogarithmicBands(), contains a magnitude for each band.
    private(set) var bandMagnitudes: [Double]!
    
    /// After calling calculateLinearBands() or calculateLogarithmicBands(), contains the average frequency for each band
    private(set) var bandFrequencies: [Double]!

    init(fft: TempiFFT) {
        self.fft = fft
    }

    /// Applies logical banding on top of the spectrum data. The bands are spaced linearly throughout the spectrum.
    func calculateLinearBands(minFrequency: Double, maxFrequency: Double, numberOfBands: Int) {
        assert(fft.hasPerformedFFT, "*** Forward data to FFT first.")

        let actualMaxFrequency = min(fft.nyquistFrequency, maxFrequency)
        
        self.numberOfBands = numberOfBands
        self.bandMagnitudes = [Double](repeating: 0.0, count: numberOfBands)
        self.bandFrequencies = [Double](repeating: 0.0, count: numberOfBands)
        
        let magLowerRange = fft.magIndexForFreq(minFrequency)
        let magUpperRange = fft.magIndexForFreq(actualMaxFrequency)
        let ratio: Double = Double(magUpperRange - magLowerRange) / Double(numberOfBands)
        
        for i in 0..<numberOfBands {
            let magsStartIdx: Int = Int(floor(Double(i) * ratio)) + magLowerRange
            let magsEndIdx: Int = Int(floor(Double(i + 1) * ratio)) + magLowerRange
            var magsAvg: Double
            if magsEndIdx == magsStartIdx {
                // Can happen when numberOfBands < # of magnitudes. No need to average anything.
                magsAvg = fft.magnitudes[magsStartIdx]
            } else {
                magsAvg = fft.fastAverage(fft.magnitudes, magsStartIdx, magsEndIdx)
            }
            self.bandMagnitudes[i] = magsAvg
            self.bandFrequencies[i] = fft.averageFrequencyInRange(magsStartIdx, magsEndIdx)
        }
        
        self.bandMinFreq = self.bandFrequencies[0]
        self.bandMaxFreq = self.bandFrequencies.last
    }

    /// Applies logical banding on top of the spectrum data. The bands are grouped by octave throughout the spectrum. Note that the actual min and max frequencies in the resulting band may be lower/higher than the minFrequency/maxFrequency because the band spectrum <i>includes</i> those frequencies but isn't necessarily bounded by them.
    func calculateLogarithmicBands(minFrequency: Double, maxFrequency: Double, bandsPerOctave: Int) {
        assert(fft.hasPerformedFFT, "*** Forward data to FFT first.")
        
        // The max can't be any higher than the nyquist
        let actualMaxFrequency = min(fft.nyquistFrequency, maxFrequency)
        
        // The min can't be 0 otherwise we'll divide octaves infinitely
        let actualMinFrequency = max(1, minFrequency)
        
        // Define the octave frequencies we'll be working with. Note that in order to always include minFrequency, we'll have to set the lower boundary to the octave just below that frequency.
        var octaveBoundaryFreqs: [Double] = [Double]()
        var curFreq = actualMaxFrequency
        octaveBoundaryFreqs.append(curFreq)
        repeat {
            curFreq /= 2
            octaveBoundaryFreqs.append(curFreq)
        } while curFreq > actualMinFrequency
        
        octaveBoundaryFreqs = octaveBoundaryFreqs.reversed()
        
        self.bandMagnitudes = [Double]()
        self.bandFrequencies = [Double]()
        
        // Break up the spectrum by octave
        for i in 0..<octaveBoundaryFreqs.count - 1 {
            let lowerFreq = octaveBoundaryFreqs[i]
            let upperFreq = octaveBoundaryFreqs[i+1]
            
            let mags = fft.magsInFreqRange(lowerFreq, upperFreq)
            let ratio =  Double(mags.count) / Double(bandsPerOctave)
            
            // Now that we have the magnitudes within this octave, cluster them into bandsPerOctave groups and average each group.
            for j in 0..<bandsPerOctave {
                let startIdx = Int(ratio * Double(j))
                var stopIdx = Int(ratio * Double(j+1)) - 1 // inclusive
                
                stopIdx = max(0, stopIdx)
                
                if stopIdx <= startIdx {
                    self.bandMagnitudes.append(mags[startIdx])
                } else {
                    let avg = fft.fastAverage(mags, startIdx, stopIdx + 1)
                    self.bandMagnitudes.append(avg)
                }
                
                let startMagnitudesIdx = Int(lowerFreq / fft.bandwidth) + startIdx
                let endMagnitudesIdx = startMagnitudesIdx + (stopIdx - startIdx)
                self.bandFrequencies.append(fft.averageFrequencyInRange(startMagnitudesIdx, endMagnitudesIdx))
            }
        }
        
        self.numberOfBands = self.bandMagnitudes.count
        self.bandMinFreq = self.bandFrequencies[0]
        self.bandMaxFreq = self.bandFrequencies.last
    }

    /// Get the magnitude for the specified frequency band.
    /// - Parameter inBand: The frequency band you want a magnitude for.
    func magnitudeAtBand(_ inBand: Int) -> Double {
        assert(bandMagnitudes != nil, "*** Call calculateLinearBands() or calculateLogarithmicBands() first")
        return bandMagnitudes[inBand]
    }

    /// Get the middle frequency of the Nth band.
    /// - Parameter inBand: An index where 0 <= inBand < size / 2.
    /// - Returns: The middle frequency of the provided band.
    func frequencyAtBand(_ inBand: Int) -> Double {
        assert(bandMagnitudes != nil, "*** Call calculateLinearBands() or calculateLogarithmicBands() first")
        return self.bandFrequencies[inBand]
    }

    
}
