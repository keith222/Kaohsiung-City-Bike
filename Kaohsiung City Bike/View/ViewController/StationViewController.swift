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
    func didSelect(_ stationID: Int)
}

class StationViewController: SearchViewController{
    
    @IBOutlet weak var stationTableView: UITableView!
    
    private let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    private var tableHelper: TableViewHelper?
    private var source: [StationCellViewModel]?
    private var filteredSource: [StationCellViewModel]?
    
    var mDelegate: SelectStation?
    
    lazy var stationViewModel = {
        return StationViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUp()
        self.bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    private func bindViewModel() {
        self.stationViewModel.reloadTableViewClosure = { [weak self] source in
            var tempSource = source
            
            //re-arrange station list
            if let favoriteList = self?.userDefault.array(forKey: "staForTodayWidget") {
                for (index, element) in tempSource.enumerated() {
                    if favoriteList.contains(where: { ($0 as! String) == element.no }) {
                        let tempElement = tempSource.remove(at: index)
                        tempSource.insert(tempElement, at: 0)
                    }
                }
            }
            
            self?.tableHelper?.reloadData = tempSource as [AnyObject]
            self?.source = tempSource
        }
        
        self.tableHelper = TableViewHelper(
            tableView: self.stationTableView,
            nibName: "StationCell",
            selectAction: { [weak self] num in
                guard let selectedID = (self?.searchController.isActive)! ? self?.filteredSource?[num].id : self?.source?[num].id else { return }
                
                self?.mDelegate?.didSelect(selectedID)
                self?.navigationController?.popToRootViewController(animated: true)
        })
        
        self.stationViewModel.initStations()
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
                let name = value.name ?? ""
                let address = value.address ?? ""
                let englishName = value.englishname ?? ""
                
                return name.contains(searchText) || address.contains(searchText) || englishName.contains(searchText.lowercased())
            })
            
            self.tableHelper?.reloadData = (self.filteredSource ?? []) as [AnyObject]
            
        } else {
            self.tableHelper?.reloadData = (source ?? []) as [AnyObject]
        }
    }
    
    deinit {
        print("==========")
        print("StationViewController deinit")
        print("==========")
    }
}
