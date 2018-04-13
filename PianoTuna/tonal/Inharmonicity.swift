//
//  Inharmonicity.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class Inharmonicity {

    static func calculateInharmonicity(fft: TempiFFT, fundamentalFrequency: Double, minMagnitude: Double = 0.1) -> [(number:Int, idealFrequency:Double, measuredFrequency:Double, magnitude:Double, inharmonicityIndex:Double)] {
        var harmonics = Array<(number:Int, idealFrequency:Double, measuredFrequency:Double, magnitude:Double, inharmonicityIndex:Double)>()
        let maxHarmonics = Int(round(fft.nyquistFrequency/fundamentalFrequency))
        let spectrum = fft.spectrum()
        if spectrum != nil {
            for i in 1...maxHarmonics {
                let idealFrequency = Double(i) * fundamentalFrequency
                let peaks = MathUtils.calculateFrequencyPeaks(spectrum: spectrum!, binWidth: fft.bandwidth, minMagnitude: minMagnitude, fromFrequency: idealFrequency*0.9, toFrequency: idealFrequency*1.1)
                if peaks.count==0 {
                    harmonics.append((number:i, idealFrequency:idealFrequency, measuredFrequency:0, magnitude:0, inharmonicityIndex:0))
                } else {
                    let inharmonicityIndex = peaks[0].frequency/idealFrequency - 1.0
                    harmonics.append((number:i, idealFrequency:idealFrequency, measuredFrequency:peaks[0].frequency, magnitude:peaks[0].magnitude, inharmonicityIndex:inharmonicityIndex))
                    if peaks.count>1 {
//                        print("[WARNING] found more than one peak in inharmonicity analysis for a single overtone")
//                        print(peaks)
                    }
                }
            }
        }
        return harmonics
    }

}
