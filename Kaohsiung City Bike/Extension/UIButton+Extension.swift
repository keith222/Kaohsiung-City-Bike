//
//  UIButton+Extension.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/26.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    func addBorder(_ radius:CGFloat,thickness:CGFloat,color:UIColor){
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderWidth = thickness
        self.layer.borderColor = color.cgColor
    }
    
    func addShadow(_ color:UIColor){
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.31
    }
}
