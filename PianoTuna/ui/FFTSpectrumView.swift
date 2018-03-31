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
    
    var labelsFrequency: [(text: String, frequency: Double)]! {
        didSet {
            prepareSpectrumView(fft)
        }
    }
    
    var annotations: [(text: String, x: Float, y: Float)]! {
        didSet {
            prepareSpectrumView(fft)
        }
    }

    var annotationsFrequency: [(text: String, frequency: Double, y: Float)]! {
        didSet {
            prepareSpectrumView(fft)
        }
    }

    var zoomMinDB: Double!
    var zoomMaxDB: Double!
    var zoomFromFrequency: Double!
    var zoomToFrequency: Double!
    
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
        if(fft == nil || fft.spectrum() == nil) {
            return
        }
        
        let maxDB = self.zoomMaxDB ?? 64.0
        let minDB = self.zoomMinDB ?? -32.0
        let minFreq = self.zoomFromFrequency ?? 0.0
        let maxFreq = self.zoomToFrequency ?? fft.nyquistFrequency

        
        var xAxisLabels = Array<String>()
        
        let fftSpectrum = fft.spectrum()!
        for i in 0..<fftSpectrum.count {
            let freq = fft.frequencyAtIndex(i)
            
            //zoom frequency
            if freq <= minFreq+fft.bandwidth {
                self.histogramView.minX = i
            } else if freq >= maxFreq-fft.bandwidth {
                self.histogramView.maxX = i
                break
            }
            
            //x axis labels
            let show = i%(Int(ceil((maxFreq-minFreq)/10.0)))==0
            xAxisLabels.append(show ? String(Int(freq)) : "")
        }
        
        self.histogramView.xAxisLabels = xAxisLabels

        self.histogramView.minY = 0
        self.histogramView.maxY = maxDB - minDB

        var spectrum = Array<Double>()
        
        var viewLabels = Array<String>()
        var labelsCounter = 0

        for i in 0..<fftSpectrum.count {
            let magnitude = fftSpectrum[i]
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = MathUtils.toDB(magnitude)
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
        
        //show annotations on specific frequencies
        let viewWidth = Double(self.bounds.size.width)
        var annotationsFromFrequency = Array<(text: String, x: Float, y: Float)>()
        if self.annotationsFrequency != nil {
            for af in self.annotationsFrequency {
                if af.frequency >= minFreq && af.frequency <= maxFreq {
                    let x = (af.frequency-minFreq) * (viewWidth/(maxFreq-minFreq))
                    annotationsFromFrequency.append((text: "^", x: Float(x), y: af.y))
                }
            }
        }
        if self.annotations != nil {
            annotationsFromFrequency.append(contentsOf: self.annotations)
        }
        self.histogramView.annotations = annotationsFromFrequency

        self.histogramView.barColor = UIColor.green.cgColor
        
        //force background to repaint
        self.histogramView.backgroundColor = self.backgroundColor
        self.histogramView.data = spectrum
    }

}

