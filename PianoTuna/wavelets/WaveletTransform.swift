//
//  TransformWavelet.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/28/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation
import Darwin

class WaveletOperations {
    
    static func convolve(signal: [Double], filter: [Double]) -> [Double] {
        //based on https://github.com/aoak/wavelets/blob/master/src/aoak/projects/hobby/dsp/transforms/wavelet/WaveletTransform.java
        
        let N = signal.count
        let K = filter.count
        
        if N == 1 {
            return signal
        }
        
//        if (N+K-1) % 2 != 0 {
//            filter = ArrayUtils.pad(filter, 1, 0);
//            K = filter.length;
//        }

        var result = Array<Double>(repeating: 0.0, count: N+K-1)

        //convolve
        for n in 0..<result.count {
            for k in max(0, n-N+1)...min(n, K-1) {
                result[n] = result[n] + (signal[n-k] * filter[k]);
            }
        }
        return result;
    }
    
    static func calculateMagnitudeForFrequency(signal: [Double], sampleRate: Double, frequency: Double) -> Double! {
        let morlet = Morlet(frequency: frequency, sampleRate: sampleRate, size: Int(Double(signal.count)*0.9))
        let convoluted = convolve(signal: signal, filter: morlet.filter())
        return convoluted.max()
    }
    
}
