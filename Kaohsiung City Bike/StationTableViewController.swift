//
//  StationTableViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/3/26.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit

class StationTableViewController: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating{

    let staInfo = DataGet().bikeLocationJson()
    var searchButton: UIBarButtonItem!
    var noTitleButton: UIBarButtonItem!
    var searchController: UISearchController!
    var searchResults: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Station_List", comment: "")
        self.noTitleButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = noTitleButton
        self.searchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(StationTableViewController.configureSearchBar))
        self.navigationItem.rightBarButtonItem = self.searchButton
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.clearsSelectionOnViewWillAppear = true
        
        //UISearchBar 設定
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.delegate = self
        //更新結果呈現在此頁
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        //呈現結果不會有black mask
        self.searchController.dimsBackgroundDuringPresentation = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.searchController.active){
            return self.searchResults.count
        }else{
            return self.staInfo.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: StationTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! StationTableViewCell
        
        cell.nameLabel.text = (self.searchController.active) ? (self.searchResults[indexPath.row]["StationName"] as? String) : (staInfo[indexPath.row]["StationName"] as? String)
        cell.addressLabel.text = (self.searchController.active) ? (self.searchResults[indexPath.row]["StationAddress"] as? String) : (staInfo[indexPath.row]["StationAddress"] as? String)
        
        return cell
    }

    //搜尋功能
    func configureSearchBar(){
        self.searchController.hidesNavigationBarDuringPresentation = false
        //結果呈現在此VC上
        definesPresentationContext = true
        //輸入框自動大小寫轉換>不設定
        self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.None
        //使用預設鍵盤
        self.searchController.searchBar.keyboardType = UIKeyboardType.Default
        //search bar placeholder
        self.searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        //將UISearchBar放到Navigation的titleView上
        self.navigationItem.titleView = self.searchController.searchBar
    }
    
    func filterContentForSearchText(searchText: String){
        //搜尋結果
        self.searchResults = self.staInfo.filter({
            if let staName = $0["StationName"], let staAddress = $0["StationAddress"]{
                return (staName!.rangeOfString(searchText).location != NSNotFound) || (staAddress!.rangeOfString(searchText).location != NSNotFound)
            }else{
                return false
            }
        })
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        //開始進行搜尋
        let searchText = searchController.searchBar.text
        filterContentForSearchText(searchText!)
        self.tableView.reloadData()
    }
     
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //按下搜尋按鈕
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = nil
        self.navigationController?.navigationBar.topItem?.hidesBackButton = true
    }
     
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        //離開搜尋
        self.navigationController?.navigationBar.topItem?.hidesBackButton = false
        self.navigationItem.rightBarButtonItem = self.searchButton
        self.navigationItem.titleView = nil
    }
        

}
