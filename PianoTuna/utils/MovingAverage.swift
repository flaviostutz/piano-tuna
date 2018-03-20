//
//  MovingAverage.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class MovingAverage {
    
    var samples: CircularArray<Double>!

    //avoid recalculating results that are already known
    var lastResultValid: Bool = false
    var lastResult: Double!
    
    init(numberOfSamples: Int) {
        self.samples = CircularArray<Double>(maxSize: numberOfSamples)
        self.lastResultValid = false
    }
    
    func addSample(value: Double) {
        self.samples.append(value)
        self.lastResultValid = false
    }
    
    func getAverage() -> Double! {
        if self.samples.count==0 {
            return nil
        } else if !self.lastResultValid {
            let sum = self.samples.reduce(0.0) { (accumulation: Double, nextValue: Double) -> Double in
                return accumulation + nextValue
            }
            self.lastResult = sum/Double(self.samples.count)
            self.lastResultValid = true
        }
        return self.lastResult
    }
    
    func getLastSample() -> Double! {
        if self.samples != nil {
            return self.samples.first
        } else {
            return nil
        }
    }
    
    func getNumberOfSamples() -> Int {
        return self.samples.count
    }
    
}
