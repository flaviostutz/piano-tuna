//
//  TimedBoolean.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/20/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

class TimedBoolean {
    
    var enabled: Bool = true;
    var time: UInt64!
    var expirationTime: UInt64!
    var testedAfterTimeout: Bool!
    
    init(time: UInt64, enabled: Bool = true) {
        self.time = time
        self.enabled = enabled
        self.expirationTime = UInt64.max
    }
    
    func reset() {
        self.expirationTime = UInt64(Date().timeIntervalSince1970*1000) + self.time
        testedAfterTimeout = false
    }
    
    func forceTimeout() {
        self.expirationTime = UInt64(Date().timeIntervalSince1970*1000)
    }
    
    func isTimedOut() -> Bool {
        if(self.enabled) {
            if (UInt64(Date().timeIntervalSince1970*1000) > expirationTime) {
                return true
            }
        }
        return false
    }
    
    func checkTrue() -> Bool {
        if isTimedOut() {
            reset()
            return true
        } else {
            return false
        }
    }
    
    func setTime(time: UInt64) {
        self.time = time
        reset()
    }
    
   func isFirstTestAfterTimeOut() -> Bool {
        if (isTimedOut() && testedAfterTimeout == false) {
            testedAfterTimeout = true
            return true
        }
        return false
    }
    
    func setEnabled(enabled: Bool) {
        self.enabled = enabled
    }
    
}
