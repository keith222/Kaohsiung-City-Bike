//
//  SearchViewchHelper.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/26.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import UIKit

class SearchViewController: UIViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    private var searchButton: UIBarButtonItem!
    var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchController.delegate = self
        //UISearchBar 設定
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        //set search button
        self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.configureSearchBar))
        self.navigationItem.rightBarButtonItem = self.searchButton
        //呈現結果不會有black mask
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.loadViewIfNeeded()
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
    
    func updateSearchResults(for searchController: UISearchController) {
        //開始進行搜尋
        let searchText = searchController.searchBar.text
        filterContentForSearchText(searchText!)
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
    
    func filterContentForSearchText(_ searchText: String){}
}