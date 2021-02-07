//
//  StationHelper.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2020/5/3.
//  Copyright © 2020 Yang Tun-Kai. All rights reserved.
//

import Foundation


final class StationHelper {
    
    static var shared : StationHelper {
        struct Static {
            static let instance : StationHelper = StationHelper()
        }
        
        return Static.instance
    }
    
    private init() {
        self.checkDocument()
    }
    
    var stations: [Station] = []
    
    private func checkDocument() {
        //if there is not json file in document, copy it from bundle to document
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let versionPath = doc.appendingPathComponent("version.json").path
            let infoPath = doc.appendingPathComponent("citybike.json").path

            if !FileManager.default.fileExists(atPath: versionPath) {
                do{
                    let versionBundlePath = Bundle.main.path(forResource: "version", ofType: "json")
                    try FileManager.default.copyItem(atPath: versionBundlePath!, toPath: versionPath)
                    
                    let infoBundlePath = Bundle.main.path(forResource: "citybike", ofType: "json")
                    try FileManager.default.copyItem(atPath: infoBundlePath!, toPath: infoPath)
                
                }catch{
                    print(error)
                }
            }
            
            self.fetchStationList()
        }
    }
    
    private func fetchStationList() {
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = doc.appendingPathComponent("citybike.json").path
            do {
                let jsonData: Data = try Data(contentsOf: URL(fileURLWithPath: path))
                let json = try JSONDecoder().decode([Station].self, from: jsonData)
                self.stations = json
                
            } catch let DecodingError.dataCorrupted(context) {
                print(context)
                
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
                
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
                
            } catch let DecodingError.typeMismatch(type, context)  {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
                
            } catch {
                print("error: ", error)
                
            }
        }
    }
}
