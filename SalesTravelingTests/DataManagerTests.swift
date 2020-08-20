//
//  DataManagerTests.swift
//  SalesTravelingTests
//
//  Created by Caio Zullo on 20/08/2020.
//  Copyright © 2020 Hanyu. All rights reserved.
//

import XCTest
import MapKit
@testable import Shoto

class DataManagerTests: XCTestCase {

    func test_fetchDirections_succeedsWhenAllRequestsSucceeds() {
        let newPlacemark = HYCPlacemark(name: "new placemark")
        
        let currentToNewPlacemarkDirection = DirectionModel(source: HYCPlacemark(name: "current placemark"), destination: newPlacemark, routes: [MKRoute()])
        
        let oldToNewPlacemarkDirection1 = DirectionModel(source: HYCPlacemark(name: "old placemark 1"), destination: newPlacemark, routes: [MKRoute()])
        
        let newToOldPlacemarkDirection1 = DirectionModel(source: oldToNewPlacemarkDirection1.destination, destination: oldToNewPlacemarkDirection1.source, routes: [MKRoute()])

        let oldToNewPlacemarkDirection2 = DirectionModel(source: HYCPlacemark(name: "old placemark 2"), destination: newPlacemark, routes: [MKRoute()])
        
        let newToOldPlacemarkDirection2 = DirectionModel(source: oldToNewPlacemarkDirection2.destination, destination: oldToNewPlacemarkDirection2.source, routes: [MKRoute()])
        
        let sut = DataManager(directionsFetcher: { source, destination, completion in
            completion(.success([MKRoute()]))
        })
        
        let exp = expectation(description: "Wait for fetch completion")
        
        sut.fetchDirections(ofNew: newPlacemark, toOld: [oldToNewPlacemarkDirection1.source, oldToNewPlacemarkDirection2.source], current: currentToNewPlacemarkDirection.source) { result in
            switch result {
            case let .success(directions):
                XCTAssertEqual(directions.count, 5)
                XCTAssertTrue(directions.contains(currentToNewPlacemarkDirection), "missing currentToNewPlacemarkDirection")
                XCTAssertTrue(directions.contains(oldToNewPlacemarkDirection1), "missing oldToNewPlacemarkDirection1")
                XCTAssertTrue(directions.contains(newToOldPlacemarkDirection1), "missing newToOldPlacemarkDirection1")
                XCTAssertTrue(directions.contains(oldToNewPlacemarkDirection2), "missing oldToNewPlacemarkDirection2")
                XCTAssertTrue(directions.contains(newToOldPlacemarkDirection2), "missing newToOldPlacemarkDirection2")
                
            case let .failure(error):
                XCTFail("Failed with error: \(error)")
            }
            
            exp.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

}
