//
//  TableViewHelper.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import UIKit

protocol ReactiveView {
    func bindViewModel(_ dataModel: Any)
}

class TableViewHelper: NSObject {
    
    private let tableView: UITableView
    private let templateCell: UITableViewCell
    private let dataSource: DataSource
    
    var reloadData: (data: [AnyObject], isLoading: Bool) = ([], true) {
        didSet{
            dataSource.data = reloadData.data
            dataSource.isLoading = reloadData.isLoading
            tableView.reloadData()
        }
    }
    
    init(tableView: UITableView, nibName: String, source: [AnyObject] = [], selectAction: ((Int)->())? = nil, refreshAction: ((Int)->())? = nil) {
        self.tableView = tableView
        
        let nib = UINib(nibName: nibName, bundle: nil)
        
        // create an instance of the template cell and register with the table view
        templateCell = nib.instantiate(withOwner: nil, options: nil)[0] as! UITableViewCell
        tableView.register(nib, forCellReuseIdentifier: templateCell.reuseIdentifier!)
        
        dataSource = DataSource(data: [], templateCell: templateCell, selectAction: nil)
        
        super.init()
        
        //set datasource variables
        dataSource.data = source
        dataSource.selectAction = selectAction
        dataSource.refreshAction = refreshAction
        dataSource.isLoading = true
        
        self.tableView.dataSource = dataSource
        self.tableView.delegate = dataSource
        
        guard !source.isEmpty else { return }
        
        self.tableView.reloadData()
    }
}

class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private let templateCell: UITableViewCell
    private var page: Int = 1
    
    fileprivate var isLoading: Bool = true
    fileprivate var selectAction: ((Int)->())?
    fileprivate var data: [AnyObject]
    
    var refreshAction: ((Int)->())?
    
    init(data: [AnyObject], templateCell: UITableViewCell, selectAction: ((Int)->())? = nil) {
        self.data = data
        self.templateCell = templateCell
        self.selectAction = selectAction
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: templateCell.reuseIdentifier!)!
        if let reactiveView = cell as? ReactiveView {
            reactiveView.bindViewModel(data[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectAction!(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if (contentHeight - scrollView.frame.height) - offsetY < 70 && isLoading {
            page += 1
            isLoading = false
            refreshAction?(page)
        }
    }
}
