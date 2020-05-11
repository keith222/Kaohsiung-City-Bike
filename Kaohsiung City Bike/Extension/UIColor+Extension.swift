//
//  UIColor+Extension.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2020/5/7.
//  Copyright © 2020 Yang Tun-Kai. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    static let subTitleColor: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    // Return the color for Dark Mode
                    return UIColor(hex: 0x67a0a3, transparency: 0.8) ?? .clear
                    
                } else {
                    // Return the color for Light Mode
                    return UIColor(hex: 0x5D7778, transparency: 0.5) ?? .clear
                }
            }
        } else {
            // Return a fallback color for iOS 12 and lower.
            return UIColor(hex: 0x5D7778, transparency: 0.5) ?? .clear
        }
    }()
    
    static let naviColor: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    // Return the color for Dark Mode
                    return UIColor(hex: 0x0d6568) ?? .clear
                    
                } else {
                    // Return the color for Light Mode
                    return UIColor(hex: 0x17A9AE) ?? .clear
                }
            }
        } else {
            // Return a fallback color for iOS 12 and lower.
            return UIColor(hex: 0x17A9AE) ?? .clear
        }
    }()
    
    static let titleColor: UIColor = {
        if #available(iOS 13, *) {
            return .secondaryLabel
        } else {
            // Return a fallback color for iOS 12 and lower.
            return .white
        }
    }()
    
    static let placeholderColor: UIColor = {
        if #available(iOS 13, *) {
            return .placeholderText
        } else {
            // Return a fallback color for iOS 12 and lower.
            return .lightGray
        }
    }()
}
