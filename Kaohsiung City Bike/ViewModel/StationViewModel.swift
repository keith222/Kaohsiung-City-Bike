//
//  StationViewModel.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import Alamofire

class StationViewModel {
   
    private var stationCellViewModels: [StationCellViewModel] = [] {
        didSet {
            self.reloadTableViewClosure?(stationCellViewModels)
        }
    }
    
    var numberOfCells: Int {
        return stationCellViewModels.count
    }
    
    var reloadTableViewClosure: (([StationCellViewModel])->())?
    
    init(){}
    
    func initStations() {
        let stations = StationHelper.shared.stations
        self.processFetched(stations)
    }
    
    func getCellViewModels() -> [StationCellViewModel] {
        return self.stationCellViewModels
    }
    
    private func getCellViewModel(with index: Int) -> StationCellViewModel {
        return self.stationCellViewModels[index]
    }
    
    private func processFetched(_ stations: [Station]) {
        var viewModels = [StationCellViewModel]()
        for station in stations {
            viewModels.append(createCellViewModel(with: station))
        }
        self.stationCellViewModels.append(contentsOf: viewModels)
    }
    
    private func createCellViewModel(with station: Station) -> StationCellViewModel {
        return StationCellViewModel(no: station.id, name: station.name, englishname: station.englishname, geohash: station.geohash, address: station.address)
    }
}
