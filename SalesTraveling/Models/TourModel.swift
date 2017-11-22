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
	
}
