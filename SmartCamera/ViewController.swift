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
import Foundation

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
            if (firstObservation.confidence > 0.6){
                print(firstObservation.identifier, firstObservation.confidence)
                let obj_name = firstObservation.identifier
//                if (obj_name.elementsEqual("ping-pong ball")){
                    let string = obj_name
                    let utterance = AVSpeechUtterance(string: string)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    pushNoti(item_name: obj_name)
                    let synth = AVSpeechSynthesizer()
                    synth.speak(utterance)
//                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixel_buffer, options: [:]).perform([request])
    }
}

func pushNoti(item_name: String) {
    let headers = [
        "Content-Type": "application/json",
        "Authorization": "Basic Zml0NDAwMi5pbnRlbGxpZ2VuY2VAZ21haWwuY29tOjIwMThGSVQ0MDAyPw==",
        "Cache-Control": "no-cache",
        "Postman-Token": "529f2661-840b-401c-b6d0-a45ce6face2a"
    ]
    let parameters = [
        "alert": "\(item_name)",
        "data": "please lord give me strength",
        "sound": "default"
        ] as [String : Any]
    
    guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {return}
    
    let request = NSMutableURLRequest(url: NSURL(string: "https://hcpms-p2000319942trial.hanatrial.ondemand.com/restnotification/application/com.sap.iot.manager/")! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData as Data
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
        if (error != nil) {
            print(error)
        } else {
            let httpResponse = response as? HTTPURLResponse
            print(httpResponse)
        }
    })
    
    dataTask.resume()
}



