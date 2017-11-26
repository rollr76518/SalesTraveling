//
//  CountdownManager.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/26.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import Foundation


class CountdownManager {
	static let shared = CountdownManager()
	fileprivate lazy var timer = makeTimer()
	fileprivate var second = 0 {
		didSet {
			if second >= 60 {
				second = 0
				countTimes = 0
			}
		}
	}
	fileprivate var countTimes = 0
}

fileprivate extension CountdownManager {
	func makeTimer() -> Timer {
		let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
			self.second += 1
			let info = ["second": self.second, "countTimes": self.countTimes]
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "test"), object: nil, userInfo: info)
		}
		return timer
	}
}

extension CountdownManager {
	func startTimer() {
		timer.fire()
	}
	
	func stopTimer() {
		timer.invalidate()
	}
	
	func canFetchAPI(_ times: Int) -> Bool {
		return countTimes + times < 60
	}
}
