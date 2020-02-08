//
//  MapMananger.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

class MapMananger { }

extension MapMananger {
	
	class func fetchLocalSearch(with keywords: String, region: MKCoordinateRegion,  completion: @escaping (_ result: Result<MKLocalSearch.Response, Error>) -> ()) {
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = keywords
		request.region = region
		
		let search = MKLocalSearch(request: request)
		search.start { (response, error) in
			if let response = response {
				completion(.success(response))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
}

extension MapMananger {
	
	class func reverseCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (_ result: Result<[MKPlacemark], Error>) -> ())  {
		let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location) { (clPlacemarks, error) in
			if let clPlacemarks = clPlacemarks {
				let placemarks = clPlacemarks.map { (clPlacemark) -> MKPlacemark in
					return MKPlacemark(placemark: clPlacemark)
				}
				completion(.success(placemarks))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
}

extension MapMananger {
	
	class func boundingMapRect(polylines: [MKPolyline]) -> MKMapRect {
		let westPoint = polylines.lazy.map{ $0.boundingMapRect.minX }.min() ?? 0
		let northPoint = polylines.lazy.map{ $0.boundingMapRect.minY }.min() ?? 0
		let eastPoint = polylines.lazy.map{ $0.boundingMapRect.maxX }.max() ?? 0
		let southPoint = polylines.lazy.map{ $0.boundingMapRect.maxY }.max() ?? 0
		
		let origin = MKMapPoint(x: westPoint, y: northPoint)
		let size = MKMapSize(width: eastPoint - westPoint, height: southPoint - northPoint)
		return MKMapRect(origin: origin, size: size)
	}
}

// MARK: - HYCPlacemark
extension MapMananger {
	
	class func calculateDirections(from source: HYCPlacemark, to destination: HYCPlacemark, completion: @escaping (_ result: Result<MKDirections.Response, Error>) -> ()) {
		let request = MKDirections.Request()
		request.source = source.toMapItem
		request.destination = destination.toMapItem
		request.transportType = .automobile
		
		let directions = MKDirections(request: request)
		directions.calculate { (response, error) in
			if let response = response {
				completion(.success(response))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}

}
