//
//  TodayWidgetTableViewCell.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/4/18.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit

class TodayWidgetTableViewCell: UITableViewCell, ReactiveView {
    
    @IBOutlet weak var stationName: UILabel!
    @IBOutlet weak var available: UILabel!
    @IBOutlet weak var park: UILabel!
    @IBOutlet var sitePoint: UIView!
    @IBOutlet weak var parkLabel: UILabel!
    @IBOutlet weak var bikeLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        self.layoutMargins = .zero
        self.preservesSuperviewLayoutMargins = false
    
        self.sitePoint.layoutIfNeeded()
        self.sitePoint.layer.cornerRadius = self.sitePoint.frame.width / 2
        self.sitePoint.layer.masksToBounds = true
        
        guard #available(iOS 10, *) else{
            self.backgroundColor = .black
            self.stationName.textColor = .white
            self.parkLabel.textColor = .white
            self.bikeLabel.textColor = .white
            return
        }
    }
    
    func bindViewModel(_ dataModel: Any) {
        if let viewModel = dataModel as? HomeViewModel {
            self.stationName.text = viewModel.name
            
            var normalColor: UIColor?
            if #available(iOS 10, *){
                normalColor = .black
            }else{
                normalColor = .white
            }
            
            self.available.textColor = (viewModel.available < 10) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : normalColor
            self.available.text = "\(viewModel.available!)"
            
            self.park.textColor = (viewModel.park < 10) ? UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1) : normalColor
            self.park.text = "\(viewModel.park!)"
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected{
            self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        }else{
            if #available(iOS 10, *){}else{
               self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            }
        }
        // Configure the view for the selected state
    }

}
