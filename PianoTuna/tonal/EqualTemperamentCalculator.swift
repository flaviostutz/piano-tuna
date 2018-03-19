//
//  File.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/18/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation
import Darwin

class EqualTemperamentCalculator {

    static func frequencyToNote(_ frequency: Float) -> (name: String, cents: Float) {
        let lnote = (log(frequency) - log(440))/log(2) + 4.0
        var oct = floor(lnote)
        var cents = 1200 * (lnote - oct)
        var note = ""
        
        let note_table = "A A#B C C#D D#E F F#G G#"
        
        var offset = Float(50.0)
        var x = 2
        
        if cents < 50 {
            note = "A "
        } else if (cents >= 1150) {
            note = "A ";
            cents -= 1200;
            oct = oct + 1;
        } else {
            for j in 1...11 {
                if (cents >= offset) && cents < (offset + 100) {
                    note = "\(charAt(note_table, x))\(charAt(note_table, x+1))"
                    cents = cents - Float(j * 100)
                    break
                }
                offset += 100
                x += 2
            }
        }
        return ( name: "\(note)\(Int(oct))".replacingOccurrences(of: " ", with: ""), cents: cents )
    }
    
    private static func charAt(_ str:String, _ i:Int) -> Character {
        return str[str.index(str.startIndex, offsetBy: i)]
    }
    
}
