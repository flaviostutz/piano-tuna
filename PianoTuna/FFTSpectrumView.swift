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

    var histogramView: HistogramView!
    
    var fft: TempiFFT! {
        didSet {
            prepareSpectrumView(fft)
//            super.setNeedsDisplay()
        }
    }
    
    var zoomMinDB: Float!
    var zoomMaxDB: Float!
    var zoomFromFrequency: Float!
    var zoomToFrequency: Float!
    
    var title: String! {
        didSet {
            self.histogramView.title = title
        }
    }

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.histogramView = HistogramView(frame:frame)
        super.addSubview(self.histogramView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func prepareSpectrumView(_ fft: TempiFFT) {
        let maxDB = self.zoomMaxDB ?? 64.0
        let minDB = self.zoomMinDB ?? -32.0
        let minFreq = self.zoomFromFrequency ?? 0
        let maxFreq = self.zoomToFrequency ?? fft.nyquistFrequency

        if self.zoomFromFrequency != nil || self.zoomToFrequency != nil {
            for i in 0..<fft.numberOfBands {
                if fft.spectrumFreqAtIndex(i) <= minFreq {
                    self.histogramView.minX = i
                } else if fft.spectrumFreqAtIndex(i) >= maxFreq {
                    self.histogramView.maxX = i
                    break
                }
            }
        }

        self.histogramView.minY = 0
        self.histogramView.maxY = maxDB - minDB

        var spectrum = Array<Float>()
        
        for i in 0..<fft.numberOfBands {
            let magnitude = fft.magnitudeAtBand(i)
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
//            print(magnitudeDB)
            spectrum.append(magnitudeDB)
        }
        self.histogramView.backgroundColor = self.backgroundColor
        self.histogramView.data = spectrum
    }

}

