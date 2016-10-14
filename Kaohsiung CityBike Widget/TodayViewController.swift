//
//  TodayViewController.swift
//  Kaohsiung CityBike Widget
//
//  Created by Yang Tun-Kai on 2016/4/18.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UITableViewController, NCWidgetProviding{
    
    let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    fileprivate var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 55, 0, 1)
        self.clearsSelectionOnViewWillAppear = true
        
        if #available(iOS 10, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        } else {
            var currentSize: CGSize = self.preferredContentSize
            if let saved = self.userDefault.array(forKey: "staForTodayWidget"){
                currentSize.height = (55 * CGFloat(saved.count))
            }else{
                currentSize = CGSize(width: currentSize.width, height: 55)
            }
            self.preferredContentSize = currentSize
        }
        

    }
    
    @available(iOS 10, *)
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        switch activeDisplayMode {
        case .expanded:
//            var currentSize: CGSize = self.preferredContentSize
//            if let saved = self.userDefault.array(forKey: "staForTodayWidget"){
//                currentSize.height = (55 * CGFloat(saved.count))
//            }else{
//                currentSize = CGSize(width: currentSize.width, height: 55)
//            }
            self.preferredContentSize = CGSize(width: maxSize.width, height: 165)
            
        case .compact:
            self.preferredContentSize = maxSize
        }
        
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let item = self.userDefault.array(forKey: "staForTodayWidget"){
            return (item.count == 0) ? 1 : item.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(self.userDefault.array(forKey: "staForTodayWidget"))
        if let station = self.userDefault.array(forKey: "staForTodayWidget"){
            if station.count > 0{
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayWidgetTableViewCell
                cell.stationName.text = station[(indexPath as NSIndexPath).row] as? String
                if self.xmlItems != nil{
                
                    var normalColor: UIColor?
                    if #available(iOS 10, *){
                        normalColor = .darkGray
                    }else{
                        normalColor = .white
                    }
                
                    cell.available.text = self.xmlItems!.filter({$0.staName == (station[(indexPath as NSIndexPath).row] as? String)})[0].ava
                    cell.available.textColor = (Int(cell.available.text!)! < 10 ) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : normalColor
                    cell.park.text = self.xmlItems!.filter({$0.staName == (station[(indexPath as NSIndexPath).row] as? String)})[0].unava
                    cell.park.textColor = (Int(cell.park.text!)! < 10 ) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : normalColor
                }
                cell.layoutMargins = UIEdgeInsets.zero
                cell.preservesSuperviewLayoutMargins = false
                return cell
            }else{
                let cell: UITableViewCell = UITableViewCell(style: .default, reuseIdentifier: "Default")
                cell.textLabel?.text = NSLocalizedString("Notification_Set", comment: "")
                cell.textLabel?.textColor = .darkGray
                tableView.separatorStyle = .none
                return cell
            }
        }else{
            let cell: UITableViewCell = UITableViewCell(style: .default, reuseIdentifier: "Default")
            cell.textLabel?.text = NSLocalizedString("Notification_Set", comment: "")
            cell.textLabel?.textColor = .darkGray
            tableView.separatorStyle = .none
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var urlString = "CityBike://?"
        if let station = self.userDefault.array(forKey: "staForTodayWidget"){
            if station.count > 0{
                urlString += (station[(indexPath as NSIndexPath).row] as! String).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            }else{
                urlString += "openlist"
            }
        }else{
            urlString += "openlist"
        }
        let url: URL = URL(string: urlString)!
        self.extensionContext?.open(url, completionHandler: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ((self.userDefault.array(forKey: "staForTodayWidget")?.count)! > 0) ? 55 : 110
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        getBikeInfo(completionHandler)
    }
    
    func getBikeInfo(_ completionHandler: ((NCUpdateResult) -> Void)!){
        let xmlParser = BikeParser()
        
        xmlParser.parserXml("http://www.c-bike.com.tw/xml/stationlistopendata.aspx", completionHandler: {(xmlItems:[(staID:String,staName:String,ava:String,unava:String)])->Void in
            self.xmlItems = xmlItems
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            completionHandler(.newData)
        })
    }
    
}
