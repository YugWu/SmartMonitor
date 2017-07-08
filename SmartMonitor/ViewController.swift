//
//  ViewController.swift
//  SmartMonitor
//
//  Created by WuMingyu on 2017/5/31.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var testText: NSTextField!
    
    var backgroundTaskRunning: Bool! = false
    var notificationSended: Bool! = false
    var cpuHighUsageValue: Double = 0.90
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.cpuHighUsageValue /= Double(gethostBasicInfo().avail_cpus)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func testAction(sender: AnyObject) {
        if self.backgroundTaskRunning == false {
            self.backgroundTaskRunning = true
            self.runBackgroundTask()
            self.testText.stringValue = "Started"
        }
        else {
            self.backgroundTaskRunning = false
            self.testText.stringValue = "Stoped"
        }
    }
    // Todo: window control with notification
    private func runBackgroundTask() {
        DispatchQueue.global().async {
            let aNotification = NSUserNotification()
            while self.backgroundTaskRunning {
                let (cpuUserUsage, _, _, _) = getCpuUsage()
                if cpuUserUsage > self.cpuHighUsageValue && !self.notificationSended{
                    DispatchQueue.main.async {
                        aNotification.title = "High Cpu Usage"
                        aNotification.informativeText = String(
                            format: "user: %0.2f%%", cpuUserUsage * 100)
                        NSUserNotificationCenter.default.scheduleNotification(
                            aNotification)
                        self.notificationSended = true
                    }
                }
                else if cpuUserUsage < self.cpuHighUsageValue && self.notificationSended{
                    self.notificationSended = false
                }
                sleep(5)
            }
        }
    }

}

