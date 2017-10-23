//
//  TourModel.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

class TourModel {
	
	var responses: [MKDirectionsResponse] = []
	
	var placemarks: [MKPlacemark] {
		return responses.map{ $0.source.placemark }
	}
	
	var routes: [MKRoute] {
		return responses.map{ $0.routes.first! }
	}
	
	var polylines: [MKPolyline] {
		return responses.map{ ($0.routes.first?.polyline)! }
	}
	
	var distances: CLLocationDistance {
		return responses.reduce(0, { (result, directionResponse) -> CLLocationDistance in
			return result + (directionResponse.routes.first?.distance)!
		})
	}
	
	var sumOfExpectedTravelTime: TimeInterval {
		return responses.reduce(0, { (result, directionResponse) -> TimeInterval in
			return result + (directionResponse.routes.first?.expectedTravelTime)!
		})
	}
	
}
