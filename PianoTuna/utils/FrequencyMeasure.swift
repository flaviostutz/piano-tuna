//
//  FrequencyMeasure.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/22/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class FrequencyMeasure {
    
    private var lastTickPeriod: Double!
    private var lastTickDate: Date!
    
    func tick() {
        if self.lastTickDate != nil {
            self.lastTickPeriod = -self.lastTickDate.timeIntervalSinceNow
        }
        self.lastTickDate = Date()
    }
    
    func getFrequency() -> Double {
        if self.lastTickPeriod == nil {
            return 0
        } else {
            return 1/self.lastTickPeriod
        }
    }
    
}
