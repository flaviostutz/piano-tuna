//
//  File.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/18/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation
import Darwin

class NoteIntervalCalculator {

    static func frequencyToNoteEqualTemperament(_ frequency: Double, referenceFrequency: Double = 440) -> (name: String, cents: Double, noteNumber: Int, noteFrequency: Double, realFrequency: Double) {
        // ceil to 128db in order to avoid log10'ing 0
        let freq = max(0.000000000001, frequency)
        let lnote = (log(freq) - log(referenceFrequency))/log(2) + 4.0
        var oct = floor(lnote)
        var cents = 1200.0 * (lnote - oct)
        var note = ""
        var noteNumber = 1
        
        let note_table = "A A#B C C#D D#E F F#G G#"
        
        var offset = Double(50.0)
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
                    cents = cents - Double(j * 100)
                    noteNumber = j+1
                    break
                }
                offset += 100
                x += 2
            }
        }
        noteNumber = noteNumber + (12*Int(oct))
//        print("NOTE \(noteNumber) \(oct)")
        let noteFrequency = frequencyForNoteEqualTemperament(noteNumber: noteNumber)
        return ( name: "\(note)\(Int(oct))".replacingOccurrences(of: " ", with: ""), cents: cents, noteFrequency: noteFrequency, noteNumber: noteNumber, realFrequency: freq )
    }
    
    private static func charAt(_ str:String, _ i:Int) -> Character {
        return str[str.index(str.startIndex, offsetBy: i)]
    }
    
    static func frequencyFromCents(baseFrequency: Double, cents: Double) -> Double {
        return baseFrequency * pow((pow(2.0,1.0/1200.0)), cents)
    }
    
    static func frequencyForNoteEqualTemperament(noteNumber: Int, referenceFrequency: Double = 440) -> Double {
        return referenceFrequency * pow((pow(2.0, 1.0/12.0)), Double(noteNumber-49))
    }
    
}
