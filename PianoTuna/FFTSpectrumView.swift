//
//  FFTSpectrumView.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

import UIKit

class FFTSpectrumView: UIView {

    var spectrumView: SpectrumView!
    
    var fft: TempiFFT! {
        didSet {
            prepareSpectrumView(fft)
        }
    }
    
    var title: String! {
        didSet {
            self.spectrumView.title = title
        }
    }

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.spectrumView = SpectrumView(frame:frame)
        super.addSubview(self.spectrumView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func prepareSpectrumView(_ fft: TempiFFT) {
        let maxDB: Float = 64.0
        let minDB: Float = -32.0

        var spectrum = Array<Float>()
        
        for i in 0..<fft.numberOfBands {
            let magnitude = fft.magnitudeAtBand(i)
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            spectrum.append(magnitudeDB)
        }
        
        self.spectrumView.minY = minDB
        self.spectrumView.maxY = maxDB
        
        self.spectrumView.spectrum = spectrum
    }

}

