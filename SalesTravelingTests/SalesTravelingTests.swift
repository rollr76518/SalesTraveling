//
//  SalesTravelingTests.swift
//  SalesTravelingTests
//
//  Created by Ryan on 2020/11/6.
//  Copyright © 2020 Hanyu. All rights reserved.
//

import XCTest
@testable import SalesTraveling
import MapKit

class SalesTravelingTests: XCTestCase {

	
	func testDataManager_fetchDirections_success() {
		//User -> New
		//New -> Old1
		//Old1 -> New
		//New -> Old2
		//Old2 -> New
		
		let currentPlacemark = HYCPlacemark(title: "Current")
		let newPlacemark = HYCPlacemark(title: "new")
		let old1Placemark = HYCPlacemark(title: "old1")
		let old2Placemark = HYCPlacemark(title: "old2")
				
		let currentToNewDirection = DirectionModel(
					source: currentPlacemark,
					destination: newPlacemark,
					routes: [MKRoute()])
				
		let newToOld1Direction = DirectionModel(
					source: newPlacemark,
					destination: old1Placemark,
					routes: [MKRoute()])
				
		let old1ToNewDirection = DirectionModel(
					source: old1Placemark,
					destination: newPlacemark,
					routes: [MKRoute()])
				
		let newToOld2Direction = DirectionModel(
					source: newPlacemark,
					destination: old2Placemark,
					routes: [MKRoute()])
				
		let old2ToNewDirection = DirectionModel(
					source: old2Placemark,
					destination: newPlacemark,
					routes: [MKRoute()])

		let sut = DataManager(fetcher: { source, destination, completion in
			completion(.success([MKRoute()]))
		})
		
		let exp = expectation(description: "Wait for callback")
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case.failure:
				XCTFail()
			case.success(let models):
				XCTAssertEqual(models.count, 5)
				XCTAssertTrue(models.contains(currentToNewDirection))
				XCTAssertTrue(models.contains(newToOld1Direction))
				XCTAssertTrue(models.contains(old1ToNewDirection))
				XCTAssertTrue(models.contains(newToOld2Direction))
				XCTAssertTrue(models.contains(old2ToNewDirection))
			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}
	
	func testDataManager_fetchDirections_failed() {
		let currentPlacemark = HYCPlacemark(title: "Current")
		let newPlacemark = HYCPlacemark(title: "new")
		let old1Placemark = HYCPlacemark(title: "old1")
		let old2Placemark = HYCPlacemark(title: "old2")

		let sut = DataManager(fetcher: { source, destination, completion in
			completion(.failure(NSError(domain: "AnyError", code: 0)))
		})
		
		let exp = expectation(description: "Wait for callback")
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case.failure:
				break
			case.success:
				XCTFail()
			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}
}
