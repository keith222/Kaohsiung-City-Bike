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
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected{
            self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        }else{
            self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        }
        // Configure the view for the selected state
    }

}