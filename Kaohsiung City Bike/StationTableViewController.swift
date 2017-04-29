//
//  StationTableViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/3/26.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit

protocol sendData {
    func sendData(_ stationName: String)
}

class StationTableViewController: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating{

    var staInfo = DataGet().bikeLocationJson()
    let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    var mDelegate: sendData?
    var searchButton: UIBarButtonItem!
    var noTitleButton: UIBarButtonItem!
    var searchController: UISearchController!
    var searchResults: [[String: AnyObject]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 70.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.title = NSLocalizedString("Station_List", comment: "")
        self.noTitleButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = noTitleButton
        self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(StationTableViewController.configureSearchBar))
        self.navigationItem.rightBarButtonItem = self.searchButton
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.clearsSelectionOnViewWillAppear = true
        
        //UISearchBar 設定
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.delegate = self
        //更新結果呈現在此頁
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        //呈現結果不會有black mask
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.loadViewIfNeeded()
        
        if let likeArray = self.userDefault.object(forKey: "staForTodayWidget"){
            for (index,element) in self.staInfo.enumerated(){
                if (likeArray as! NSArray).contains(where: {$0 as? String == (element["StationName"] as? String)}){
                    let tempElement = staInfo.remove(at: index)
                    staInfo.insert(tempElement, at: 0)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.searchController.isActive){
            return self.searchResults.count
        }else{
            return self.staInfo.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: StationTableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationTableViewCell
        
        cell.nameLabel.text = (self.searchController.isActive) ? (self.searchResults[indexPath.row]["StationName"] as? String) : (staInfo[indexPath.row]["StationName"] as? String)
        cell.addressLabel.text = (self.searchController.isActive) ? (self.searchResults[indexPath.row]["StationAddress"] as? String) : (staInfo[indexPath.row]["StationAddress"] as? String)
        
        cell.likeButton.tag = (indexPath as NSIndexPath).row
        cell.likeButton.addTarget(self, action: #selector(self.likeButtonAction(_:)), for: .touchUpInside)
        
        if let staArray = self.userDefault.object(forKey: "staForTodayWidget"){
            if (staArray as! NSArray).contains(where: {$0 as? String == cell.nameLabel.text}){
                cell.likeButton.setImage(UIImage(named: "starfilled"), for: UIControlState())
            }else{
                cell.likeButton.setImage(UIImage(named: "star"), for: UIControlState())
            }
        }else{
            cell.likeButton.setImage(UIImage(named: "star"), for: UIControlState())
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = (self.searchController.isActive) ? (self.searchResults[indexPath.row]["StationName"] as? String) : (staInfo[indexPath.row]["StationName"] as? String)

        self.mDelegate?.sendData(selectedCell!)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func likeButtonAction(_ sender:UIButton){
        if var staArray = self.userDefault.array(forKey: "staForTodayWidget"){
            let staName = (self.searchController.isActive) ?  (self.searchResults[sender.tag]["StationName"] as? String) : (staInfo[sender.tag]["StationName"] as? String)
            if staArray.contains(where: {$0 as? String == staName}){
                staArray = staArray.filter({$0 as? String != staName})
                self.userDefault.set(staArray, forKey: "staForTodayWidget")
                self.userDefault.synchronize()
                NSLog("remove station")
                sender.setImage(UIImage(named: "star"), for: UIControlState())
            }else{
                if staArray.count < 8{
                    staArray.append(staName!)
                    self.addAlert(staArray as NSArray, button: sender)
                }else{
                    let alert = UIAlertController(title: NSLocalizedString("Reached_the_limit", comment: ""), message: NSLocalizedString("Only_8_Station_can_be_added", comment: ""), preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }else{
            let array = [(self.searchController.isActive) ?  (self.searchResults[sender.tag]["StationName"] as! String) : (staInfo[sender.tag]["StationName"] as! String)]
            self.addAlert(array as NSArray, button: sender)
        }
//        print(self.userDefault.arrayForKey("staForTodayWidget"))
    }
    
    //Alert
    func addAlert(_ stationArray: NSArray,button: UIButton){
        let widgetAlert = UIAlertController(title: NSLocalizedString("Widget_alert_title", comment: ""), message: NSLocalizedString("Widget_alert_content", comment: ""), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Widget_alert_ok", comment: ""), style: .default, handler: {(action)->Void in
            
            self.userDefault.set(stationArray, forKey: "staForTodayWidget")
            self.userDefault.synchronize()
            NSLog("saves station")
            button.setImage(UIImage(named: "starfilled"), for: UIControlState())
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("Widget_alert_cancel", comment: ""), style: .cancel, handler: nil)
        widgetAlert.addAction(cancelAction)
        widgetAlert.addAction(okAction)
        self.present(widgetAlert, animated: true, completion: nil)
    }
    
    //搜尋功能
    func configureSearchBar(){
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        
        //結果呈現在此VC上
        definesPresentationContext = true
        //輸入框自動大小寫轉換>不設定
        self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.none
        //使用預設鍵盤
        self.searchController.searchBar.keyboardType = UIKeyboardType.default
        //search bar placeholder
        self.searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        
        //將UISearchBar放到Navigation的titleView上
        self.navigationItem.titleView = self.searchController.searchBar
        
        //讓searchbar出現鍵盤
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    func filterContentForSearchText(_ searchText: String){
        //搜尋結果

        self.searchResults = self.staInfo.filter({
            if let staName = $0["StationName"], let staAddress = $0["StationAddress"]{
                return (staName.range(of: searchText).location != NSNotFound) || (staAddress.range(of: searchText).location != NSNotFound)
            }else{
                return false
            }
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //開始進行搜尋
        let searchText = searchController.searchBar.text
        filterContentForSearchText(searchText!)
        self.tableView.reloadData()
    }
     
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //按下搜尋按鈕
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = nil
        self.navigationController?.navigationBar.topItem?.hidesBackButton = true
    }
     
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //離開搜尋
        self.navigationController?.navigationBar.topItem?.hidesBackButton = false
        self.navigationItem.rightBarButtonItem = self.searchButton
        self.navigationItem.titleView = nil
    }

}
