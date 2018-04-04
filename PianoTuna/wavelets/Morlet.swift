//
//  MorletWavelet.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/28/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation
import Darwin

class Morlet {

    var sampleRate: Double!
    var s: Double!
    
    //s - number of periods in wavelet
    init(sampleRate: Double, s: Double = 6) {
        self.sampleRate = sampleRate
        self.s = s
    }
    
    //https://github.com/scipy/scipy/blob/master/scipy/signal/wavelets.py
    func filter(frequency: Double) -> [Double] {
        let size = Int(round((self.sampleRate/frequency)*self.s))
        //f = 2*s*w*r / M`` where `r` sampling rate; s Scaling factor, windowed from ``-s*2*pi`` to ``+s*2*pi``. Default is 1; w Omega0. Default is 5; M Length of the wavelet
        let w = 2.0 * Double.pi * frequency
        let gaussianWindow = MathUtils.gaussianWindow(windowSize: size, sigma: 6.0)
//        let gaussianWindow = Array<Double>(repeating: 1.0, count: size)
        var filter = Array<Double>(repeating: 0.0, count: size)
        let sh = size/2
        for i in 0..<sh {
            let t = Double(i)/sampleRate
            var v1 = gaussianWindow[sh+i]
            v1 = v1 * pow(Double.pi,-0.25)
            let real = v1 * cos(w*Double(t))
//            let imag = v1 * sin(w*Double(t))
            filter[sh+i] = real
            filter[sh-i] = filter[sh+i]
        }
        return filter
    }
    
    func convolve(signal: [Double], frequency: Double) -> [Double] {
        //based on https://github.com/aoak/wavelets/blob/master/src/aoak/projects/hobby/dsp/transforms/wavelet/WaveletTransform.java

        let filter = self.filter(frequency: frequency)
        
        //        if N == 1 {
        //            return signal
        //        }
        
        //        if (N+K-1) % 2 != 0 {
        //            filter = ArrayUtils.pad(filter, 1, 0);
        //            K = filter.length;
        //        }
        
        var result = Array<Double>(repeating: 0.0, count: signal.count+filter.count-1)
        
        //convolve
        for n in 0..<result.count {
            for k in max(0, n-signal.count+1)...min(n, filter.count-1) {
                result[n] = result[n] + (signal[n-k] * filter[k])
            }
        }
        return result
    }
    
}
