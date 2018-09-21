//
//  StationTableViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/3/26.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//
import Foundation
import UIKit

protocol SelectStation {
    func didSelect(_ stationID: String)
}

class StationViewController: SearchViewController{
    
    @IBOutlet weak var stationTableView: UITableView!
    
    private let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    private var tableHelper: TableViewHelper?
    private var source: [StationViewModel]?
    private var filteredSource: [StationViewModel]?
    
    var mDelegate: SelectStation?

    lazy var stationViewModel = {
        return StationViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUp()
        
        self.stationViewModel.fetchStationList(handler: { [weak self] stations in
            self?.source = stations.map{ value -> StationViewModel in
                return StationViewModel(data: value)
            }
            
            //re-arrange station list
            if let favoriteList = self?.userDefault.array(forKey: "staForTodayWidget") {
                for (index, element) in (self?.source?.enumerated())! {
                    if favoriteList.contains(where: { ($0 as! String) == element.no }) {
                        let tempElement = self?.source?.remove(at: index)
                        self?.source?.insert(tempElement!, at: 0)
                    }
                }
            }
            
            self?.tableHelper = TableViewHelper(
                tableView: self!.stationTableView,
                nibName: "StationCell",
                source: self!.source!,
                selectAction: { num in
                    let selectedNO = (self?.searchController.isActive)! ? self?.filteredSource?[num].no : self?.source?[num].no
                    
                    guard let selectedNo = selectedNO else { return }
                    self?.mDelegate?.didSelect(selectedNo)
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            )
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        print("==========")
        print("StationViewController deinit")
        print("==========")
    }

    private func setUp() {
        self.title = NSLocalizedString("Station_List", comment: "")

        //set tableview cell self-sizing
        self.stationTableView.estimatedRowHeight = 70.0
        self.stationTableView.rowHeight = UITableView.automaticDimension
        
        //no title back button
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func filterContentForSearchText(_ searchText: String) {
        //搜尋結果
        if !searchText.isEmpty {
            self.filteredSource = source?.filter({ value in
                return (value.name.contains(searchText)) || (value.address.contains(searchText)) || (value.englishname.contains(searchText.lowercased()))
            })
            
            self.tableHelper?.reloadData = self.filteredSource!
            
        } else {
            self.tableHelper?.reloadData = source!
        }
    }
}
