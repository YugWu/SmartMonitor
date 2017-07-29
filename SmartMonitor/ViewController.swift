//
//  ViewController.swift
//  SmartMonitor
//
//  Created by WuMingyu on 2017/5/31.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import Cocoa


class ViewController: NSViewController, NSUserNotificationCenterDelegate {
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var testText: NSTextField!
    
    let notificationCenter = NSUserNotificationCenter.default
    let notificationActionTitle = "sleep"
    let notificationActions = [
            NSUserNotificationAction(identifier: "sleep", title: "sleep"),
            NSUserNotificationAction(identifier: "exit", title: "exit")]

    var observers = [String : Observer]()
    var notifications = [String: NSUserNotification]()

    var backgroundTaskRunning: Bool = false
    let sleepSeconds: UInt32 = 5

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // FIXME: circular reference with notificationCenter
        notificationCenter.delegate = self

        // TODO: dynamic define observers and notifications
        let notification = NSUserNotification()
        let cpuObserver = CpuObserver(normalValue: 50.0)

        notification.title = cpuObserver.name
        notification.actionButtonTitle = notificationActionTitle
        notification.additionalActions = notificationActions

        observers[cpuObserver.name] = cpuObserver
        notifications[cpuObserver.name] = notification
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
            self.testText.stringValue = "Stopped"
        }
    }
    
    
    func openSystemMonitor() {
        NSWorkspace.shared().launchApplication("Activity Monitor")
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
        let observerName = notification.title
        let observer = observers[observerName!]
        switch (notification.activationType) {
        case .contentsClicked:
            self.openSystemMonitor()
            self.notificationCenter.removeDeliveredNotification(notification)
            observer!.enterInitialedStatus()
         // FIXME: Do not pop window or get focus
        case .actionButtonClicked:
            observer!.enterSleepingStatus()
        case .additionalActionClicked:
            let action =
                notification.additionalActivationAction!.identifier!
            if action == "exit" {
                exit(0)
            } else if action == "sleep" {
                observer!.enterSleepingStatus()
            }
        default:
            break;
        }
    }
    
    private func runBackgroundTask() {
        // NOTE: Multi-threaded competition when update UI
        DispatchQueue.global().async {
            while self.backgroundTaskRunning {
                for observer in self.observers.values {
                    let notification = self.notifications[observer.name]
                    let result = observer.glance()
                    switch observer.status {
                    case .initialed:
                        if !result.isNormal {
                            observer.enterTriggeredStatus()
                        }
                    case .triggered:
                        if !result.isNormal {
                            if observer.triggeredSeconds < observer.triggeredMaxSeconds {
                                observer.triggeredSeconds += self.sleepSeconds
                            } else {
                                notification!.informativeText = result.description
                                self.notificationCenter.deliver(notification!)
                                observer.enterAlertedStatus()
                                observer.triggeredSeconds = 0
                            }
                        } else {
                            observer.enterInitialedStatus()
                            observer.triggeredSeconds = 0
                        }
                    case .sleeping:
                        if observer.sleepingSeconds < observer.sleepingMaxSeconds {
                            observer.sleepingSeconds += self.sleepSeconds
                        } else {
                            observer.sleepingSeconds = 0
                            observer.enterInitialedStatus()
                        }
                    case .alerted:
                        let isNotificationClosed =
                                !self.notificationCenter.deliveredNotifications.contains(
                                        notification!)
                        if isNotificationClosed {
                            observer.enterInitialedStatus()
                        }
                        else if result.isNormal {
                            self.notificationCenter.removeDeliveredNotification(
                                notification!
                            )
                            observer.enterInitialedStatus()
                        }
                    }
                }
                sleep(self.sleepSeconds)
            }
        }
    }
}

