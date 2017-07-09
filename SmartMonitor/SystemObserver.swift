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
    var description: String
}


class Observer {
    var result: Result
    
    init (normalValue: Float, unit: String, description: String){
        result = Result(
            isNormal: false, value: 0.0, normalValue: normalValue, unit: unit,
            description: description)
    }
    
    func checkResult() {
        if result.value >= result.normalValue {
            result.isNormal = false
        } else {
            result.isNormal = true
        }
    }
    
    func glance() -> Result {
        return result
    }
    
    func glance(_ value: Float) -> Result {
        result.value = value
        checkResult()
        return result
    }
}


class CpuObserver: Observer {
    static private let machHostSelf = mach_host_self()
    static private let INTEGER_T_COUNT = MemoryLayout<integer_t>.stride
    static private let HOST_CPU_LOAD_INFO_COUNT =
        MemoryLayout<host_cpu_load_info>.stride / INTEGER_T_COUNT

    private var hostCpuLoadInfo = host_cpu_load_info()
    private var lastCpuTicks = (natural_t(0),natural_t(0),natural_t(0),natural_t(0))
    
    init() {
        super.init(normalValue: 25.0, unit: "%", description: "All cpu usage.")
        // init lastCpuTicks
        _ = self.getCpuUsage()
    }
    
    private func getCpuUsage() -> (Float){
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
    
    override func glance() -> Result {
        return super.glance(getCpuUsage())
    }
}

