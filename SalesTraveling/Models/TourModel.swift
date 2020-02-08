//
//  TourModel.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit.MKPlacemark

struct TourModel: Codable {
	
	var directions: [DirectionModel] = []
}

extension TourModel {
	
	var destinations: [HYCPlacemark] {
		return directions.map{ $0.destination }
	}
	
	var polylines: [MKPolyline] {
		return directions.map{ $0.polyline }
	}
}

extension TourModel {
	
	var distances: CLLocationDistance {
		return directions.map{ $0.distance }.reduce(0, +)
	}
	
	var sumOfExpectedTravelTime: TimeInterval {
		return directions.map{ $0.expectedTravelTime }.reduce(0, +)
	}
	
	var routeInformation: String {
		let distance = String(format: "Distance".localized + ": %.2f " + "km".localized, distances/1000)
		let time = String(format: "Time".localized + ": %.2f " + "min".localized, sumOfExpectedTravelTime/60)
		
		return distance + ", " + time
	}
}

extension TourModel: Comparable {
	
	static func <(lhs: TourModel, rhs: TourModel) -> Bool {
		return lhs.distances < rhs.distances
	}

	static func ==(lhs: TourModel, rhs: TourModel) -> Bool {
		return lhs.distances == rhs.distances
	}
}

extension TourModel: Hashable {
	
	func hash(into hasher: inout Hasher) {
		polylines.forEach { (polyline) in
			let coordinate = polyline.coordinate
			hasher.combine("\(coordinate.latitude)" + "+" + "\(coordinate.longitude)")
		}
	}
}
