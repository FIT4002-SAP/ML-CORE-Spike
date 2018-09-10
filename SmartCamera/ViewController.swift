//
//  ViewController.swift
//  SmartCamera
//
//  Created by roshan  singh  on 7/9/18.
//  Copyright © 2018 roshan  singh . All rights reserved.
//

import UIKit
import AVKit //audio visual kit
import Vision
import AVFoundation //textToSpeech

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        let data_output = AVCaptureVideoDataOutput()
        data_output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_queue"))
        captureSession.addOutput(data_output)
        
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("camera was able to capture a frame:", Date())
        
        guard let pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            //check for err
//            print(finishedReq.results)
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            if (firstObservation.confidence > 0.01
                ){
                print(firstObservation.identifier, firstObservation.confidence)
                let obj_name = firstObservation.identifier
//                if (obj_name.elementsEqual("ping-pong ball")){
                    let string = "I think that is a " + obj_name
                    let utterance = AVSpeechUtterance(string: string)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    
                    let synth = AVSpeechSynthesizer()
                    synth.speak(utterance)
//                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixel_buffer, options: [:]).perform([request])
    }


}

