//
//  ViewController.swift
//  SmartCamera
//
//  Created by roshan  singh  on 7/9/18.
//  Copyright © 2018 roshan  singh . All rights reserved.
//

import UIKit
import AVKit
import Vision
import AVFoundation
import Foundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var dataFrames: [Array<String>] = []

    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var ScanBtn: UIButton!
    @IBOutlet weak var StopScanBtn: UIButton!

    
    @IBAction func scanBtn(_ sender: UIButton) {
        print("scan button tapped")
        ScanBtn.isHidden = true
        StopScanBtn.isHidden = false
        dataFrames.removeAll()
    }
    
    @IBAction func stopScan(_ sender: Any) {
        print(StopScanBtn.isHidden)
        StopScanBtn.isHidden = true
        ScanBtn.isHidden = false
        if (!dataFrames.isEmpty){
            pushNoti(alert:"Detected Object", data_frames: "\(dataFrames[0][0])")
            pushDB(timestamp: String(Int(NSDate().timeIntervalSince1970.rounded())),
                   data_frames: "\(dataFrames[0][0]),\(dataFrames[0][1])")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        StopScanBtn.isHidden = true
        
        //here is where we init camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        
        //use this input statement to grab camera/audio module
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // displays camera output
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.bringSubviewToFront(buttonContainer)

        
        let data_output = AVCaptureVideoDataOutput()
        data_output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_queue"))
        captureSession.addOutput(data_output)
    }
    
    /**
     This function iterates through every frame and checks if a object element 'vegetation'
     exists and adds dataframes to a queue when the confidence level is above the threshold value.
     **/
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(dataFrames)
        guard let pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Vegetation().model) else {return}
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            if (firstObservation.confidence > 0.8){
                print(firstObservation.identifier, firstObservation.confidence)

                let obj_name = firstObservation.identifier
                if (obj_name.elementsEqual("vegetation") && self.ScanBtn.isHidden){
                    let string = obj_name
                    let utterance = AVSpeechUtterance(string: string)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    let synth = AVSpeechSynthesizer()
                    synth.speak(utterance)
                    
                    self.dataFrames.append([obj_name.uppercased(),"\(firstObservation.confidence)"])
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixel_buffer, options: [:]).perform([request])
    }
}
