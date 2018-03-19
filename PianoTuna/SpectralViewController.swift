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
//    var spectralView: SpectralView!
//    var histogramView: HistogramView!
    var fftSpectrumView: FFTSpectrumView!
    var hpsSpectrumView: HistogramView!

    //PARAMETERS
    var sampleRate: Float = 16000//piano max frequency is 8kHz
    var circularBufferSize: Int = 2048 //2048 7.8125Hz/bin

    var lastTimeStamp: Double = 0
    var lastTimeStampCircularBuffer: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.spectralView = SpectralView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/2-60))
//        self.spectralView.backgroundColor = UIColor.black

        //draw spectrum
//        histogramView = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/3))
//        histogramView.backgroundColor = UIColor.black
//        let s = [-20,20,60,40,48,-10]
//        histogramView.data = s.map({ (elem) -> Float in
//            return Float(elem)
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
        self.fftSpectrumView.zoomFromFrequency = 0
        self.fftSpectrumView.zoomToFrequency = 2000
        
        
        //draw hps spectrum
        self.hpsSpectrumView = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/2-20))
        self.hpsSpectrumView.backgroundColor = UIColor.black
        self.hpsSpectrumView.barColor = UIColor.red.cgColor
        self.hpsSpectrumView.minX = 0
        self.hpsSpectrumView.maxX = 256

        //prepare main vertical layout
        let verticalLayout = VerticalLayoutView(width:view.bounds.width)
        verticalLayout.addSubview(fftSpectrumView)
        verticalLayout.addSubview(hpsSpectrumView)
        self.view.addSubview(verticalLayout)
        
        //initialize sound analysis
        var circularSamplesBuffer = CircularArray<Float>()
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
//            print("audio frame count=\(numberOfFrames) freq=\(1/(timeStamp-self.lastTimeStamp))Hz (\((timeStamp-self.lastTimeStamp)*1000)ms)")
            self.lastTimeStamp = timeStamp
//            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)

            //expand FFT size with an internal buffer
            for sample in samples {
                circularSamplesBuffer.append(sample)
                //keep buffer with a maximum size
                if circularSamplesBuffer.count>self.circularBufferSize {
                    circularSamplesBuffer.removeFirst()
                }
            }
            let bufferSamples = circularSamplesBuffer.map({ (element) -> Float in
                return element
            })
            
//            if(circularSamplesBuffer.count==self.circularBufferSize) {
            if(circularSamplesBuffer.count==self.circularBufferSize) {
//                print("buffer frame count=\(bufferSamples.count) freq=\(1/(timeStamp-self.lastTimeStampCircularBuffer))Hz (\((timeStamp-self.lastTimeStampCircularBuffer)*1000)ms)")
                self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: circularSamplesBuffer.count, samples: bufferSamples)
                circularSamplesBuffer.removeAll(keepingCapacity:false)
                self.lastTimeStampCircularBuffer = timeStamp
            }
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: sampleRate, numberOfChannels: 1)
        audioInput.startRecording()
    }

    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: sampleRate)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
//        print("fft count=\(fft.magnitudes.count)")
        
        let hpsSpectrum = PitchAnalyser.calculateHPSSpectrum(spectrum: fft.spectrum())
        let peakFundamentalFreqs = PitchAnalyser.detectFundamentalFrequencies(fft: fft, harmonics:4, minMagnitude:0.1)
        
//        let hm = FFTUtils.calculateHarmonicsMask(fundamentalFrequency: 100, binCount: 1000, binWidth: 1)

        let peakFundamentalFreqsFiltered = peakFundamentalFreqs.filter { (peak) -> Bool in
            return peak.score > 1
        }

        let peakFundamentalFreqsSorted = peakFundamentalFreqsFiltered.sorted { (peak1, peak2) -> Bool in
            return peak1.score>peak2.score
        }
//        print(peakFundamentalFreqs)
        
        let labelsFrequency = peakFundamentalFreqsSorted.map { (peak) -> (frequency: Float, text: String) in
            let note = EqualTemperamentCalculator.frequencyToNote(peak.frequency)
            return (frequency: peak.frequency, text: "\(peak.frequency)Hz \(note.name) \(Int(round(note.cents)))¢")
        }

        self.hpsSpectrumView.annotations = []
        if peakFundamentalFreqsSorted.count>0 {
            let peak = peakFundamentalFreqsSorted[0]
            let note = EqualTemperamentCalculator.frequencyToNote(peak.frequency)
            print("detection=\(note.name) \(Int(round(note.cents)))¢ \(peak.frequency)Hz")
            self.hpsSpectrumView.annotations.append((text:"\(note.name) \(Int(round(note.cents)))¢", x:100, y:100))
        }
        if peakFundamentalFreqsSorted.count>1 {
            let peak = peakFundamentalFreqsSorted[1]
            let note = EqualTemperamentCalculator.frequencyToNote(peak.frequency)
            print("detection=\(note.name) \(Int(round(note.cents)))¢ \(peak.frequency)Hz")
            self.hpsSpectrumView.annotations.append((text:"\(note.name) \(Int(round(note.cents)))¢", x:100, y:120))
        }
        if peakFundamentalFreqsSorted.count>2 {
            let peak = peakFundamentalFreqsSorted[2]
            let note = EqualTemperamentCalculator.frequencyToNote(peak.frequency)
            print("detection=\(note.name) \(Int(round(note.cents)))¢ \(peak.frequency)Hz")
            self.hpsSpectrumView.annotations.append((text:"\(note.name) \(Int(round(note.cents)))¢", x:100, y:140))
        }

        tempi_dispatch_main { () -> () in
            self.fftSpectrumView.fft = fft
            self.fftSpectrumView.labelsFrequency = labelsFrequency
            self.hpsSpectrumView.data = hpsSpectrum
        }
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

