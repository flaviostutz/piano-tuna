//
//  dataView.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/16/18.
//  Copyright © 2018 John Scalo. All rights reserved.
//

import Foundation
import UIKit

//This view shows a data graph along with labels and custom geometries along both axis
class HistogramView: UIView {

    var data: [Double]! {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var minY: Double!
    var maxY: Double!
    var minX: Int!
    var maxX: Int!
    var barColor: CGColor!

    var labels: [String]!
    var labelFontSize: Float = 11.0 {
        didSet {
            prepareFonts()
        }
    }
    var labelFont: UIFont!
    
    var annotations: [(text:String,x:Float,y:Float)]!
    var annotationsFontSize: Float = 11.0 {
        didSet {
            prepareFonts()
        }
    }
    var annotationsFont: UIFont!
    
    var title: String!
    var titleFontSize: Float = 14.0 {
        didSet {
            prepareFonts()
        }
    }
    var titleFont: UIFont!
    
    var xAxisLabels: [String]!
    var xAxisLabelsFontSize: Float = 10.0 {
        didSet {
            prepareFonts()
        }
    }
    var xAxisLabelsFont: UIFont!

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareFonts()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func prepareFonts() {
        labelFont = UIFont.systemFont(ofSize: CGFloat(labelFontSize), weight: UIFont.Weight.regular)
        titleFont = UIFont.systemFont(ofSize: CGFloat(titleFontSize), weight: UIFont.Weight.regular)
        xAxisLabelsFont = UIFont.systemFont(ofSize: CGFloat(xAxisLabelsFontSize), weight: UIFont.Weight.regular)
        annotationsFont = UIFont.systemFont(ofSize: CGFloat(annotationsFontSize), weight: UIFont.Weight.regular)
    }
    
    override func draw(_ rect: CGRect) {
        if self.data == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()

        if self.data.count > 0 {
            self.drawdata(context: context!)
            self.drawLabels(context: context!)
            self.drawXAxisLabels(context: context!)
            self.drawAnnotations(context: context!)
        }
        self.drawTitle(context: context!)
    }

    private func drawdata(context: CGContext) {
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
//        let scale: CGFloat = UIScreen.main.scale
        let maxXIndex = self.maxX ?? self.data.count - 1
        let minXIndex = self.minX ?? 0
        let colWidth = Float((viewWidth / CGFloat((maxXIndex-minXIndex+1))))

        //y axis
        let minYValue = self.minY ?? self.data.min() ?? 0
        let maxYValue = self.maxY ?? self.data.max() ?? 0
        let negativeMinOffset = CGFloat(minYValue/(maxYValue - minYValue)) * maxColHeight

        //draw bars
        for i in minXIndex...maxXIndex {
            var magnitude = self.data[i]
            magnitude = min(maxYValue, max(magnitude, minYValue))//clip upper and lower ranges
            let ratio = magnitude/(maxYValue - minYValue)
            let magnitudeHeight = CGFloat(ratio) * maxColHeight
            
            let colRect: CGRect = CGRect(x: CGFloat(colWidth*Float(i-minXIndex)), y: plotYStart - negativeMinOffset, width: CGFloat(colWidth), height: magnitudeHeight)
//            print("colRect \(colRect)")

            if self.barColor != nil {
                //paint in plain colors (less cpu usage!)
                context.setFillColor(self.barColor)
                context.addRect(colRect)
                context.drawPath(using: CGPathDrawingMode.fill)
            } else {
                //default to gradient
                let startPoint = CGPoint(x: 0, y: 0)
                let endPoint = CGPoint(x: 0, y: maxColHeight)
                context.saveGState()
                context.clip(to: colRect)
                context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
                context.restoreGState()
            }
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
        attrStr.addAttribute(NSAttributedStringKey.font, value: titleFont, range: NSMakeRange(0, title.count))
        attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, title.count))
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
        let maxXIndex = maxX ?? self.data.count - 1
        let minXIndex = minX ?? 0
        let colWidth = Float((viewWidth / CGFloat((maxXIndex-minXIndex+1)) * scale / scale))
        
        //y axis
        let minYValue = self.minY ?? self.data.min() ?? 0
        let maxYValue = self.maxY ?? self.data.max() ?? 0

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
            attrStr.addAttribute(NSAttributedStringKey.font, value: labelFont, range: NSMakeRange(0, label.count))
            attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, label.count))
            
            let x = CGFloat(colWidth*Float(i) + colWidth/2 - labelFontSize/2)
            let ratio = self.data[i]/(maxYValue - minYValue)
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
        let maxXIndex = maxX ?? self.data.count - 1
        let minXIndex = minX ?? 0
        let colWidth = Float((viewWidth / CGFloat((maxXIndex-minXIndex+1)) * scale / scale))
        
        for i in minXIndex...maxXIndex {
            if xAxisLabels.count<(i+1) {
                return
            }
            let label = xAxisLabels[i]
            if label.count==0 {
                continue
            }
            let attrStr = NSMutableAttributedString(string: label)
            attrStr.addAttribute(NSAttributedStringKey.font, value: xAxisLabelsFont, range: NSMakeRange(0, label.count))
            attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, label.count))
            
            let x = CGFloat(colWidth*Float(i) + colWidth/2 - xAxisLabelsFontSize/2)
            attrStr.draw(at: CGPoint(x: x + CGFloat(xAxisLabelsFontSize*0.5), y: -CGFloat(xAxisLabelsFontSize*1.2)))
        }
        
    }
    

    private func drawAnnotations(context: CGContext) {
        if annotations == nil {
            return
        }
        
        for annotation in annotations {
            let attrStr = NSMutableAttributedString(string: annotation.text)
            attrStr.addAttribute(NSAttributedStringKey.font, value: annotationsFont, range: NSMakeRange(0, annotation.text.count))
            attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, annotation.text.count))
            attrStr.draw(at: CGPoint(x: CGFloat(annotation.x), y: CGFloat(annotation.y)))
        }
        
    }
    
}
