//
//  TodayWidgetTableViewCell.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/4/18.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import UIKit

class TodayWidgetTableViewCell: UITableViewCell {
    
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
