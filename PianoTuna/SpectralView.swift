//
//  SpectralView.swift
//  TempiHarness
//
//  Created by John Scalo on 1/20/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit

class SpectralView: UIView {

    var fft: TempiFFT!

    override func draw(_ rect: CGRect) {
        
        if fft == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        self.drawSpectrum(context: context!)

        self.drawPeaks(context: context!)

        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        self.drawLabels(context: context!)
    }

    private func drawPeaks(context: CGContext) {
        let fontSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightRegular)
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight)

        var fftPitchAnalyser = FFTPitchAnalyser(self.fft)
        var peakFreqs = fftPitchAnalyser.detectFrequencyPeaks(minMagnitude:0.2)
        
        print(peakFreqs)
        
        let labelStrings: [String] = peakFreqs.map { (freq) -> String in
            return String(freq)
        }
        let labelValues: [CGFloat] = peakFreqs.map { (freq) -> CGFloat in
            return CGFloat(freq)
        }
        
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            var attrStr = NSMutableAttributedString(string: str)

            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, str.characters.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, str.characters.count))
            
            var x: CGFloat = freq / samplesPerPixel - fontSize / 2.0
            attrStr.draw(at: CGPoint(x: x, y: -200))
        }
        
        context.restoreGState()
    }
    
    private func drawSpectrum(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        let plotYStart: CGFloat = 48.0
        
        context.saveGState()
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -viewHeight)
        
        let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.red.cgColor]
        let gradient = CGGradient(
            colorsSpace: nil, // generic color space
            colors: colors as CFArray,
            locations: [0.0, 0.3, 0.6])
        
        var x: CGFloat = 0.0
        
        let count = fft.numberOfBands
        
        // Draw the spectrum.
        let maxDB: Float = 64.0
        let minDB: Float = -32.0
        let headroom = maxDB - minDB
//        let colWidth = CGFloat(0.1)
//        print("viewWidth=\(viewWidth) numberOfBands=\(count)")
        let colWidth = tempi_round_device_scale(d: viewWidth / CGFloat(count))
//        print("colWidth=\(colWidth)")
        
        for i in 0..<count {
            let magnitude = fft.magnitudeAtBand(i)
//            print("draw bar \(i)")
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            
            let dbRatio = min(1.0, magnitudeDB / headroom)
            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
            
            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
            
            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
            
            context.saveGState()
            context.clip(to: colRect)
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context.restoreGState()
            
            x += colWidth
        }
        
        context.restoreGState()
    }
    
    private func drawLabels(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        
        let pointSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: pointSize, weight: UIFontWeightRegular)
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth

        let maxFFT = "Max FFT freq=\(fft.nyquistFrequency)Hz"
        var attrStr1 = NSMutableAttributedString(string: maxFFT)
        attrStr1.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, maxFFT.characters.count))
        attrStr1.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, maxFFT.characters.count))
        var x1: CGFloat = viewWidth / 2.0 - attrStr1.size().width / 2.0
        attrStr1.draw(at: CGPoint(x: x1, y: -300))

        
        let freqLabelStr = "Frequency (kHz)"
        var attrStr = NSMutableAttributedString(string: freqLabelStr)
        attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, freqLabelStr.characters.count))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, freqLabelStr.characters.count))
        var x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        attrStr.draw(at: CGPoint(x: x, y: -22))


        let labelStrings: [String] = ["5", "10", "15", "20"]
        let labelValues: [CGFloat] = [5000, 10000, 15000, 20000]
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, str.characters.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, str.characters.count))
            
            x = freq / samplesPerPixel - pointSize / 2.0
            attrStr.draw(at: CGPoint(x: x, y: -40))
        }
        
        context.restoreGState()
    }
}
