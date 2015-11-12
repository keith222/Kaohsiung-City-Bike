//
//  BikeParser.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/11/12.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import Foundation

class BikeParser: NSObject,NSXMLParserDelegate {
    
    private var xmlItems:[(staID: String, staName: String, ava: String, unava: String)] = []
    private var currentElement = ""
    private var currentId = "" {
        didSet{
            currentId = currentId.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }

    private var currentName = ""{
        didSet{
            currentName = currentName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }

    private var ava = ""{
        didSet{
            ava = ava.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }

    private var unava = ""{
        didSet{
            unava = unava.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }

    
    private var paraserCompletionHandler:([(staID: String, staName: String, ava: String, unava: String)]->Void)?
    
    func parserXml(xmlUrl:String,completionHandler:([(staID: String, staName: String, ava: String, unava: String)]->Void)?)->Void{
    
        self.paraserCompletionHandler = completionHandler
        let request = NSURLRequest(URL: NSURL(string: xmlUrl)!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request, completionHandler: {(data,response,error)->Void in
            if error != nil{
                print(error?.localizedDescription)
            }
            let parser = NSXMLParser(data: data!)
            parser.delegate = self
            parser.parse()
            
        })
        task.resume()
    }
    
    func parserDidStartDocument(parser: NSXMLParser) {
        xmlItems = []
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        if currentElement == "Station"{
            currentId = ""
            currentName = ""
            ava = ""
            unava = ""
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        switch currentElement{
            case "StationID" :currentId+=string
            case "StationName": currentName += string
            case "StationNums1": ava+=string
            case "StationNums2": unava+=string
            default: break
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Station"{
            let xmlItem = (staID:currentId,staName:currentName,ava:ava,unava:unava)
            xmlItems+=[xmlItem]
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        self.paraserCompletionHandler?(xmlItems)
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print(parseError.localizedDescription)
    }
    
}