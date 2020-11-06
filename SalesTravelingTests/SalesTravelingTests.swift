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
	
	func testDataManager_fetchRoutes_successWithResponse() {
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
		
		let exp = expectation(description: "wait for async response.")
		
		let sut = DataManager(fetcher: { source, destination, completion in
			completion(.success([MKRoute()]))
		})
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case .success(let models):
				XCTAssertEqual(models.count, 5)
				XCTAssertTrue(models.contains(currentToNewDirection))
				XCTAssertTrue(models.contains(newToOld1Direction))
				XCTAssertTrue(models.contains(old1ToNewDirection))
				XCTAssertTrue(models.contains(newToOld2Direction))
				XCTAssertTrue(models.contains(old2ToNewDirection))

			case .failure(let error):
				XCTFail("expect succes but get error instead \(error)")

			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}
}
