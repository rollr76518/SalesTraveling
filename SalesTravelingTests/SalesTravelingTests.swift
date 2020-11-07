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
		//Current -> New
		//New -> Old1
		//Old1 -> New
		//New -> Old2
		//Old2 -> New
		
		let currentPlacemark = HYCPlacemark(title: "Current")
		let newPlacemark = HYCPlacemark(title: "new")
		let old1Placemark = HYCPlacemark(title: "old1")
		let old2Placemark = HYCPlacemark(title: "old2")
		
		let currentToNewPlacemarkDirection = DirectionModel(
			source: currentPlacemark,
			destination: newPlacemark,
			routes: [MKRoute()])
		
		let newToOld1PlacemarkDirection = DirectionModel(
			source: newPlacemark,
			destination: old1Placemark,
			routes: [MKRoute()])
		
		let old1ToPlacemarkDirection = DirectionModel(
			source: old1Placemark,
			destination: newPlacemark,
			routes: [MKRoute()])
		
		let newToOld2PlacemarkDirection = DirectionModel(
			source: newPlacemark,
			destination: old2Placemark,
			routes: [MKRoute()])
		
		let old2ToNewPlacemarkDirection = DirectionModel(
			source: old2Placemark,
			destination: newPlacemark,
			routes: [MKRoute()])
		
		let sut = DataManager(fetcher: { source, destination, completion in
			completion(.success([MKRoute()]))
		})
		
		let exp = expectation(description: "Wait for callback.")
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case .failure(let error):
				XCTFail("Should not error but get \(error)")
			case .success(let models):
				XCTAssertEqual(models.count, 5)
				XCTAssertTrue(models.contains(currentToNewPlacemarkDirection))
				XCTAssertTrue(models.contains(newToOld1PlacemarkDirection))
				XCTAssertTrue(models.contains(old1ToPlacemarkDirection))
				XCTAssertTrue(models.contains(newToOld2PlacemarkDirection))
				XCTAssertTrue(models.contains(old2ToNewPlacemarkDirection))
			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}

	func testDataManager_fetchDirections_failure() {
		
		let currentPlacemark = HYCPlacemark(title: "Current")
		let newPlacemark = HYCPlacemark(title: "new")
		let old1Placemark = HYCPlacemark(title: "old1")
		let old2Placemark = HYCPlacemark(title: "old2")
		
		let sut = DataManager(fetcher: { source, destination, completion in
			completion(.failure(NSError(domain: "Any Error", code: 0)))
		})
		
		let exp = expectation(description: "Wait for callback.")
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case .failure:
				break
			case .success(let models):
				XCTFail("Should be failure but get \(models)")
			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}
	
	func testDataManager_fetchDirection_dispatchToMainThread() {
		
		let currentPlacemark = HYCPlacemark(title: "Current")
		let newPlacemark = HYCPlacemark(title: "new")
		let old1Placemark = HYCPlacemark(title: "old1")
		let old2Placemark = HYCPlacemark(title: "old2")
		
		let sut = DataManager(fetcher: { source, destination, completion in
			DispatchQueue.main.async {
				completion(.success([MKRoute()]))
			}
		})
		
		let exp = expectation(description: "Wait for callback.")
		
		sut.fetchDirections(
			ofNew: newPlacemark,
			toOld: [old1Placemark, old2Placemark],
			current: currentPlacemark) { (result) in
			switch result {
			case .failure(let error):
				XCTFail("Should not error but get \(error)")
			case .success(let models):
				XCTAssertEqual(models.count, 5)
			}
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 0.1)
	}
}
