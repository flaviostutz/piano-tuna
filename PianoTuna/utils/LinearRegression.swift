//
//  MovingAverage.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class LinearRegression {
    
    var samples: CircularArray<(x: Double, y: Double)>!
    var lastx = 0.0

    //avoid recalculating results that are already known
    var lastResult: (a: Double, b: Double)!
    
    init(numberOfSamples: Int) {
        self.samples = CircularArray<(x: Double, y: Double)>(maxSize: numberOfSamples)
        self.lastResult = nil
    }
    
    func addSample(_ value: (x: Double, y: Double)) {
        self.lastx = value.x
        self.samples.append(value)
        self.lastResult = nil
    }

    //shortcut for addsample with last x being incremented by 1 at every call
    func addSample(y: Double) {
        addSample((x:self.lastx+1.0, y:y))
    }

    /**
     * Performs a regression on samples and returns an array containing the
     * elements "a" and "b" for the form "y = a + bx".
     *
     * @return
     */
    func regress() -> (a: Double, b: Double)! {
        assert(self.samples.count>0, "No sample was added to this calculator yet")
        if self.lastResult == nil {
            var sumx = 0.0
            var sumy = 0.0
            var sumxx = 0.0
            var sumxy = 0.0
            for i in 0..<self.samples.count {
                let x = self.samples[i].x
                let y = self.samples[i].y
                sumx += x
                sumy += y
                sumxx += x*x
                sumxy += x*y
            }
            let sxx = sumxx - (sumx * sumx / Double(self.samples.count))
            let sxy = sumxy - (sumx * sumy / Double(self.samples.count))
            
            if sxx != 0 {
                let b = sxy/sxx
                let a = ((sumy-(b*sumx))/Double(self.samples.count))
                self.lastResult = (a: a, b: b)
            }
        }
        return self.lastResult
    }

    func getLastSample() -> (x: Double, y: Double)! {
        if self.samples != nil {
            return self.samples.first
        } else {
            return nil
        }
    }
    
    func getNumberOfSamples() -> Int {
        return self.samples.count
    }
    
    func calculateBestYValue() -> Double! {
        if (self.samples.count > 0) {
            let r = regress()
            if r != nil {
                return r!.a + r!.b*(self.samples[0].x + ((self.samples[self.samples.count-1].x - self.samples[0].x)/2.0))
            }
        }
        return nil
    }
    
}
