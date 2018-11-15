//
//  ViewController.swift
//  AudioKitDemo
//
//  Created by 田向阳 on 2018/10/17.
//  Copyright © 2018 田向阳. All rights reserved.
//

import UIKit
import AudioKitUI
import AudioKit
import SandboxFileManager

class ViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var tryButton: UIButton!
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var accVolumSlider: UISlider!
    @IBOutlet weak var singVolumSlider: UISlider!
    
    
    var manager = WSSingManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSandBoxFileManager()
        manager.accFilePath = Bundle.main.path(forResource: "qingqu", ofType: "mp3")
        manager.reset()
        
    }
    
    
    @IBAction func reverbAction(_ sender: UIButton) {
        let type = manager.types[sender.tag]
        manager.loadReverb(reverbType: type)
    }
    
    @IBAction func tryListenAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.isSelected ? manager.tryListen(at: 0) : manager.stopTryListen()
    }
    
    @IBAction func recordAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.isSelected ? manager.startRecord() : manager.stopRecord()
    }
    
    @IBAction func pitchSliderAction(_ sender: Any) {
        manager.accPitchShifter = self.pitchSlider.value * 12
    }
    
    @IBAction func accSliderAction(_ sender: Any) {
        manager.accVolume = Double(self.accVolumSlider.value)
    }
    
    @IBAction func singSliderAction(_ sender: Any) {
        manager.singVolume = Double(self.singVolumSlider.value)
    }
    
    @IBAction func resetAction(_ sender: Any) {
        manager.stopRecord()
        manager.stopTryListen()
        try? manager.recorder?.reset()
    }
    
    private func addSandBoxFileManager () {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        tap.numberOfTouchesRequired = 2
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }
    
    @objc private func tapAction() {
        let sandBoxVC = WXXFileListViewController()
        let nav = UINavigationController(rootViewController: sandBoxVC)
        present(nav, animated: true, completion: nil)
    }
}

