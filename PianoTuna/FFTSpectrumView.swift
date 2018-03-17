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
        }
    }
    
    var labelsFrequency: [(frequency: Float, text: String)]! {
        didSet {
            prepareSpectrumView(fft)
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
    
    private func prepareSpectrumView(_ fft: TempiFFT!) {
        if(fft == nil) {
            return
        }
        
        let maxDB = self.zoomMaxDB ?? 64.0
        let minDB = self.zoomMinDB ?? -32.0
        let minFreq = self.zoomFromFrequency ?? 0
        let maxFreq = self.zoomToFrequency ?? fft.nyquistFrequency

        var xAxisLabels = Array<String>()
        for i in 0..<fft.magnitudes.count {
            let freq = fft.frequencyAtIndex(i)
            
            //zoom frequency
            if freq <= minFreq {
                self.histogramView.minX = i
            } else if freq >= maxFreq {
                self.histogramView.maxX = i
                break
            }
            
            //x axis labels
            let show = i%(Int((maxFreq-minFreq)/100))==0
            xAxisLabels.append(show ? String(Int(freq)) : "")
        }
        self.histogramView.xAxisLabels = xAxisLabels

        self.histogramView.minY = 0
        self.histogramView.maxY = maxDB - minDB

        var spectrum = Array<Float>()
        
        var viewLabels = Array<String>()
        var labelsCounter = 0

        for i in 0..<fft.magnitudes.count {
            let magnitude = fft.magnitudes[i]
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = FFTUtils.toDB(magnitude)
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            spectrum.append(magnitudeDB)

            //labels match
            if self.labelsFrequency != nil {
                if labelsCounter<self.labelsFrequency.count {
//                    print("labelsCounter \(labelsCounter) c \(self.labelsFrequency.count)")
                    let lf = self.labelsFrequency[labelsCounter]
                    if abs(lf.frequency-fft.frequencyAtIndex(i))<fft.bandwidth {
                        viewLabels.append(lf.text)
                        labelsCounter = labelsCounter + 1
                    } else {
                        viewLabels.append("")
                    }
                }
            }
        }
        self.histogramView.labels = viewLabels

        self.histogramView.barColor = UIColor.green.cgColor
        
        //force background to repaint
        self.histogramView.backgroundColor = self.backgroundColor
        self.histogramView.data = spectrum
    }

}

