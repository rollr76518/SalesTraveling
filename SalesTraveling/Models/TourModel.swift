//
//  TourModel.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

class TourModel {
	
	var responses: [DirectionsModel] = []
	
	var placemarks: [MKPlacemark] {
        var placemarks = responses.map{ $0.sourcePlacemark }
        if let last = responses.last {
            placemarks.append(last.destinationPlacemark)
        }
        return placemarks
	}
	
	var distances: CLLocationDistance {
		return responses.reduce(0, { (result, directionResponse) -> CLLocationDistance in
			return result + directionResponse.distance
		})
	}

	var sumOfExpectedTravelTime: TimeInterval {
		return responses.reduce(0, { (result, directionResponse) -> TimeInterval in
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
