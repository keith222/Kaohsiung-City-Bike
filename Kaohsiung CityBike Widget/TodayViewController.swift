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
    
    let userDefault: NSUserDefaults = NSUserDefaults(suiteName: "group.kcb.todaywidget")!
    private var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.separatorColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 0.6)
        var currentSize: CGSize = self.preferredContentSize
        if let saved = self.userDefault.arrayForKey("staForTodayWidget"){
            currentSize.height = (50 * CGFloat(saved.count)) - 1
            self.preferredContentSize = currentSize
        }
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let item = self.userDefault.arrayForKey("staForTodayWidget"){
            return item.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TodayWidgetTableViewCell
        if let station = self.userDefault.arrayForKey("staForTodayWidget"){
            cell.stationName.text = station[indexPath.row] as? String
            if self.xmlItems != nil{
                cell.available.text = self.xmlItems!.filter({$0.staName == (station[indexPath.row] as? String)})[0].ava
                cell.available.textColor = (Int(cell.available.text!)! < 10 ) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : UIColor.whiteColor()
                cell.park.text = self.xmlItems!.filter({$0.staName == (station[indexPath.row] as? String)})[0].unava
                cell.park.textColor = (Int(cell.park.text!)! < 10 ) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : UIColor.whiteColor()
            }
        }
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let station = self.userDefault.arrayForKey("staForTodayWidget"){
            let urlString = "CityBike://?"+(station[indexPath.row] as! String).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let url: NSURL = NSURL(string: urlString)!
            self.extensionContext?.openURL(url, completionHandler: nil)
        }
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        getBikeInfo(completionHandler)
    }
    
    func getBikeInfo(completionHandler: ((NCUpdateResult) -> Void)!){
        let xmlParser = BikeParser()
        
        xmlParser.parserXml("http://www.c-bike.com.tw/xml/stationlistopendata.aspx", completionHandler: {(xmlItems:[(staID:String,staName:String,ava:String,unava:String)])->Void in
            self.xmlItems = xmlItems
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
            completionHandler(.NewData)
        })
    }
    
}
