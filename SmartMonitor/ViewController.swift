//
//  ViewController.swift
//  SmartMonitor
//
//  Created by WuMingyu on 2017/5/31.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import Cocoa


enum ObserverStatus: Int {
    case inited = 0
    case triggered = 1
    case alerted = 2
    case sleeped = 3
}


class ViewController: NSViewController, NSUserNotificationCenterDelegate {
    // FIXME: circular reference with notificationCenter
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var testText: NSTextField!
    
    let notification = NSUserNotification()
    let notificationCenter = NSUserNotificationCenter.default
    let notificationActoins = [
        NSUserNotificationAction(identifier: "sleep", title: "sleep"),
        NSUserNotificationAction(identifier: "exit", title: "exit")]
    
    let cpuObserver = CpuObserver()
    var cpuObserverStatus = ObserverStatus.inited
    var cpuObserverTriggeredTime = 0
    let cpuObserverMaxTriggeredTime = 10
    var cpuObserverSleepedTime = 0
    let cpuObserverMaxSleepedTime = 10
    
    var backgroundTaskRunning: Bool = false
    let sleepTime: UInt32 = 5 // seconds, check results every interval time
    let persistentTime = 300 // raise alert after persistent time
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.notificationCenter.delegate = self
        self.notification.actionButtonTitle = "ignore"
        self.notification.additionalActions = self.notificationActoins
        
        // TODO: select item
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
    
    
    func openSystemMonitor() {
        NSWorkspace.shared().launchApplication("Activity Monitor")
    }
    
    
    func handleNotification(notification: NSUserNotification) {
        self.testText.stringValue = "\(notification.activationType)"
        switch (notification.activationType) {
        case .replied:
            guard let res = notification.response else { return }
            print("User replied: \(res.string)")
        default:
            break;
        }
    }
    
    // NSUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: NSUserNotificationCenter,
        shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(
        _ center: NSUserNotificationCenter,
        didActivate notification: NSUserNotification) {
        
        switch (notification.activationType) {
        case .contentsClicked:
            self.openSystemMonitor()
            self.notificationCenter.removeDeliveredNotification(self.notification)
            self.cpuObserverStatus = ObserverStatus.inited
        case .actionButtonClicked:
            // TODO: no action button and design the notification communiction
            self.testText.stringValue = "actionButtonClicked"
        case .additionalActionClicked:
            let action =
                notification.additionalActivationAction!.identifier!
            if action == "sleep" {
                self.cpuObserverStatus = ObserverStatus.sleeped
            } else if action == "exit" {
                exit(0)
            }
        default:
            break;
        }
    }
    
    func sendNotification(title: String, informativeText: String) {
        self.notification.title = title
        self.notification.informativeText = informativeText
        self.notificationCenter.scheduleNotification(self.notification)
    }
    
    private func runBackgroundTask() {
        DispatchQueue.global().async {
            while self.backgroundTaskRunning {
                let result = self.cpuObserver.glance()
                switch self.cpuObserverStatus {
                case .inited:
                    if !result.isNormal {
                        self.cpuObserverStatus = ObserverStatus.triggered
                    }
                case .triggered:
                    if !result.isNormal {
                        if self.cpuObserverTriggeredTime < self.cpuObserverMaxTriggeredTime {
                            self.cpuObserverTriggeredTime += Int(self.sleepTime)
                        }
                        else {
                            DispatchQueue.main.async {
                                self.sendNotification(
                                    title: result.description,
                                    informativeText: String(
                                        format: "user: %0.2f%s", result.value,
                                        result.unit))
                            }
                            self.cpuObserverStatus = ObserverStatus.alerted
                            self.cpuObserverTriggeredTime = 0
                        }
                    }
                    else {
                        self.cpuObserverStatus = ObserverStatus.inited
                        self.cpuObserverTriggeredTime = 0
                    }
                case .sleeped:
                    if self.cpuObserverSleepedTime < self.cpuObserverMaxSleepedTime {
                        self.cpuObserverSleepedTime += Int(self.sleepTime)
                    }
                    else {
                        self.cpuObserverSleepedTime = 0
                        self.cpuObserverStatus = ObserverStatus.inited
                    }
                default:
                    break;
                }
                sleep(self.sleepTime)
            }
        }
    }
}

