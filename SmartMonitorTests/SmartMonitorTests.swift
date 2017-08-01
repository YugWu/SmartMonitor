//
//  SmartMonitorTests.swift
//  SmartMonitorTests
//
//  Created by WuMingyu on 2017/5/31.
//  Copyright © 2017年 WuMingyu. All rights reserved.
//

import XCTest
@testable import SmartMonitor

class SmartMonitorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


class SystemObserverTests: XCTestCase {
    let cpuObserver = CpuObserver(normalValue: 50)
    let memoryObserver = MemoryObserver(normalValue: 50)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCpuObserver() {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let _ = cpuObserver.glance()
        cpuObserver.enterInitialedStatus()
        let _ = memoryObserver.glance()
        memoryObserver.enterInitialedStatus()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

