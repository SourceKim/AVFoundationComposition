////  DuplicateSelfViewController.swift
//  AVFoundationComposition
//
//  Created by Su Jinjin on 2020/6/22.
//  Copyright © 2020 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class DuplicateSelfViewController: UIViewController {
    
    /// 源视频路径
    private let url = Bundle.main.url(forResource: "1561122035537077", withExtension: "mp4")!
    
    /// 源视频 asset
    private lazy var originAsset = AVAsset(url: self.url)
    
    /// 导出路径：沙盒/Documents/文件名 （注意此处没有拓展名）
    private let kOutPath = NSHomeDirectory() + "/Documents/duplicatedVideo"
    
    /// AVAsset 导出的类，为了防止在 block 中访问他被释放，全局引用一下
    var exporter: AVAssetExportSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 组合
        if let duplicatedAsset = self.duplicateVideo() {
            print("Export path: \(self.kOutPath)")
            // 2. 导出
            self.save(asset: duplicatedAsset, to: self.kOutPath)
        }
    }
    
    /// 获取组合后的视频
    private func duplicateVideo() -> AVAsset? {
        
        // 先获取源 asset 的视频轨道
        guard let videoTrack = self.originAsset.tracks(withMediaType: .video).first
            else {
                print("No video track for video asset")
                return nil
        }
        
        // 源轨道的播放时长
        let duration = videoTrack.timeRange.duration
        
        // 视频编辑的操作对象 (composition)
        let mComposition = AVMutableComposition()
        
        // 为 composition 增加一条 **可变视频轨道**
        let compositionTrack = mComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionTrack?.preferredTransform = videoTrack.preferredTransform // 注意要统一 Transform，否则会出现结果旋转 90°
        
        // 为可变视频轨道插入内容
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        do {
            // 视频轨道插入到时间为 0，长度是 duration
            try compositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            // 视频轨道插入到时间为 duration，长度是 duration
            try compositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: duration)
        } catch let err {
            print("Composition with error: \(err)")
        }
        
        return mComposition
        
    }
    
    /// 导出 AVAsset
    /// - Parameters:
    ///   - asset: 要导出的资源
    ///   - path: 要导出的路径（注意，无需拓展名）
    private func save(asset: AVAsset, to path: String) {
        
        // 文件类型
        let fileType = AVFileType.mov
        
        // 根据文件类型 fileType 获取文件拓展
        let extPtr = UTTypeCopyPreferredTagWithClass(fileType.rawValue as CFString, kUTTagClassFilenameExtension)
        guard let ext = extPtr?.takeRetainedValue() else {
            print("Wrong extention with file type: (\(fileType.rawValue))")
            return
        }
        
        // 输出的路径
        let url = URL(fileURLWithPath: path).appendingPathExtension(ext as String)
        
        // **先移除原来的文件**
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error {
            print(error)
        }
        
        // 配置 exporter
        exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter!.outputURL = url
        exporter!.outputFileType = fileType
        exporter!.shouldOptimizeForNetworkUse = true
        
        // 执行异步导出
        exporter!.exportAsynchronously {
            
            // 导出状态
            print("Export status: \(self.exporter!.status.rawValue)")
            
            // 具体错误信息
            if let err = self.exporter!.error {
                print("Export failed, err \(err)")
                return
            }
            print("Export successfully")
        }
    }

}
