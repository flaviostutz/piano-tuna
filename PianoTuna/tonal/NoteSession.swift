//
//  NoteSession.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/19/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

enum NoteSessionPhase {
    case release
    case backgroundNoise
    case attack
    case decay
}

extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    func diff(_ otherTime: Date) -> Int64 {
        return self.toMillis() - otherTime.toMillis()
    }
}

class NoteSession {

    let zoomCents: Double = 100
    var zoomFrequencyFrom: Double!
    var zoomFrequencyTo: Double!

    var phase = NoteSessionPhase.release
    var phaseStart = Date()
    
    var backgroundNoise: MovingAverageBins!
    var overallMagnitude = MovingAverage(numberOfSamples:4)
    
    var detectedNote: (name: String, cents: Double, noteFrequency: Double, noteNumber: Int, realFrequency: Double)!
    
    var zoomedSpectrum: MovingAverageBins!
    var zoomedTonalPeaks: [(frequency:Double, magnitude: Double)]!
    
    var fft: TempiFFT!

    func step(fft: TempiFFT) {

        overallMagnitude.addSample(value: fft.sumMagnitudes(lowFreq: 0, highFreq: fft.nyquistFrequency, useDB: false))
        print("Level=\(overallMagnitude.getAverage()) \(fft.sumMagnitudes(lowFreq: 0, highFreq: fft.nyquistFrequency, useDB: false))")

        //wait for calmness
        if phase == NoteSessionPhase.release {
            self.detectedNote = nil
            self.zoomedTonalPeaks = nil
            self.zoomFrequencyFrom = nil
            self.zoomFrequencyTo = nil
            
            if overallMagnitude.getAverage() < 5 {
                startPhase(phase: NoteSessionPhase.backgroundNoise, fft: fft)
                self.backgroundNoise = MovingAverageBins(binCount: fft.spectrum().count, maxSamples: 16)
            }

        //measure background noise
        } else if phase == NoteSessionPhase.backgroundNoise {
            
            //high change detected. may be an attack
            if (abs(overallMagnitude.getLastSample()-overallMagnitude.getAverage()))>5 && timeInPhase()>50 {
                
                let peakFundamentalFreqs = detectBestFundamentalPeaks(fft: fft)

                //hit was caused by a tonal sound
                if peakFundamentalFreqs.count>0 {
                    print("TONAL")
                    startPhase(phase: NoteSessionPhase.attack, fft: fft)
                    
                //hit was caused by an atonal sound
                } else {
                    print("ATONAL")
                    startPhase(phase: NoteSessionPhase.release, fft: fft)
                }
                
            //no. it is still calm
            } else {
                backgroundNoise.addSample(bins: fft.spectrum())
            }
        
        } else if phase == NoteSessionPhase.attack {
            //remove measured background noise
            let backgroundNoiseAvg = self.backgroundNoise.getAverage()
            if backgroundNoiseAvg == nil {
                print("NO BACKGROUND NOISE")
                startPhase(phase: NoteSessionPhase.release, fft: fft)
                
            } else {
//                fft.subtractMagnitude(backgroundNoiseAvg!)
                
                if timeInPhase()>100 {
                    let bestPeaks = detectBestFundamentalPeaks(fft: fft)
                    
                    if bestPeaks.count == 0 {
                        print("NO FUNDAMENTAL DETECTED")
                        startPhase(phase: NoteSessionPhase.release, fft: fft)
                        
                    } else {
                        self.detectedNote = NoteIntervalCalculator.frequencyToNoteEqualTemperament(bestPeaks[0].frequency)
                        print("LOCKING TO \(self.detectedNote)")
                        
                        let diff = NoteIntervalCalculator.frequencyFromCents(baseFrequency: self.detectedNote.realFrequency, cents: self.zoomCents) - self.detectedNote.realFrequency
                        self.zoomFrequencyFrom = max(0, self.detectedNote.noteFrequency - diff)
                        self.zoomFrequencyTo = min(fft.nyquistFrequency, self.detectedNote.noteFrequency + diff)
                        self.zoomedSpectrum = MovingAverageBins(binCount: fft.magnitudes.count, maxSamples: 16)
                        startPhase(phase: NoteSessionPhase.decay, fft: fft)
                    }
                }
            }

        } else if phase == NoteSessionPhase.decay {
            //remove measured background noise
//            fft.subtractMagnitude(self.backgroundNoise.getAverage())
            
            //mask and average current spectrum
            let zoomIndexFrom = fft.magIndexForFreq(self.zoomFrequencyFrom)
            let zoomIndexTo = fft.magIndexForFreq(self.zoomFrequencyTo)
            let spec = fft.maskedSpectrum(fromIndex: zoomIndexFrom, toIndex: zoomIndexTo)
            zoomedSpectrum.addSample(bins: spec)
            
            let zoomedAverage = zoomedSpectrum.getAverage()
//            if zoomedAverage != nil {
//                let sumMag = zoomedAverage?.reduce(0, { (current, element) -> Double in
//                    current + element
//                })
            if overallMagnitude.getAverage()<1.3 {
                print("SIGNAL TOO LOW")
                startPhase(phase: NoteSessionPhase.release, fft: fft)
                    
            } else {
                self.zoomedTonalPeaks = FFTUtils.calculateFrequencyPeaks(spectrum: zoomedAverage!, binWidth: fft.bandwidth)
            }
            
        }
        
        self.fft = fft
    }
    
    private func detectBestFundamentalPeaks(fft: TempiFFT) -> [(frequency: Double, score: Double, magnitude: Double)] {
        //detect which tonal sound we are looking for
        let peakFundamentalFreqs = PitchAnalyser.detectFundamentalFrequencies(fft: fft, harmonics:4, minMagnitude:0.1)
        let peakFundamentalFreqsFiltered = peakFundamentalFreqs.filter { (peak) -> Bool in
            return peak.score > 1
        }
        let peakFundamentalFreqsSorted = peakFundamentalFreqsFiltered.sorted { (peak1, peak2) -> Bool in
            return peak1.score>peak2.score
        }
        return peakFundamentalFreqsSorted
    }
    
    private func startPhase(phase: NoteSessionPhase, fft: TempiFFT) {
        print("PHASE \(phase)")
        self.phase = phase
        self.phaseStart = Date()
    }
    
    private func timeInPhase() -> Int64 {
        return Date().diff(self.phaseStart)
    }
    
}
