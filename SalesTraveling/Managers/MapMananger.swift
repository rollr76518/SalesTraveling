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
	
	enum DirectResponseStatus {
		case success(MKDirectionsResponse)
		case failure(Error)
	}
	
	class func calculateDirections(from sourcePlacemark: MKPlacemark, to destinationPlacemark: MKPlacemark, completion: @escaping (_ status: DirectResponseStatus) -> ()) {
		
		let request = MKDirectionsRequest()
		request.source = sourcePlacemark.toMapItem
		request.destination = destinationPlacemark.toMapItem
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
		let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let geocoder = CLGeocoder()
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
			return MKPlacemark(coordinate: location.coordinate, addressDictionary: dic)
		}
	}
	
	class func placemarkNames(_ placemarks: [MKPlacemark]) -> String {
		let names = placemarks.reduce("") { (result, placemark) -> String in
			guard let name = placemark.name else { return result }
			var append = ""
			if placemark != placemarks.first {
				append = "->"
			}
			return result + "\(append)" + "\(name)"
		}
		
		return names
	}
	
	class func routeInfomation(_ tourModal: TourModel) -> String {
		let time = String(format: "Time".localized + ": %.2f " + "min".localized, tourModal.sumOfExpectedTravelTime/60)
		let distance = String(format: "Distance".localized + ": %.2f " + "km".localized, tourModal.distances/1000)
		
		return time  + ", " + distance
	}
	
	class func boundingMapRect(polylines: [MKPolyline]) -> MKMapRect {
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
		
		return MKMapRect(origin: MKMapPointMake(westPoint!, northPoint!), size: MKMapSizeMake(eastPoint! - westPoint!, southPoint! - northPoint!))
	}
}

extension MKPlacemark {
	var toMapItem: MKMapItem {
		let item = MKMapItem(placemark: self)
		item.name = name
		return item
	}
}
