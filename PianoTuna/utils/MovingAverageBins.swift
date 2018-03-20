//
//  MovingAverageBins.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class MovingAverageBins {
    
    var averages: Array<MovingAverage>!
    
    init(binCount: Int, maxSamples: Int) {
        self.averages = Array<MovingAverage>()
        for _ in 0..<binCount {
            self.averages.append(MovingAverage(numberOfSamples: maxSamples))
        }
    }
    
    func addSample(bins: [Double]) {
        assert(bins.count == self.averages.count, "average bins count is different from sample bins count")
        for i in 0..<bins.count {
            self.averages[i].addSample(value: bins[i])
        }
    }
    
    func getAverage() -> [Double]! {
        var result = Array<Double>()
        for average in self.averages {
            if(average.getAverage() == nil) {
                return nil
            } else {
                result.append(average.getAverage())
            }
        }
        return result
    }
    
}
