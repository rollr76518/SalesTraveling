//
//  MapMananger.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

class MapMananger {
	
	enum LocalSearchStatus {
		case success(MKLocalSearchResponse)
		case failure(Error)
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
	
	enum DirectResponseStatus {
		case success(MKDirectionsResponse)
		case failure(Error)
	}
	
	class func calculateDirections(from begin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (_ status: DirectResponseStatus) -> ()) {
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
	
	class func pointAnnotation(mapItem: MKMapItem) -> MKPointAnnotation {
		return pointAnnotation(placemark: mapItem.placemark)
	}
	
	class func pointAnnotation(placemark: MKPlacemark) -> MKPointAnnotation {
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		annotation.subtitle = placemark.title
		return annotation
	}
	
	class func addPolyline(_ mapView: MKMapView, route: MKRoute) {
		mapView.add(route.polyline, level: .aboveRoads)
		let rect = route.polyline.boundingMapRect
		mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
	}
	
	class func showRegion(_ mapView: MKMapView, spanDegrees: Double,  coordinate: CLLocationCoordinate2D) {
		let span = MKCoordinateSpanMake(spanDegrees, spanDegrees)
		let region = MKCoordinateRegionMake(coordinate, span)
		mapView.setRegion(region, animated: true)
	}
	
	enum ReverseGeocodeLocationStatus {
		case success([MKPlacemark])
		case failure(Error)
	}
	
	class func reverseCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (_ status: ReverseGeocodeLocationStatus) -> ())  {
		let location = CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let geocoder = CLGeocoder.init()
		geocoder.reverseGeocodeLocation(location) { (clPlacemarks, error) in
			if let clPlacemarks = clPlacemarks {
				completion(.success(transfer(clPlacemarks: clPlacemarks)))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
	
	class func transfer(clPlacemarks: [CLPlacemark]) -> [MKPlacemark] {
		return clPlacemarks.map { (clPlacemark) -> MKPlacemark in
			let location = clPlacemark.location!
			let dic = clPlacemark.addressDictionary as! [String: Any]
			return MKPlacemark.init(coordinate: location.coordinate, addressDictionary: dic)
		}
	}
	
	class func placemarkNames(_ placemarks: [MKPlacemark]) -> String {
		let names = placemarks.reduce("") { (result, placemark) -> String in
			return result + "\(placemark.name!) ->"
		}
		
		return names
	}
	
	class func routeInfomation(_ tourModal: TourModel) -> String {
		let time = String.init(format: "Time: %2f min", tourModal.sumOfExpectedTravelTime/60)
		let distance = String.init(format: "Distance: %2f km", tourModal.distances/1000)
		
		return time  + ", " + distance
	}
}
