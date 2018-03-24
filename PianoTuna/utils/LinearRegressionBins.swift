//
//  MovingAverageBins.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class LinearRegressionBins {
    
    var regressions: Array<LinearRegression>!
    var maxSamples: Int!
    
    var lastResult: [Double]!
    
    init(binCount: Int, maxSamples: Int) {
        self.regressions = Array<LinearRegression>()
        self.maxSamples = maxSamples
        for _ in 0..<binCount {
            self.regressions.append(LinearRegression(numberOfSamples: maxSamples))
        }
    }
    
    func addSample(bins: [Double]) {
        assert(bins.count == self.regressions.count, "average bins count is different from sample bins count")
        for i in 0..<bins.count {
            self.regressions[i].addSample(y: bins[i])
        }
        self.lastResult = nil
    }
    
    func getResult() -> [Double]! {
        if self.lastResult == nil {
            self.lastResult = Array<Double>()
            for regression in self.regressions {
                let r = regression.calculateBestYValue()
                if(r == nil) {
                    self.lastResult = nil
                    break
                } else {
                    self.lastResult.append(r!)
                }
            }
        }
        return self.lastResult
    }
    
}
