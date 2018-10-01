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
            pushNoti(alert:"Detected Object", data_frames: dataFrames[0])
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

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(dataFrames)
        guard let pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Vegetation().model) else {return}
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            if (firstObservation.confidence > 0.6){
                print(firstObservation.identifier, firstObservation.confidence)

                let obj_name = firstObservation.identifier
                if (obj_name.elementsEqual("vegetation") && self.ScanBtn.isHidden){
                    let string = obj_name
                    let utterance = AVSpeechUtterance(string: string)
                    utterance.voice = AVSpeechSynthesisVoice(language: "ta-IN")
//                    pushNoti(item_name: obj_name)
                    let synth = AVSpeechSynthesizer()
                    synth.speak(utterance)
                    
                    self.dataFrames.append([obj_name,"\(firstObservation.confidence)"])
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixel_buffer, options: [:]).perform([request])
    }
}

//todo: create button :time towerdid and frame data
func pushNoti(alert: String, data_frames: [String]) {
    let headers = [
        "Content-Type": "application/json",
        "Authorization": "Basic Zml0NDAwMi5pbnRlbGxpZ2VuY2VAZ21haWwuY29tOjIwMThGSVQ0MDAyPw==",
        "Cache-Control": "no-cache",
        "Postman-Token": "529f2661-840b-401c-b6d0-a45ce6face2a"
    ]
    let parameters = [
        "alert": "\(alert)",
        "data": "\(data_frames)",
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

func pushDB(timestamp: String, data_frames: String){
    let headers = [
        "Authorization": "Bearer 7153e5144e72f4949ccf777a387c35",
        "Content-Type": "application/json;charset=utf-8",
        "Accept": "*/*",
        "Cache-Control": "no-cache",
        "Postman-Token": "c9d58bcf-0510-47c8-acf0-78816e35fadb"
    ]
    
    let postData = NSData(data: """
    {
        "mode": "sync",
        "messageType": "35970b0909ffb71c3f4f",
        "messages": [
            {
            "timestamp": "\(timestamp)",
            "description": "\(data_frames)",
            "incident_code": "Vegetation"
            }
        ]
    }
    """.data(using: String.Encoding.utf8)!)

    let request = NSMutableURLRequest(url: NSURL(string: "https://iotmmsp2000319942trial.hanatrial.ondemand.com/com.sap.iotservices.mms/v1/api/http/data/80c04384-651e-4420-9ed4-a56f52d0c805")! as URL,
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
