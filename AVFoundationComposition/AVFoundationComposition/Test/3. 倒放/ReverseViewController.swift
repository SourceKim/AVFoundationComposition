////  ReverseViewController.swift
//  AVFoundationComposition
//
//  Created by Su Jinjin on 2020/6/22.
//  Copyright © 2020 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation

class ReverseViewController: UIViewController {
    
    /// 每段视频最大的帧数
    private let kMaxFramePerSegmentCount = 100
    
    /// 临时存放的 buffer
    private let tmpBuffers = [CMSampleBuffer]()
    
    /// 翻转的 assets
    private var reversedAssets = [AVAsset]()
    
    /// 源视频路径
    private let url = Bundle.main.url(forResource: "1561122035537077", withExtension: "mp4")!
    
    /// 源视频 asset
    private lazy var originAsset = AVAsset(url: self.url)
    
    private lazy var originVideoTrack = self.originAsset.tracks(withMediaType: .video).first!
    
    private var assetReader: AVAssetReader!
    private var readerOutput: AVAssetReaderTrackOutput!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInput: AVAssetWriterInput!
    private var assetWriterInputAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupReader()
        self.setupWriterParams()
        
        self.assetReader.startReading()
        while true {
            let res = self.readBuffers()
            
//            let asset = self.writeAssets(idx: self.reversedAssets.count, with: res.buffers)
//            self.reversedAssets.append(asset!)
            
            if res.reachEnd {
                break
            }
        }
        self.assetReader.cancelReading()
        print("Finish to reverse the videos")
        
    }
    
    private func setupReader() {
        
        do {
            self.assetReader = try AVAssetReader(asset: self.originAsset)
        } catch let err {
            print("Create asset reader with error: \(err)")
            return
        }
        
        let settings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        
        self.readerOutput = AVAssetReaderTrackOutput(track: self.originVideoTrack, outputSettings: settings)
        
        if self.assetReader.canAdd(self.readerOutput) {
            self.assetReader.add(self.readerOutput)
        } else {
            print("Can't add reader track output")
        }
    }
    
    private func setupWriterParams() {
        
        let naturalSize = self.originVideoTrack.naturalSize
        let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                       AVVideoWidthKey: naturalSize.width,
                                       AVVideoHeightKey: naturalSize.height]
        
        self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        
        if (self.assetWriterInput == nil) {
            print("Can't create asset writer input")
        }
        
        self.assetWriterInput.expectsMediaDataInRealTime = true
//        assetWriter!.add(assetWriterInput!)
        self.assetWriterInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
        
        if (self.assetWriterInputAdaptor == nil) {
            print("Can't create asset writer input adaptor")
        }
    }
    
    private func readBuffers() -> (reachEnd: Bool, buffers: [CMSampleBuffer]) {
        var buffers = [CMSampleBuffer]()
        for i in 0..<self.kMaxFramePerSegmentCount {
            if let nextBuffer = self.readerOutput.copyNextSampleBuffer() {
                buffers.append(nextBuffer)
            } else {
                print("cur - \(i)")
                return (true, buffers)
            }
        }
        return (false, buffers)
    }
    
    private let writeSemaphore = DispatchSemaphore(value: 0)
    
    private func writeAssets(idx: Int, with buffers: [CMSampleBuffer]) -> AVAsset? {
        let outpath = NSTemporaryDirectory() + "seg_" + "\(idx)" + ".mov"
        let outUrl = URL(fileURLWithPath: outpath)
        
        print("Temporary asset persistance file path: \(outpath)")
        
        var writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outUrl, fileType: .mov)
        } catch let err {
            print("Create writer with error: (\(err))")
            return nil
        }
        
        guard writer.canAdd(self.assetWriterInput) else {
            print("Failed to add input to writer")
            return nil
        }
        
        writer.add(self.assetWriterInput)
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var time: Int32 = 0
        let scale = self.originVideoTrack.naturalTimeScale
        for buffer in buffers.reversed() {
            
            while !self.assetWriterInput.isReadyForMoreMediaData {
                sleep(1)
            }
            
            self.assetWriterInputAdaptor.append(CMSampleBufferGetImageBuffer(buffer)!, withPresentationTime: CMTime(value: CMTimeValue(time * scale), timescale: scale))
            time += 1
        }
        
        writer.finishWriting {
            print("Finish writing")
            self.writeSemaphore.signal()
        }
        
        self.writeSemaphore.wait()
        print("Return from writing asset")
        
        let asset = AVAsset(url: outUrl)
        return asset
    }
    
    private func combineAssets() {
        
    }
}
