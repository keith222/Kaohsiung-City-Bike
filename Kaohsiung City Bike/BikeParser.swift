//
//  BikeParser.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/11/12.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import UIKit

class BikeParser: NSObject, XMLParserDelegate, URLSessionDataDelegate,UIAlertViewDelegate{

    fileprivate var xmlItems:[(staID: String, staName: String, ava: String, unava: String)] = []
    fileprivate var currentElement = ""
    fileprivate var currentId = "" {
        didSet{
            currentId = currentId.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    fileprivate var currentName = ""{
        didSet{
            currentName = currentName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    fileprivate var ava = ""{
        didSet{
            ava = ava.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    fileprivate var unava = ""{
        didSet{
            unava = unava.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    
    fileprivate var paraserCompletionHandler:(([(staID: String, staName: String, ava: String, unava: String)])->Void)?
    
    func parserXml(_ xmlUrl:String,completionHandler:(([(staID: String, staName: String, ava: String, unava: String)])->Void)?)->Void{
    
        self.paraserCompletionHandler = completionHandler
        let request = URLRequest(url: URL(string: xmlUrl)!)
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 30
        urlConfig.timeoutIntervalForResource = 60
        let urlSession = URLSession(configuration: urlConfig, delegate: self, delegateQueue: nil)
        
        let task = urlSession.dataTask(with: request, completionHandler: {(data,response,error)->Void in
            if error != nil{
                print(error?.localizedDescription)
                if (error?._code == NSURLErrorTimedOut){
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "timeOut"),object: self, userInfo: ["message":(error?.localizedDescription)!])
                }
            }else{
                let parser = XMLParser(data: data!)
                parser.delegate = self
                parser.parse()
            }            
        })
        task.resume()
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        xmlItems = []
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        if currentElement == "Station"{
            currentId = ""
            currentName = ""
            ava = ""
            unava = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement{
            case "StationID" :currentId+=string
            case "StationName": currentName += string
            case "StationNums1": ava+=string
            case "StationNums2": unava+=string
            default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Station"{
            let xmlItem = (staID:currentId,staName:currentName,ava:ava,unava:unava)
            xmlItems+=[xmlItem]
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        self.paraserCompletionHandler?(xmlItems)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError.localizedDescription)
    }
    
}
