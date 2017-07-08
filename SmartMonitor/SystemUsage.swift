//
//  SystemInfo.swift
//  SmartMonitor
//
//  Created by WuMingyu on 2017/6/3.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import Foundation
import Cocoa

private let machHostSelf = mach_host_self()
private let INTEGER_T_COUNT = MemoryLayout<integer_t>.stride
private let HOST_CPU_LOAD_INFO_COUNT =
    MemoryLayout<host_cpu_load_info>.stride / INTEGER_T_COUNT
private let HOST_BASIC_INFO_COUNT =
    MemoryLayout<host_basic_info>.stride / INTEGER_T_COUNT

private var hostCpuLoadInfo = host_cpu_load_info()
private var hostBasicInfo = host_basic_info()

private var lastCpuTicks = (natural_t(0),natural_t(0),natural_t(0),natural_t(0))

public func gethostBasicInfo() -> host_basic_info {
    var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
    _ = withUnsafeMutablePointer(to: &hostBasicInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(machHostSelf, Int32(HOST_BASIC_INFO), $0, &size)
        }
    }
    return hostBasicInfo
}

public func getCpuUsage() -> (Double, Double, Double, Double){
    var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
    _ = withUnsafeMutablePointer(to: &hostCpuLoadInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(machHostSelf, Int32(HOST_CPU_LOAD_INFO), $0, &size)
        }
    }
    let user = Double(hostCpuLoadInfo.cpu_ticks.0 - lastCpuTicks.0)
    let sys = Double(hostCpuLoadInfo.cpu_ticks.1 - lastCpuTicks.1)
    let idle = Double(hostCpuLoadInfo.cpu_ticks.2 - lastCpuTicks.2)
    let nice = Double(hostCpuLoadInfo.cpu_ticks.3 - lastCpuTicks.3)
    let total = user + sys + idle + nice
    lastCpuTicks = hostCpuLoadInfo.cpu_ticks
    return (user / total, sys / total, idle / total, nice / total)
}
