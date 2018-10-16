//
//  pushNotificationService.swift
//  SmartCamera
//
//  Created by roshan  singh  on 16/10/18.
//  Copyright © 2018 roshan  singh . All rights reserved.
//

import Foundation

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
