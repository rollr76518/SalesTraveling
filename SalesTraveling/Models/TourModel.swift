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
	
	var hycPlacemarks: [HYCPlacemark] {
		var placemarks = directions.map{ $0.source }
		if let last = directions.last {
			placemarks.append(last.destination)
		}
		return placemarks
	}
	
	var polylines: [MKPolyline] {
		return directions.map({ (direction) -> MKPolyline in
			return direction.polyline
		})
	}
	
}

extension TourModel {
	var placemarks: [MKPlacemark] {
		var placemarks = directions.map{ $0.sourcePlacemark }
		if let last = directions.last {
			placemarks.append(last.destinationPlacemark)
		}
		return placemarks
	}
	
	var distances: CLLocationDistance {
		return directions.reduce(0, { (result, directionResponse) -> CLLocationDistance in
			return result + directionResponse.distance
		})
	}
	
	var sumOfExpectedTravelTime: TimeInterval {
		return directions.reduce(0, { (result, directionResponse) -> TimeInterval in
			return result + directionResponse.expectedTravelTime
		})
	}
	
	var routeInformation: String {
		let time = String(format: "Time".localized + ": %.2f " + "min".localized, sumOfExpectedTravelTime/60)
		let distance = String(format: "Distance".localized + ": %.2f " + "km".localized, distances/1000)
		
		return time  + ", " + distance
	}
	
	var stopInformation: String {
		let names = placemarks.reduce("") { (result, placemark) -> String in
			guard let name = placemark.name else { return result }
			var append = "->"
			if placemark.name == placemarks.first?.name {
				append = ""
			}
			return result + "\(append)" + "\(name)"
		}
		
		return names
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
