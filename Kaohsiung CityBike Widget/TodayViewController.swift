//
//  TodayViewController.swift
//  Kaohsiung CityBike Widget
//
//  Created by Yang Tun-Kai on 2016/4/18.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding{
    
    @IBOutlet weak var todayTableView: UITableView!
    @IBOutlet weak var defaultButton: UIButton!
    
    private let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    private var source: [HomeViewModel]?
    private var tableHelper: TableViewHelper?
    
    lazy var homeViewModel = {
        return HomeViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        self.setUp()
        
        self.tableHelper = TableViewHelper(
            tableView: self.todayTableView,
            nibName: "TodayWidgetTableViewCell",
            source: self.source ?? [],
            selectAction: { [weak self] num in
                print("selected")
                if let station = self?.userDefault.array(forKey: "staForTodayWidget") {
                    var urlString = "CityBike://?"
                    urlString += (station[num] as! String).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                    let url: URL = URL(string: urlString)!
                    self?.extensionContext?.open(url, completionHandler: nil)
                }
        }
        )
        
        
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
    
    private func setUp() {
        self.todayTableView.isHidden = true
        self.todayTableView.estimatedRowHeight = 56
        self.todayTableView.rowHeight = UITableViewAutomaticDimension
        self.todayTableView.cellLayoutMarginsFollowReadableWidth = false
        self.todayTableView.tableFooterView = UIView(frame: .zero)
        self.todayTableView.separatorInset = UIEdgeInsetsMake(0, 55, 0, 1)
        self.todayTableView.separatorColor = .blue
        
        self.defaultButton.setTitle(NSLocalizedString("Notification_Set", comment: ""), for: .normal)
    }
    
    @IBAction func defaultAction(_ sender: UIButton) {
        let url: URL = URL(string: "CityBike://?openlist")!
        self.extensionContext?.open(url, completionHandler: nil)
    }


    @available(iOS 10, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        switch activeDisplayMode {
        case .expanded:
            var currentSize: CGSize = self.preferredContentSize
            if let saved = self.userDefault.array(forKey: "staForTodayWidget") ,saved.count > 0{
                currentSize.height = (55 * CGFloat(saved.count))
            }
            self.preferredContentSize = currentSize
        case .compact:
            self.preferredContentSize = maxSize
        }
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        getBikeInfo(completionHandler)
    }
    
    func getBikeInfo(_ completionHandler: ((NCUpdateResult) -> Void)!){
        if let savedArray = self.userDefault.array(forKey: "staForTodayWidget"), savedArray.count > 0 {
            self.defaultButton.isHidden = true
            
            self.homeViewModel.fetchStationInfo(handler: { [weak self] data in
                guard data.count > 0 else{ return }
                
                self?.source = data.map({value -> HomeViewModel in
                    return HomeViewModel(data: value)
                }).filter({ value in
                    return (savedArray.contains(where: {($0 as! String) == value.no }))
                })
                self?.tableHelper?.reloadData = (self?.source)!
                self?.todayTableView.isHidden = false
                
                completionHandler(.newData)
            })
        }else{
            self.defaultButton.isHidden = false
        }
    }
    
}
