//
//  SpectralViewController.swift
//  TempiHarness
//
//  Created by John Scalo on 1/7/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit
import AVFoundation

class SpectralViewController: UIViewController {
    
    var audioInput: TempiAudioInput!
    var fftSpectrumView: FFTSpectrumView!
    var hpsSpectrumView: HistogramView!
    var fftLoader: FFTLoader!
    
    let uiFps = FrequencyMeasure()

    //PARAMETERS
    //best frequency measurements precision: 44100@8192samples (5Hz FFT)
    let fftSampleRate: Double = 44100//piano max frequency is 8kHz
    let fftSize: Int = 2048*4 //2048 7.8125Hz/bin
    
    var drawTimedBoolean = TimedBoolean(time: 1000/10)

    var noteSession = NoteSession()

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.spectralView = SpectralView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/2-60))
//        self.spectralView.backgroundColor = UIColor.black

        //draw spectrum
//        histogramView = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/3))
//        histogramView.backgroundColor = UIColor.black
//        let s = [-20,20,60,40,48,-10]
//        histogramView.data = s.map({ (elem) -> Double in
//            return Double(elem)
//        })
//        histogramView.labels = ["a","b","c","d"]
//        histogramView.minY = -32
//        histogramView.maxY = 64
//        histogramView.title = "Testing this!"
//        histogramView.xAxisLabels = ["100","","","200"]
//        histogramView.annotations = [("test1", 100, 100)]
//        histogramView.annotations = [("test2", 150, 30)]

        
        //draw fft spectrum
        self.fftSpectrumView = FFTSpectrumView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/2-20))
        self.fftSpectrumView.backgroundColor = UIColor.black
        self.fftSpectrumView.title = "Raw spectrum"
//        self.fftSpectrumView.zoomMinDB =
//        self.fftSpectrumView.zoomMaxDB =
//        self.fftSpectrumView.zoomFromFrequency = 0
//        self.fftSpectrumView.zoomToFrequency = 2000
        
        
        //draw hps spectrum
        self.hpsSpectrumView = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/2-20))
        self.hpsSpectrumView.backgroundColor = UIColor.black
        self.hpsSpectrumView.barColor = UIColor.red.cgColor
        self.hpsSpectrumView.minX = 0
//        self.hpsSpectrumView.maxX = 256

        //prepare main vertical layout
        let verticalLayout = VerticalLayoutView(width:view.bounds.width)
        verticalLayout.addSubview(fftSpectrumView)
        verticalLayout.addSubview(hpsSpectrumView)
        self.view.addSubview(verticalLayout)
        
        //initialize sound analysis
//        var circularSamplesBuffer = CircularArray<Double>()
        self.drawTimedBoolean.reset()
        
        self.fftLoader = FFTLoader(sampleRate: self.fftSampleRate, samplesSize: fftSize)
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            let dsamples = samples.map({ (element) -> Double in
                return Double(element)
            })
            let fft = self.fftLoader.addSamples(samples: dsamples)
            if fft != nil {
                self.noteSession.step(fft: fft!)
            }

            if self.drawTimedBoolean.checkTrue() {
                self.updateUI(noteSession: self.noteSession)
            }
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: Float(fftSampleRate), numberOfChannels: 1)
        audioInput.startRecording()
    }

    func updateUI(noteSession: NoteSession) {
        
        DispatchQueue.main.async {
            self.uiFps.tick()
            var labelFrequencies = Array<(text: String, frequency: Double, y: Float)>()
            var annotations = Array<(text: String, x: Float, y: Float)>()
            annotations.append((text: "Phase \(noteSession.phase)", x: 100, y: 10))
            annotations.append((text: "UI \(Int(self.uiFps.getFrequency()))Hz   FFT \(Int(self.fftLoader.forwardFrequency.getFrequency()))Hz", x: 400, y: 25))
            if noteSession.overallMagnitude.getAverage() != nil {
                annotations.append((text: "Level \(String(format:"%.3f",noteSession.overallMagnitude.getAverage()))", x: 100, y: 25))
            }
            if noteSession.detectedNote != nil {
                annotations.append((text: "Fundamental \(noteSession.detectedNote.name)Hz - [\(noteSession.detectedNote.name) \(noteSession.detectedNote.noteNumber) \(noteSession.detectedNote.noteFrequency)Hz]", x: 100, y: 40))
            }
            if noteSession.zoomedTonalPeaks != nil {
                annotations.append((text: "Current frequencies \(noteSession.zoomedTonalPeaks)", x: 100, y: 55))
                var c = 0
                for peak in noteSession.zoomedTonalPeaks {
                    labelFrequencies.append((frequency: peak.frequency, text: "^", y: 20))
                    let note = NoteIntervalCalculator.frequencyToNoteEqualTemperament(peak.frequency)
                    annotations.append((text: "\(note.name) \(noteSession.detectedNote.noteNumber) \(String(format:"%.2f",note.cents))c \(String(format:"%.2f",peak.frequency))Hz (\(noteSession.detectedNote.noteFrequency))Hz", x: 100, y: 70 + Float(c)))
                    c = c + 15
                    if c>30 {
                        break
                    }
                }
            }
            self.fftSpectrumView.annotations = annotations
            self.fftSpectrumView.annotationsFrequency = labelFrequencies
            
            //        print("zoomFrequencyFrom \(noteSession.zoomFrequencyFrom) zoomFrequencyTo \(noteSession.zoomFrequencyTo)")
            
            self.fftSpectrumView.zoomFromFrequency = noteSession.zoomFrequencyFrom
            self.fftSpectrumView.zoomToFrequency = noteSession.zoomFrequencyTo
            
            //        self.hpsSpectrumView.annotations = []
            //        if peakFundamentalFreqsSorted.count>0 {
            //            let peak = peakFundamentalFreqsSorted[0]
            //            let note = NoteIntervalCalculator.frequencyToNoteEqualTemperament(peak.frequency)
            //            print("detection=\(note.name) \(String(format: "%.1f", note.cents))¢ \(peak.frequency)Hz")
            //            self.hpsSpectrumView.annotations.append((text:"\(note.name) \(String(format: "%.1f", note.cents))¢", x:100, y:100))
            //
            //            let harmonics = Inharmonicity.calculateInharmonicity(fft: fft, fundamentalFrequency: peak.frequency)
            //            for i in 0..<harmonics.count {
            //                let harm = harmonics[i]
            //                self.hpsSpectrumView.annotations.append((text:"\(harm.number): \(harm.idealFrequency) (\(harm.measuredFrequency)) \(String(format:"%.2f", harm.inharmonicityIndex*100))%", x: 300, y: Double(20+(i*20))))
            //            }
            //        }
            
            var bgbins: [Double]!
            if noteSession.backgroundNoise != nil {
                bgbins = noteSession.backgroundNoise.getResult()
            }
            
            bgbins = FFTUtils.gaussianWindow(windowSize: 100, sigma: 6)

            self.fftSpectrumView.fft = noteSession.fft
            self.hpsSpectrumView.data = bgbins
        }
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

