//
//  DirectionsModel.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/21.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit
import Contacts.CNPostalAddress

struct DirectionsModel: Codable {
	var source: HYCPlacemark
	var destination: HYCPlacemark
	var distance: CLLocationDistance
	var expectedTravelTime: TimeInterval
	
	var sourcePlacemark: MKPlacemark {
		set {
			source = HYCPlacemark(mkPlacemark: newValue)
		}
		get {
			let postalAddress = DirectionsModel.postalAddress(placemark: source)
			return MKPlacemark(coordinate: CLLocationCoordinate2DMake(source.latitude, source.longitude), postalAddress: postalAddress)
		}
	}
	
	var destinationPlacemark: MKPlacemark {
		set {
			destination = HYCPlacemark(mkPlacemark: newValue)
		}
		get {
			let postalAddress = DirectionsModel.postalAddress(placemark: destination)
			return MKPlacemark(coordinate: CLLocationCoordinate2DMake(destination.latitude, destination.longitude), postalAddress: postalAddress)
		}
	}
	
	init(source: MKPlacemark, destination: MKPlacemark, routes: [MKRoute]) {
		self.source = HYCPlacemark(mkPlacemark: source)
		self.destination = HYCPlacemark(mkPlacemark: destination)
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
	}
	
	init(source: HYCPlacemark, destination: HYCPlacemark, routes: [MKRoute]) {
		self.source = source
		self.destination = destination
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
	}
	
	static func postalAddress(placemark: HYCPlacemark) -> CNPostalAddress {
		let postalAddress = CNMutablePostalAddress()
		postalAddress.street = placemark.street ?? ""
		postalAddress.city = placemark.city ?? ""
		postalAddress.state = placemark.state ?? ""
		postalAddress.postalCode = placemark.postalCode ?? ""
		postalAddress.country = placemark.country ?? ""
		postalAddress.isoCountryCode = placemark.isoCountryCode ?? ""
		postalAddress.subAdministrativeArea = placemark.subAdministrativeArea ?? ""
		postalAddress.subLocality = placemark.subLocality ?? ""
		return postalAddress.copy() as! CNPostalAddress
	}
}

/*
struct HYCAddress: Codable {
	var street: String?
	var zip: String?
	var country: String?
	var subThoroughfare: String?
	var state: String?
	var name: String?
	var subAdministrativeArea: String?
	var thoroughfare: String?
	var formattedAddressLines: [String]?
	var city: String?
	var countryCode: String?
	var subLocality: String?
	
	init(dictionary: [String: Any]) {
		street = dictionary["Street"] as? String
		zip = dictionary["ZIP"] as? String
		country = dictionary["Country"] as? String
		subThoroughfare = dictionary["SubThoroughfare"] as? String
		state = dictionary["State"] as? String
		name = dictionary["Name"] as? String
		subAdministrativeArea = dictionary["SubAdministrativeArea"] as? String
		thoroughfare = dictionary["Thoroughfare"] as? String
		formattedAddressLines = dictionary["FormattedAddressLines"] as? [String]
		city = dictionary["City"] as? String
		countryCode = dictionary["CountryCode"] as? String
		subLocality = dictionary["SubLocality"] as? String
	}
	
	var dictionary: [String: Any] {
		var dic: [String: Any] = [:]
		
		if let street = street {
			dic["Street"] = street as Any
		}
		
		if let zip = zip {
			dic["ZIP"] = zip as Any
		}
		
		if let country = country {
			dic["Country"] = country as Any
		}
		
		if let subThoroughfare = subThoroughfare {
			dic["SubThoroughfare"] = subThoroughfare as Any
		}
		
		if let state = state {
			dic["State"] = state as Any
		}
		
		if let name = name {
			dic["Name"] = name as Any
		}
		
		if let subAdministratieArea = subAdministratieArea {
			dic["SubAdministrativeArea"] = subAdministratieArea as Any
		}
		
		if let thoroughfare = thoroughfare {
			dic["Thoroughfare"] = thoroughfare as Any
		}
		
		if let formattedAddressLines = formattedAddressLines {
			dic["FormattedAddressLines"] = formattedAddressLines as Any
		}
		
		if let city = city {
			dic["City"] = city as Any
		}
		
		if let countryCode = countryCode {
			dic["CountryCode"] = countryCode as Any
		}
		
		if let subLocality = subLocality {
			dic["SubLocality"] = subLocality
		}
		
		return dic
	}
}
*/

/*
class DirectionsModel2: NSObject, NSCopying {
	var source: MKPlacemark
	var destination: MKPlacemark
	var distance: CLLocationDistance
	var expectedTravelTime: TimeInterval
	
	init(source: MKPlacemark, destination: MKPlacemark, distance: CLLocationDistance, expectedTravelTime: TimeInterval) {
		self.source = source
		self.destination = destination
		self.distance = distance
		self.expectedTravelTime = expectedTravelTime
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		let copy = DirectionsModel2(source: source, destination: destination, distance: distance, expectedTravelTime: expectedTravelTime)
		return copy
	}
}
*/
