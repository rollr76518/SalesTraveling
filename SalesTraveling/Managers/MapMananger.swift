//
//  MapMananger.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

enum LocalSearchStatus {
	case success(MKLocalSearchResponse)
	case failure(Error)
}

enum DirectResponseStatus {
	case success(MKDirectionsResponse)
	case failure(Error)
}

class MapMananger {
	class func parseAddress(placemark: MKPlacemark) -> String {
		let addressLine = String (
			format:"%@%@%@%@",
			// state
			placemark.administrativeArea ?? "",
			// city
			placemark.locality ?? "",
			// street name
			placemark.thoroughfare ?? "",
			// street number
			(placemark.subThoroughfare != nil) ? String.init(format: "%@號", placemark.subThoroughfare!):""
		)
		return addressLine
	}

	class func fetchLocalSearch(with keywords: String, region: MKCoordinateRegion,  completion: @escaping (_ status: LocalSearchStatus) -> ()) {
		let request = MKLocalSearchRequest()
		request.naturalLanguageQuery = keywords
		request.region = region
		
		let search = MKLocalSearch.init(request: request)
		search.start { (response, error) in
			if let response = response {
				completion(.success(response))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
	
	class func showRoute(from begin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (_ status: DirectResponseStatus) -> ()) {
		let beginMark = MKPlacemark.init(coordinate: begin, addressDictionary: nil)
		let destinationMark = MKPlacemark.init(coordinate: destination, addressDictionary: nil)
		
		let beginItem = MKMapItem.init(placemark: beginMark)
		let destinationItem = MKMapItem.init(placemark: destinationMark)
		
		let request = MKDirectionsRequest.init()
		request.source = beginItem
		request.destination = destinationItem
		request.transportType = .automobile
		
		let directions = MKDirections.init(request: request)
		directions.calculate { (response, error) in
			if let response = response {
				completion(.success(response))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
	
	class func pointAnnotation(placemark: MKPlacemark) -> MKPointAnnotation {
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		annotation.subtitle = parseAddress(placemark: placemark)
		return annotation
	}
}
