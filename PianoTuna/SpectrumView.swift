//
//  SpectrumView.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 John Scalo. All rights reserved.
//

import Foundation
import UIKit

//This view shows a spectrum graph along with labels and custom geometries along both axis
class SpectrumView: UIView {

    var spectrum: [Float]! {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var minY: Float!
    var maxY: Float!
    var minX: Int!
    var maxX: Int!

    var labels: [String]!
    var labelFontSize: Float = 11.0
    var labelFont: UIFont!

    var title: String!
    var titleFontSize: Float = 14.0
    var titleFont: UIFont!
    
    var xAxisLabels: [String]!
    var xAxisLabelsFontSize: Float = 10.0
    var xAxisLabelsFont: UIFont!

    override init(frame: CGRect) {
        super.init(frame: frame)
        labelFont = UIFont.systemFont(ofSize: CGFloat(labelFontSize), weight: UIFontWeightRegular)
        titleFont = UIFont.systemFont(ofSize: CGFloat(titleFontSize), weight: UIFontWeightRegular)
        xAxisLabelsFont = UIFont.systemFont(ofSize: CGFloat(xAxisLabelsFontSize), weight: UIFontWeightRegular)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        if self.spectrum == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()

        self.drawTitle(context: context!)
        if self.spectrum.count > 0 {
            self.drawSpectrum(context: context!)
            self.drawLabels(context: context!)
            self.drawXAxisLabels(context: context!)
        }
    }

    private func drawSpectrum(context: CGContext) {
        if spectrum == nil {
            return
        }

        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height

        context.saveGState()
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -viewHeight)
        defer {
            context.restoreGState()
        }

        var plotYStart: CGFloat = 0.0
        var plotYEnd: CGFloat = viewHeight
        if self.title != nil {
            plotYEnd = viewHeight - CGFloat(titleFontSize*1.2)
        }
        if self.xAxisLabels != nil {
            plotYStart = CGFloat(xAxisLabelsFontSize*1.2)
        }
        let maxColHeight = plotYEnd - plotYStart;

        let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.red.cgColor]
        let gradient = CGGradient(
            colorsSpace: nil, // generic color space
            colors: colors as CFArray,
            locations: [0.0, 0.3, 0.6])
        
        //x axis
        let scale: CGFloat = UIScreen.main.scale
        let maxXIndex = maxX ?? spectrum.count - 1
        let minXIndex = minX ?? 0
        let colWidth = Float(round((viewWidth / CGFloat((maxXIndex-minXIndex+1)) * scale) / scale))

        //y axis
        let minYValue = self.minY ?? spectrum.min() ?? 0
        let maxYValue = self.maxY ?? spectrum.max() ?? 0

        let negativeMinOffset = CGFloat(minYValue/(maxYValue - minYValue)) * maxColHeight

        //draw bars
        for i in minXIndex...maxXIndex {
            let magnitude = spectrum[i]
            let ratio = magnitude/(maxYValue - minYValue)
            let magnitudeHeight = CGFloat(ratio) * maxColHeight
//            print("bar magnitude=\(magnitude) ratio=\(ratio) rectH=\(magnitudeHeight)")
            
            let colRect: CGRect = CGRect(x: CGFloat(colWidth*Float(i)), y: plotYStart - negativeMinOffset, width: CGFloat(colWidth), height: magnitudeHeight)
            
            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
            
            context.saveGState()
            context.clip(to: colRect)
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context.restoreGState()
        }
    }
    
    private func drawTitle(context: CGContext) {
        if title == nil {
            return
        }
        
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        defer {
            context.restoreGState()
        }

        //draw title
        let attrStr = NSMutableAttributedString(string: title)
        attrStr.addAttribute(NSFontAttributeName, value: titleFont, range: NSMakeRange(0, title.count))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, title.count))
        let x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        attrStr.draw(at: CGPoint(x: x, y: -(viewHeight - CGFloat(titleFontSize*0.1))))
    }
    
    private func drawLabels(context: CGContext) {
        if labels == nil {
            return
        }
        
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        defer {
            context.restoreGState()
        }

        let scale: CGFloat = UIScreen.main.scale
        
        //x axis
        let maxXIndex = maxX ?? spectrum.count - 1
        let minXIndex = minX ?? 0
        let colWidth = Float(round((viewWidth / CGFloat((maxXIndex-minXIndex+1))) * scale / scale))
        
        //y axis
        let minYValue = self.minY ?? spectrum.min() ?? 0
        let maxYValue = self.maxY ?? spectrum.max() ?? 0

        var plotYStart: CGFloat = 0.0
        var plotYEnd: CGFloat = viewHeight
        if self.title != nil {
            plotYEnd = viewHeight - CGFloat(titleFontSize*1.2)
        }
        if self.xAxisLabels != nil {
            plotYStart = CGFloat(xAxisLabelsFontSize*1.2)
        }
        let maxColHeight = plotYEnd - plotYStart;
        let negativeMinOffset = CGFloat(minYValue/(maxYValue - minYValue)) * maxColHeight

        for i in minXIndex...maxXIndex {
            if labels.count<(i+1) {
                return
            }
            let label = labels[i]
            let attrStr = NSMutableAttributedString(string: label)
            attrStr.addAttribute(NSFontAttributeName, value: labelFont, range: NSMakeRange(0, label.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, label.count))
            
            let x = CGFloat(colWidth*Float(i) + colWidth/2 - labelFontSize/2)
            let ratio = spectrum[i]/(maxYValue - minYValue)
            let labelY = CGFloat(ratio) * maxColHeight + CGFloat(labelFontSize) + 2 + plotYStart
            attrStr.draw(at: CGPoint(x: x, y: -labelY + negativeMinOffset))
        }
    }
    

    private func drawXAxisLabels(context: CGContext) {
        if xAxisLabels == nil {
            return
        }
        
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height

        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        defer {
            context.restoreGState()
        }
        
        let scale: CGFloat = UIScreen.main.scale
        
        //x axis
        let maxXIndex = maxX ?? spectrum.count - 1
        let minXIndex = minX ?? 0
        let colWidth = Float(round((viewWidth / CGFloat((maxXIndex-minXIndex+1))) * scale / scale))
        
        for i in minXIndex...maxXIndex {
            if xAxisLabels.count<(i+1) {
                return
            }
            let label = xAxisLabels[i]
            if label.count==0 {
                continue
            }
            let attrStr = NSMutableAttributedString(string: label)
            attrStr.addAttribute(NSFontAttributeName, value: xAxisLabelsFont, range: NSMakeRange(0, label.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, label.count))
            
            let x = CGFloat(colWidth*Float(i) + colWidth/2 - xAxisLabelsFontSize/2)
//            print("x \(x) label \(label) y \(-CGFloat(xAxisLabelsFontSize*1.2))")
            attrStr.draw(at: CGPoint(x: x, y: -CGFloat(xAxisLabelsFontSize*1.2)))
        }
        
    }
    

    
}
