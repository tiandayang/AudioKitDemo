//
//  WSSingManager.swift
//  AudioKitDemo
//
//  Created by 田向阳 on 2018/11/15.
//  Copyright © 2018 田向阳. All rights reserved.
//

import UIKit
import AudioKit

class WSSingManager {
    
    enum WSSingManagerMode {
        case none
        case record //录音模式
        case tryListen //试听模式
    }

    
    let types = [
        WSReverbType.none,
        WSReverbType.KTV(dryWetMix: 0.2, decayTimeAt0Hz: 1.8, gain: 12, maxDelayTime: 0.05, randomizeReflections: 1, minDelayTime: 0.008, decayTimeAtNyquist: 12),
        WSReverbType.KTV(dryWetMix: 0.5, decayTimeAt0Hz: 1, gain: 0.5, maxDelayTime: 0.05, randomizeReflections: 1, minDelayTime: 0.008, decayTimeAtNyquist: 0.5),
        WSReverbType.KTV(dryWetMix: 0.5, decayTimeAt0Hz: 3, gain: 0.5, maxDelayTime: 0.05, randomizeReflections: 1, minDelayTime: 0.008, decayTimeAtNyquist: 10)]
    
    var melodyFilePath: String?
    var melodyPlayer: AKPlayer?
    
    var accFilePath: String?
    var accompanyPlayer: AKPlayer?
    var accPitch: AKPitchShifter?

    var singPath: String?
    var singPlayer: AKPlayer?
    var singReverb: AKReverb2?
    
    var totalMixer: AKMixer?
    let mic = AKMicrophone()
    var micMixer: AKMixer?
    var recorder: AKNodeRecorder?
    var recordReverb: AKReverb2?
    
    
    //共有的
     //演唱试听时的声音强度
    var singVolume: Double = 1.0 {
        didSet{
            if mode == .record {
                self.micMixer?.volume = singVolume
            }else{
                self.singPlayer?.volume = singVolume
            }
        }
    }
 
    //伴奏的音量
    var accVolume: Double  = 1.0 {
        didSet{
            self.accompanyPlayer?.volume = accVolume
        }
    }
    //调音
    var accPitchShifter: Double  = 0.0 {
        didSet{
            self.accPitch?.shift = accPitchShifter
        }
    }
    
    //模式改变的话
    var mode = WSSingManagerMode.none {
        didSet{
            switch mode {
            case .record:
                self.micMixer?.volume = self.singVolume
            default:
                self.micMixer?.volume = 0
            }
        }
    }
    
    private var reverbType = WSReverbType.none
    
    //MARK: init-Method
    init() {
        AKSettings.bufferLength = .medium
        
        AKSettings.defaultToSpeaker = true
        micMixer = AKMixer(mic)
        micMixer?.volume = 0
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
            recorder = try AKNodeRecorder(node: micMixer)
            recordReverb = AKReverb2(micMixer) 
        } catch {
            AKLog("Could not set session category.")
        }
        singPath = recorder?.audioFile?.url.path
    }
    
    //MARK: 开始录制
    public func startRecord(at: Double = 0.0){
        guard let `recorder` = recorder, !recorder.isRecording else {return}
        do {
            try recorder.record()
            accompanyPlayer?.setPosition(at)
            accompanyPlayer?.play()
            loadReverb(reverbType: self.reverbType)
            self.mode = .record
        }catch{
            AKLog("录音开启出错：\(error)")
        }
    }
    
    public func stopRecord(){
        guard let `recorder` = recorder, recorder.isRecording else {return}
        recorder.stop()
        accompanyPlayer?.stop()
        self.mode = .none
    }
    
    //MARK: 试听
    public func tryListen(at: Double){
        stopRecord()
        guard let file = recorder?.audioFile else { return }
        singPlayer?.load(audioFile: file)
        accompanyPlayer?.play()
        singPlayer?.play()
        self.mode = .tryListen
    }
    
    public func stopTryListen(){
        accompanyPlayer?.stop()
        singPlayer?.stop()
        self.mode = .none
    }
    
    //MARK: 混响
    public func loadReverb(reverbType: WSReverbType){
        configureReverbWithType(type: reverbType)
    }
    
    private func  configureReverbWithType(type: WSReverbType){
        switch type {
        case .none:
            singReverb?.dryWetMix = 0
            singReverb?.decayTimeAt0Hz = 1
            singReverb?.gain = 0
            singReverb?.maxDelayTime = 0.05
            singReverb?.randomizeReflections = 1
            singReverb?.minDelayTime = 0.008
            singReverb?.decayTimeAtNyquist = 0.5
            
            recordReverb?.decayTimeAt0Hz = 1
            recordReverb?.gain = 0
            recordReverb?.maxDelayTime = 0.05
            recordReverb?.randomizeReflections = 1
            recordReverb?.minDelayTime = 0.008
            recordReverb?.decayTimeAtNyquist = 0.5
            break
        case .KTV(dryWetMix: let dryWetMix, decayTimeAt0Hz: let decayTimeAt0Hz, gain: let gain, maxDelayTime: let maxDelayTime, randomizeReflections: let randomizeReflections, minDelayTime: let minDelayTime ,decayTimeAtNyquist: let decayTimeAtNyquist):
            
            singReverb?.dryWetMix = dryWetMix
            singReverb?.decayTimeAt0Hz = decayTimeAt0Hz
            singReverb?.gain = gain
            singReverb?.maxDelayTime = maxDelayTime
            singReverb?.randomizeReflections = randomizeReflections
            singReverb?.minDelayTime = minDelayTime
            singReverb?.decayTimeAtNyquist = decayTimeAtNyquist
            
            recordReverb?.dryWetMix = dryWetMix
            recordReverb?.decayTimeAt0Hz = decayTimeAt0Hz
            recordReverb?.gain = gain
            recordReverb?.maxDelayTime = maxDelayTime
            recordReverb?.randomizeReflections = randomizeReflections
            recordReverb?.minDelayTime = minDelayTime
            recordReverb?.decayTimeAtNyquist = decayTimeAtNyquist
            
            break
        }
    }
    
    public func reset(){
        guard let aSingPath = singPath, let aAccPath = accFilePath else {return}
        do{
            let accFile = try AKAudioFile(forReading: URL(fileURLWithPath: aAccPath))
            let singFile = try AKAudioFile(forReading: URL(fileURLWithPath: aSingPath))
            accompanyPlayer = AKPlayer(audioFile: accFile)
            accPitch = AKPitchShifter(accompanyPlayer)
            
            singPlayer = AKPlayer(audioFile: singFile)
            singReverb = AKReverb2(singPlayer)
            totalMixer = AKMixer(recordReverb, accPitch, singReverb)
            AudioKit.output = totalMixer
            try AudioKit.start()
            
        }catch{
            AKLog("加载文件出错：\(error)")
        }
        
    }
    
}

enum WSReverbType {
    
    case none
    case KTV(dryWetMix: Double,decayTimeAt0Hz: Double, gain: Double, maxDelayTime: Double,randomizeReflections: Double, minDelayTime: Double, decayTimeAtNyquist: Double)
}
