//
//  StationTableViewCell.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/3/26.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit
import SwifterSwift

class StationCell: UITableViewCell, ReactiveView {

    @IBOutlet weak var staImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    let userDefault: UserDefaults = UserDefaults(suiteName: "group.kcb.todaywidget")!
    private var stationNO: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.favoriteButton.setImage(UIImage(named: "star"), for: .normal)
        self.favoriteButton.setImage(UIImage(named: "starfilled"), for: .selected)
        self.subtitleLabel.textColor = UIColor.subTitleColor
    }
    
    func bindViewModel(_ dataModel: Any) {
        if let viewModel = dataModel as? StationCellViewModel {
            self.titleLabel.text = viewModel.name
            self.subtitleLabel.text = (Locale.current.languageCode == "zh") ? viewModel.description : viewModel.englishname
            self.stationNO = viewModel.no
            
            if let favoriteList = self.userDefault.array(forKey: "staForTodayWidget"){
                self.favoriteButton.isSelected = favoriteList.contains(where: {($0 as! String) == viewModel.no})
            }
        }
    }

    @IBAction func favoriteAction(_ sender: UIButton) {
        var title = ""
        var message = ""
        
        if let favoriteList = self.userDefault.array(forKey: "staForTodayWidget") {
            var list = favoriteList
            
            if let index = favoriteList.firstIndex(where: {($0 as! String) == self.stationNO}) {
                list.remove(at: index)
                self.userDefault.set(list, forKey: "staForTodayWidget")
                self.userDefault.synchronize()
                
            } else {
                if favoriteList.count < 8 {
                    list.append(self.stationNO!)
                
                    self.userDefault.set(list, forKey: "staForTodayWidget")
                    self.userDefault.synchronize()
                    
                    title = NSLocalizedString("Widget_alert_title", comment: "")
                    message = NSLocalizedString("Widget_alert_content", comment: "")
                
                } else {
                    title = NSLocalizedString("Reached_the_limit", comment: "")
                    message = NSLocalizedString("Only_8_Station_can_be_added", comment: "")
                    
                }
                
                self.showAlert(with: title, message: message)
            }
        } else {
            let newList = [self.stationNO!]
            self.userDefault.set(newList, forKey: "staForTodayWidget")
            self.userDefault.synchronize()
            
            title = NSLocalizedString("Widget_alert_title", comment: "")
            message = NSLocalizedString("Widget_alert_content", comment: "")
            self.showAlert(with: title, message: message)
        }
        
        sender.isSelected = !sender.isSelected
    }

    private func showAlert(with title: String, message: String) {
        UIAlertController(title: title, message: message, defaultActionButtonTitle: NSLocalizedString("Widget_alert_ok", comment: "")).show()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
