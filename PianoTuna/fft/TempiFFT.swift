//
//  TempiFFT.swift
//  TempiBeatDetection
//
//  Created by John Scalo on 1/12/16
//  Changed by Flávio Stutz @ 2018
//  Copyright © 2016 John Scalo. See accompanying License.txt for terms.

/*  A functional FFT built atop Apple's Accelerate framework for optimum performance on any device. In addition to simply performing the FFT and providing access to the resulting data, TempiFFT provides the ability to map the FFT spectrum data into logical bands, either linear or logarithmic, for further analysis.

E.g.

let fft = TempiFFT(withSize: frameSize, sampleRate: 44100)

// Setting a window type reduces errors
fft.windowType = TempiFFTWindowType.hanning

// Perform the FFT
fft.fftForward(samples)

// Map FFT data to logical bands. This gives 4 bands per octave across 7 octaves = 28 bands.
fft.calculateLogarithmicBands(minFrequency: 100, maxFrequency: 11025, bandsPerOctave: 4)

// Process some data
for i in 0..<fft.numberOfBands {
let f = fft.frequencyAtBand(i)
let m = fft.magnitudeAtBand(i)
}

Note that TempiFFT expects a mono signal (i.e. numChannels == 1) which is ideal for performance.
*/


import Foundation
import Accelerate

@objc enum TempiFFTWindowType: NSInteger {
    case none
    case hanning
    case hamming
}

@objc class TempiFFT : NSObject {

    var hasPerformedFFT: Bool = false

    /// The length of the sample buffer we'll be analyzing.
    private(set) var size: Int
    
    /// The sample rate provided at init time.
    private(set) var sampleRate: Double
    
    /// The Nyquist frequency is ```sampleRate``` / 2
    var nyquistFrequency: Double {
        get {
            return sampleRate / 2.0
        }
    }
    
    // After performing the FFT, contains size/2 magnitudes, one for each frequency band.
    var magnitudes: [Double]!
    
    /// The average bandwidth throughout the spectrum (nyquist / magnitudes.count)
    var bandwidth: Double {
        get {
            return self.nyquistFrequency / Double(self.magnitudes.count)
        }
    }
    
    /// Supplying a window type (hanning or hamming) smooths the edges of the incoming waveform and reduces output errors from the FFT function (aka "spectral leakage" - ewww).
    var windowType = TempiFFTWindowType.none
    
    private var halfSize:Int
    private var log2Size:Int
    private var window:[Double]!
    private var fftSetup:FFTSetup
    private var complexBuffer: DSPDoubleSplitComplex!
    
    /// Instantiate the FFT.
    /// - Parameter withSize: The length of the sample buffer we'll be analyzing. Must be a power of 2. The resulting ```magnitudes``` are of length ```inSize/2```.
    /// - Parameter sampleRate: Sampling rate of the provided audio data.
    init(withSize inSize:Int, sampleRate inSampleRate: Double) {
        
        let sizeDouble: Double = Double(inSize)
        
        self.sampleRate = inSampleRate
        
        // Check if the size is a power of two
        let lg2 = logb(sizeDouble)
        assert(remainder(sizeDouble, pow(2.0, lg2)) == 0, "size must be a power of 2")
        
        self.size = inSize
        self.halfSize = inSize / 2
        
        // create fft setup
        self.log2Size = Int(log2(sizeDouble))
        self.fftSetup = vDSP_create_fftsetupD(UInt(log2Size), FFTRadix(FFT_RADIX2))!
        
        // Init the complexBuffer
        var real = [Double](repeating: 0.0, count: self.halfSize)
        var imaginary = [Double](repeating: 0.0, count: self.halfSize)
        self.complexBuffer = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)
    }
    
    deinit {
        // destroy the fft setup object
        vDSP_destroy_fftsetupD(fftSetup)
    }
    
    /// Perform a forward FFT on the provided single-channel audio data. When complete, the instance can be queried for information about the analysis or the magnitudes can be accessed directly.
    /// - Parameter inMonoBuffer: Audio data in mono format
    func fftForward(_ inMonoBuffer:[Double]) {
        var analysisBuffer = inMonoBuffer
        
        // If we have a window, apply it now. Since 99.9% of the time the window array will be exactly the same, an optimization would be to create it once and cache it, possibly caching it by size.
        if self.windowType != .none {
            
            if self.window == nil {
                self.window = [Double](repeating: 0.0, count: size)
                
                switch self.windowType {
                case .hamming:
                    vDSP_hamm_windowD(&self.window!, UInt(size), 0)
                case .hanning:
                    vDSP_hann_windowD(&self.window!, UInt(size), Int32(vDSP_HANN_NORM))
                default:
                    break
                }
            }
            
            // Apply the window
            vDSP_vmulD(inMonoBuffer, 1, self.window, 1, &analysisBuffer, 1, UInt(inMonoBuffer.count))
        }
        

        // vDSP_ctoz converts an interleaved vector into a complex split vector. i.e. moves the even indexed samples into frame.buffer.realp and the odd indexed samples into frame.buffer.imagp.
//        var imaginary = [Double](repeating: 0.0, count: analysisBuffer.count)
//        var splitComplex = DSPSplitComplex(realp: &analysisBuffer, imagp: &imaginary)
//        let length = vDSP_Length(self.log2Size)
//        vDSP_fft_zip(self.fftSetup, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))

        // Doing the job of vDSP_ctoz 😒. (See below.)
        var reals = [Double]()
        var imags = [Double]()
        for (idx, element) in analysisBuffer.enumerated() {
            if idx % 2 == 0 {
                reals.append(element)
            } else {
                imags.append(element)
            }
        }
        self.complexBuffer = DSPDoubleSplitComplex(realp: UnsafeMutablePointer(mutating: reals), imagp: UnsafeMutablePointer(mutating: imags))
        
        // This compiles without error but doesn't actually work. It results in garbage values being stored to the complexBuffer's real and imag parts. Why? The above workaround is undoubtedly tons slower so it would be good to get vDSP_ctoz working again.
//        withUnsafePointer(to: &analysisBuffer, { $0.withMemoryRebound(to: DSPComplex.self, capacity: analysisBuffer.count) {
//            vDSP_ctoz($0, 2, &(self.complexBuffer!), 1, UInt(self.halfSize))
//            }
//        })
        // Verifying garbage values.
//        let rDoubles = [Double](UnsafeBufferPointer(start: self.complexBuffer.realp, count: self.halfSize))
//        let iDoubles = [Double](UnsafeBufferPointer(start: self.complexBuffer.imagp, count: self.halfSize))
        
        // Perform a forward FFT
        vDSP_fft_zripD(self.fftSetup, &(self.complexBuffer!), 1, UInt(self.log2Size), Int32(FFT_FORWARD))
        
        // Store and square (for better visualization & conversion to db) the magnitudes
        self.magnitudes = [Double](repeating: 0.0, count: self.halfSize)
        vDSP_zvmagsD(&(self.complexBuffer!), 1, &self.magnitudes!, 1, UInt(self.halfSize))
        
        //show info
        print("bins:\(magnitudes.count) binWidth:\(self.nyquistFrequency/Double(self.magnitudes.count))Hz; maxFrequency:\(self.nyquistFrequency)Hz")
        
        self.hasPerformedFFT = true
    }
    
    func magIndexForFreq(_ freq: Double) -> Int {
        return Int(Double(self.magnitudes.count) * freq / self.nyquistFrequency)
    }
    
    // On arrays of 1024 elements, this is ~35x faster than an iterational algorithm. Thanks Accelerate.framework!
    @inline(__always) func fastAverage(_ array:[Double], _ startIdx: Int, _ stopIdx: Int) -> Double {
        var mean: Double = 0
        let ptr = UnsafePointer<Double>(array)
        vDSP_meanvD(ptr + startIdx, 1, &mean, UInt(stopIdx - startIdx))
        
        return mean
    }
    
    @inline(__always) func magsInFreqRange(_ lowFreq: Double, _ highFreq: Double) -> [Double] {
        let lowIndex = Int(lowFreq / self.bandwidth)
        var highIndex = Int(highFreq / self.bandwidth)
        
        if (lowIndex == highIndex) {
            // Occurs when both params are so small that they both fall into the first index
            highIndex += 1
        }
        
        return Array(self.magnitudes[lowIndex..<highIndex])
    }
    
    @inline(__always) func averageFrequencyInRange(_ startIndex: Int, _ endIndex: Int) -> Double {
        return (self.bandwidth * Double(startIndex) + self.bandwidth * Double(endIndex)) / 2
    }
    
    /// Get the magnitude of the requested frequency in the spectrum.
    /// - Parameter inFrequency: The requested frequency. Must be less than the Nyquist frequency (```sampleRate/2```).
    /// - Returns: A magnitude.
    func magnitudeAtFrequency(_ inFrequency: Double) -> Double {
        assert(hasPerformedFFT, "*** Perform the FFT first.")
        let index = Int(floor(inFrequency / self.bandwidth ))
        return self.magnitudes[min(index, self.magnitudes.count-1)]
    }
    
    /// Calculate the average magnitude of the frequency band bounded by lowFreq and highFreq, inclusive
    func averageMagnitude(lowFreq: Double, highFreq: Double) -> Double {
        var curFreq = lowFreq
        var total: Double = 0
        var count: Int = 0
        while curFreq <= highFreq {
            total += magnitudeAtFrequency(curFreq)
            curFreq += self.bandwidth
            count += 1
        }
        
        return total / Double(count)
    }
    
    /// Sum magnitudes across bands bounded by lowFreq and highFreq, inclusive
    func sumMagnitudes(lowFreq: Double, highFreq: Double, useDB: Bool) -> Double {
        var curFreq = lowFreq
        var total: Double = 0
        while curFreq <= highFreq {
            var mag = magnitudeAtFrequency(curFreq)
            if (useDB) {
                mag = max(0, FFTUtils.toDB(mag))
            }
            total += mag
            curFreq += self.bandwidth
        }
        
        return total
    }
    
    func subtractMagnitude(_ magnitudes:[Double]) {
        assert(magnitudes.count == self.magnitudes.count, "subtract magnitudes must have the same length as fft")
        for i in 0..<self.magnitudes.count {
            self.magnitudes[i] = max(0, (self.magnitudes[i]-magnitudes[i]))
        }
    }
    
    func applyGain(fromIndex: Int, toIndex: Int, gain: Double) {
        assert(toIndex<self.magnitudes.count, "toIndex invalid")
        for i in fromIndex...toIndex {
            self.magnitudes[i] = self.magnitudes[i]*gain
        }
    }
    
    func maskedSpectrum(fromIndex: Int, toIndex: Int) -> [Double] {
        assert(toIndex<self.magnitudes.count, "toIndex invalid")
        var result = Array<Double>()
        for i in 0..<self.magnitudes.count {
            if i>=fromIndex && i<=toIndex {
                result.append(self.magnitudes[i])
            } else {
                result.append(0.0)
            }
        }
        return result
    }
    
    func spectrum() -> [Double] {
        return self.magnitudes
    }
    
    func frequencyAtIndex(_ index:Int) -> Double {
        return self.bandwidth * Double(index) + self.bandwidth/2.0
    }
}
