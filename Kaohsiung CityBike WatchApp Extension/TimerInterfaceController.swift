//
//  TimerInterfaceController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/12/1.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import WatchKit
import Foundation


class TimerInterfaceController: WKInterfaceController {
    
    @IBOutlet var timeLabel: WKInterfaceLabel!
    @IBOutlet var priceLabel: WKInterfaceLabel!
    @IBOutlet var startStopButtonOutlet: WKInterfaceButton!
    var isStopped = true
    var count = 0
    var stopTimer:NSTimer!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startStopButton() {
        if isStopped{
            self.isStopped = false
            self.timeLabel.setText("00:00:00")
            self.priceLabel.setText("0")
            self.stopTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(TimerInterfaceController.stopWatchTimer(_:)), userInfo: nil, repeats: true)
            self.startStopButtonOutlet.setBackgroundColor(UIColor(red: 1, green: 0, blue: 128/255, alpha: 1))
            self.startStopButtonOutlet.setTitle(NSLocalizedString("TimeStop", comment: ""))
            
        }else{
            isStopped = true
            self.stopTimer.invalidate()
            self.stopTimer = nil
            self.startStopButtonOutlet.setTitle(NSLocalizedString("TimeStart", comment: ""))
            self.startStopButtonOutlet.setBackgroundColor(UIColor(red: 45/255, green: 222/255, blue: 149/255, alpha: 1))
            
            var calMinute = Int(count/60)
            var cost = 0//計算花費
            switch calMinute{
            case 0...60: cost = 0 //不滿60分鐘免費
            case 61...90: cost = 10 //90分鐘 10元
            default: //90分後每30分20元
                calMinute -= 90
                if calMinute % 30 != 0{
                    calMinute = Int(calMinute/30)+1
                }else{
                    calMinute = Int(calMinute/30)
                }
                cost = 10 + (calMinute*20)
            }
            self.priceLabel.setText(String(cost))
            
            self.count = 0
        }
        
    }
    
    func stopWatchTimer(timer:NSTimer){
        count += 1
        let second = count%60
        let minute = (count/60)%60
        let hour = Int(count/3600)
        self.timeLabel.setText(String(format: "%02d:%02d:%02d",hour,minute,second))
    }
}
