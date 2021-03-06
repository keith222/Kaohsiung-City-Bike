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
        if #available(iOS 11.0, *) {
            self.configureSearchBar()
            
        } else {
            self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.configureSearchBar))
            self.navigationItem.rightBarButtonItem = self.searchButton
        }
        //呈現結果不會有black mask
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.loadViewIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            self.searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Search", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor.placeholderColor])
        } else {
            // Fallback on earlier versions
        }
    }
    
    //搜尋功能
    @objc func configureSearchBar(){
        //結果呈現在此VC上
        definesPresentationContext = true
        //輸入框自動大小寫轉換>不設定
        self.searchController.searchBar.autocapitalizationType = .none
        //使用預設鍵盤
        self.searchController.searchBar.keyboardType = .default
        //search bar placeholder
        self.searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        
        //設定 search bar 輸入框 icon 顏色
        let textField = searchController.searchBar.value(forKey: "searchField") as! UITextField
        let glassIconView = textField.leftView as! UIImageView
        glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
        glassIconView.tintColor = .white

        let clearButton = textField.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = .white
        
        //將UISearchBar放到Navigation的titleView上
        if #available(iOS 11.0, *) {
            self.searchController.hidesNavigationBarDuringPresentation = true
            
            if let textfield = self.searchController.searchBar.value(forKey: "searchField") as? UITextField {
                if let backgroundview = textfield.subviews.first {

                    // Background color
                    backgroundview.backgroundColor = .white

                    // Rounded corner
                    backgroundview.layer.cornerRadius = 10
                    backgroundview.clipsToBounds = true
                }
            }
            
            self.navigationItem.searchController = self.searchController
            self.navigationItem.hidesSearchBarWhenScrolling = true
            
        } else {
            self.searchController.searchBar.tintColor = .lightGray
            self.navigationItem.titleView = self.searchController.searchBar
            //讓searchbar出現鍵盤
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //開始進行搜尋
        let searchText = searchController.searchBar.text
        filterContentForSearchText(searchText!)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if #available(iOS 11.0, *) {} else {
            //按下搜尋按鈕
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem = nil
            self.navigationController?.navigationBar.topItem?.hidesBackButton = true
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //離開搜尋
        if #available(iOS 11.0, *) {} else {
            self.navigationController?.navigationBar.topItem?.hidesBackButton = false
            self.navigationItem.rightBarButtonItem = self.searchButton
            self.navigationItem.titleView = nil
        }
    }
    
    func filterContentForSearchText(_ searchText: String){}
}
