//
//  SystemInfo.swift
//  SmartMonitor
//
//  Created by WuMingyu on 2017/6/3.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import Foundation
import Cocoa


struct Result {
    var isNormal: Bool
    var value: Float
    var normalValue: Float
    var unit: String
    var description: String {
        get {
            return String(format: "Usage: %0.2f%@", value, unit)
        }
    }
}


enum Status: Int {
    case initialed = 0
    case triggered = 1
    case alerted = 2
    case sleeping = 3
}


// TODO: config file
class Observer {
    var result: Result
    var status: Status
    let name: String
    var triggeredSeconds: UInt32 = 0
    let triggeredMaxSeconds: UInt32 = 5
    var sleepingSeconds: UInt32 = 0
    let sleepingMaxSeconds: UInt32 = 5
    
    init (name: String, normalValue: Float, unit: String) {
        result = Result(
            isNormal: false, value: 0.0, normalValue: normalValue, unit: unit)
        self.name = name
        status = Status.initialed
    }


    func record() -> Float {
        // Record result value, need to be override.
        return 0.0
    }

    func glance() -> Result {
        let value = record()
        result.value = value
        if result.value >= result.normalValue {
            result.isNormal = false
        } else {
            result.isNormal = true
        }
        return result
    }

    func enterInitialedStatus() {
        status = Status.initialed
    }

    func enterTriggeredStatus() {
        status = Status.triggered
    }

    func enterAlertedStatus() {
        status = Status.alerted
    }

    func enterSleepingStatus() {
        status = Status.sleeping
    }
}


class CpuObserver: Observer {
    static private let machHostSelf = mach_host_self()
    static private let INTEGER_T_COUNT = MemoryLayout<integer_t>.stride
    static private let HOST_CPU_LOAD_INFO_COUNT =
        MemoryLayout<host_cpu_load_info>.stride / INTEGER_T_COUNT

    private var hostCpuLoadInfo = host_cpu_load_info()
    private var lastCpuTicks = (natural_t(0),natural_t(0),natural_t(0),natural_t(0))

    init (normalValue: Float){
        super.init(name: "CPU", normalValue: normalValue, unit: "%")
        // Init lastCpuTicks
        _ = self.record()
    }
    
    override func record() -> (Float) {
        var size = mach_msg_type_number_t(CpuObserver.HOST_CPU_LOAD_INFO_COUNT)
        _ = withUnsafeMutablePointer(to: &hostCpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(CpuObserver.machHostSelf, Int32(HOST_CPU_LOAD_INFO), $0, &size)
            }
        }
        let user = Double(hostCpuLoadInfo.cpu_ticks.0 - lastCpuTicks.0)
        let sys = Double(hostCpuLoadInfo.cpu_ticks.1 - lastCpuTicks.1)
        let idle = Double(hostCpuLoadInfo.cpu_ticks.2 - lastCpuTicks.2)
        let nice = Double(hostCpuLoadInfo.cpu_ticks.3 - lastCpuTicks.3)
        let total = user + sys + idle + nice
        lastCpuTicks = hostCpuLoadInfo.cpu_ticks
        return (Float)(1 - idle / total) * 100
    }
}


class MemoryObserver: Observer {
    static private let machHostSelf = mach_host_self()
    static private let INTEGER_T_COUNT = MemoryLayout<integer_t>.stride
    static private let VM_STATISTIC_COUNT =
            MemoryLayout<vm_statistics64>.stride / INTEGER_T_COUNT
    var vmStatistic = vm_statistics64()

    init (normalValue: Float){
        super.init(name: "Memory", normalValue: normalValue, unit: "%")
    }

    override func record() -> (Float) {
        var size = mach_msg_type_number_t(MemoryObserver.VM_STATISTIC_COUNT)
        _ = withUnsafeMutablePointer(to: &vmStatistic) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(MemoryObserver.machHostSelf, Int32(HOST_LOAD_INFO), $0, &size)
            }
        }
        let sumCount = vmStatistic.free_count + vmStatistic.active_count + vmStatistic.inactive_count +
                vmStatistic.wire_count + vmStatistic.compressor_page_count
        return (1 - (Float)(vmStatistic.free_count) / (Float)(sumCount)) * 100
    }
}
