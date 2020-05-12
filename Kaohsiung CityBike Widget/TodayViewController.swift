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
    private var source: [TodayWidgetTableViewCellViewModel]?
    private var tableHelper: TableViewHelper?
    private var savedStations: [(Int,String,String)] = []
    
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
            source: (self.source ?? []) as [AnyObject],
            selectAction: { [weak self] num in
                guard let savedStations = self?.savedStations, !savedStations.isEmpty else { return }
                
                var urlString = "CityBike://?"
                urlString += ("\(savedStations[num].0)").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                let url: URL = URL(string: urlString)!
                self?.extensionContext?.open(url, completionHandler: nil)
        })
        
        
        if #available(iOS 10, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
    }
    
    private func setUp() {
        self.todayTableView.isHidden = true
        self.todayTableView.estimatedRowHeight = 56
        self.todayTableView.rowHeight = UITableView.automaticDimension
        self.todayTableView.cellLayoutMarginsFollowReadableWidth = false
        self.todayTableView.tableFooterView = UIView(frame: .zero)
        self.todayTableView.separatorInset = UIEdgeInsets.init(top: 0, left: 55, bottom: 0, right: 1)
        self.todayTableView.separatorColor = .blue
        
        self.defaultButton.setTitle(NSLocalizedString("Notification_Set", comment: ""), for: .normal)
        
        if let savedArray = self.userDefault.array(forKey: "staForTodayWidget") as? [String] {
            
            let stations = self.homeViewModel.fetchStationListForWidget()
            savedStations = stations.filter{ savedArray.contains($0.no ?? "") }
                .compactMap({ value in
                    return (value.id!,value.name!,value.englishname!)
                })
        }
    }
    
    @IBAction func defaultAction(_ sender: UIButton) {
        let url: URL = URL(string: "CityBike://?openlist")!
        self.extensionContext?.open(url, completionHandler: nil)
    }
    
    
    @available(iOS 10, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        var currentSize: CGSize = self.preferredContentSize
        
        switch activeDisplayMode {
        case .expanded:
            if let saved = self.userDefault.array(forKey: "staForTodayWidget") ,saved.count > 0 {
                currentSize.height = (55 * CGFloat(saved.count))
            }
            self.preferredContentSize = currentSize
        case .compact:
            self.preferredContentSize = maxSize
        @unknown default:
            self.preferredContentSize = currentSize
        }
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        getBikeInfo(completionHandler)
    }
    
    func getBikeInfo(_ completionHandler: ((NCUpdateResult) -> Void)!){
        self.defaultButton.isHidden = true
        
        guard savedStations.count > 0 else {
            self.defaultButton.isHidden = false
            return
        }
        
        let ids = savedStations.map{$0.0}
        self.homeViewModel.fetchStationInfo(with: ids, handler: { [weak self] parks in
            guard let parks = parks else {
                self?.defaultButton.isHidden = false
                return
            }
                        
            self?.source = parks.map({ [weak self] park -> TodayWidgetTableViewCellViewModel in
                let name = self?.savedStations
                    .filter{ park.StationID == "\($0.0)"}.first
                    .map{ (Locale.current.languageCode == "zh") ? $0.1 : $0.2} ?? ""
                return TodayWidgetTableViewCellViewModel(name: name, available: park.AvailableRentBikes, park: park.AvailableReturnBikes)
            })
            
            self?.tableHelper?.reloadData = (self?.source)! as [AnyObject]
            self?.todayTableView.isHidden = false
            
            completionHandler(.newData)
        })
    }
    
}
