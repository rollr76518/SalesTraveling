//
//  MapViewModelTests.swift
//  SalesTravelingTests
//
//  Created by Ryan on 2020/8/17.
//  Copyright © 2020 Hanyu. All rights reserved.
//

import XCTest
@testable import SalesTraveling
import MapKit

class MapViewModelTests: XCTestCase {

	func test_mapViewModel_shouldPassWithoutDeadLock() {
		let viewModel = MapViewModel()
		let placemarks = makeMockPlacemarks()
		
		let exp = expectation(description: "wait for test callback.")
		viewModel.add(placemarks: placemarks) { (_) in
			exp.fulfill()
		}
		wait(for: [exp], timeout: 5.0)
	}
}

extension MapViewModelTests {
	
	private func makeMockPlacemarks() -> [HYCPlacemark] {
		let source: HYCPlacemark = {
			let placemark = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0416801, 121.508074)))
			placemark.name = "西門町"
			placemark.title = "臺北市萬華區中華路一段"
			return placemark
		}()
		
		let destination1: HYCPlacemark = {
			let placemark = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0157677, 121.5555731)))
			placemark.name = "木柵動物園"
			placemark.title = "臺北市文山區新光路二段30號"
			return placemark
		}()
		
		let destination2: HYCPlacemark = {
			let placemark = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.063985, 121.575923)))
			placemark.name = "內湖好市多"
			placemark.title = "114台北市內湖區舊宗路一段268號"
			return placemark
		}()
		return [source, destination1, destination2]
	}
}

