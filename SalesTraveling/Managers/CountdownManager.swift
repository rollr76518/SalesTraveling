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
	fileprivate var second = 60 {
		didSet {
			if second <= 0 {
				second = 60
				countTimes = 0
			}
		}
	}
	var countTimes = 0
}

fileprivate extension CountdownManager {
	func makeTimer() -> Timer {
		let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
			self.second -= 1
			let info = ["second": self.second, "countTimes": self.countTimes]
			NotificationCenter.default.post(name: NSNotification.Name.CountDown, object: nil, userInfo: info)
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
	
	func canCallRequest(_ times: Int) -> Bool {
		return countTimes + times < 50
	}
	
	//TODO: 可以寫測試
	//Add New Placemark
	func timesOfRequestShouldCalledWhenAddNewPlacemark(placemarks count: Int, userPlacemark isExist: Bool) -> Int {
		var times: Int = 0
		
		if isExist {
			times += 1
		}
		
		times += count * 2
		return times
	}
	//Change Already Exist Placemark
	func timesOfRequestShouldCalledWhenChangeExistPlacemark(placemarks count: Int, userPlacemark isExist: Bool) -> Int {
		var times: Int = 0
		
		if isExist {
			times += 1
		}
		
		times += (count - 1) * 2
		return times
	}
	//Change UserPlacemark
	func timesOfRequestShouldCalledWhenChangeUserPlacemark(placemarks count: Int) -> Int {
		return count * 2
	}
}
