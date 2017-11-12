//
//  TourModel.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

struct DirectionsModel {
    var source: MKMapItem
    var destination: MKMapItem
    var routes: [MKRoute]
}

class TourModel {
	
	var responses: [DirectionsModel] = []
	
	var placemarks: [MKPlacemark] {
        var placemarks = responses.map{ $0.source.placemark }
        if let last = responses.last {
            placemarks.append(last.destination.placemark)
        }
        return placemarks
	}
	
	var routes: [MKRoute] {
		return responses.map{ $0.routes.first! }
	}
	
	var polylines: [MKPolyline] {
		return responses.map{ ($0.routes.first?.polyline)! }
	}
	
	var boundingMapRect: MKMapRect {
		var westPoint: Double?
		var northPoint: Double?
		var eastPoint: Double?
		var southPoint: Double?
		
		for polyline in polylines {
			if let west = westPoint, let north = northPoint, let east = eastPoint, let south = southPoint {
				
				if polyline.boundingMapRect.origin.x < west {
					westPoint = polyline.boundingMapRect.origin.x
				}
				if polyline.boundingMapRect.origin.y < north {
					northPoint = polyline.boundingMapRect.origin.y
				}
				if polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width > east {
					eastPoint = polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width
				}
				if polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height > south {
					southPoint = polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height
				}
			}
			else {
				westPoint = polyline.boundingMapRect.origin.x
				northPoint = polyline.boundingMapRect.origin.y
				eastPoint = polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width
				southPoint = polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height
			}
		}
		
		return MKMapRect.init(origin: MKMapPointMake(westPoint!, northPoint!), size: MKMapSizeMake(eastPoint! - westPoint!, southPoint! - northPoint!))
		
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
