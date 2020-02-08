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
	
	enum LocalSearchStatus {
		case success(MKLocalSearch.Response)
		case failure(Error)
	}
	
	class func fetchLocalSearch(with keywords: String, region: MKCoordinateRegion,  completion: @escaping (_ status: LocalSearchStatus) -> ()) {
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
	
	enum ReverseGeocodeLocationStatus {
		case success([MKPlacemark])
		case failure(Error)
	}
	
	class func reverseCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (_ status: ReverseGeocodeLocationStatus) -> ())  {
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
		var westPoint: Double?
		var northPoint: Double?
		var eastPoint: Double?
		var southPoint: Double?
		
		for polyline in polylines {
			if let west = westPoint, let north = northPoint, let east = eastPoint, let south = southPoint {
				westPoint = min(west, polyline.boundingMapRect.minX)
				northPoint = min(north, polyline.boundingMapRect.minY)
				eastPoint = max(east, polyline.boundingMapRect.maxX)
				southPoint = max(south, polyline.boundingMapRect.maxY)
			}
			else {
				westPoint = polyline.boundingMapRect.minX
				northPoint = polyline.boundingMapRect.minY
				eastPoint = polyline.boundingMapRect.maxX
				southPoint = polyline.boundingMapRect.maxY
			}
		}
		
		return MKMapRect(origin: MKMapPoint(x: westPoint ?? 0, y: northPoint ?? 0),
						 size: MKMapSize(width: (eastPoint ?? 0) - (westPoint ?? 0), height: (southPoint ?? 0) - (northPoint ?? 0)))
	}
}

// MARK: - HYCPlacemark
extension MapMananger {
	
	enum DirectResponseStatus {
		case success(MKDirections.Response)
		case failure(Error)
	}
	
	class func calculateDirections(from source: HYCPlacemark, to destination: HYCPlacemark, completion: @escaping (_ status: DirectResponseStatus) -> ()) {
		
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
