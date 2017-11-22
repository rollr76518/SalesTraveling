//
//  DirectionsModel.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/21.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

struct DirectionsModel: Codable {
	var source: HYCPlacemark
	var destination: HYCPlacemark
	var distance: CLLocationDistance
	var expectedTravelTime: TimeInterval
	
	var sourcePlacemark: MKPlacemark {
		set {
			source = HYCPlacemark.init(with: newValue)
		}
		get {
			return MKPlacemark.init(coordinate: CLLocationCoordinate2DMake(source.latitude, source.longitude), addressDictionary: source.addressDictionary.dictionary)
		}
	}
	
	var destinationPlacemark: MKPlacemark {
		set {
			destination = HYCPlacemark.init(with: newValue)
		}
		get {
			return MKPlacemark.init(coordinate: CLLocationCoordinate2DMake(destination.latitude, destination.longitude), addressDictionary: destination.addressDictionary.dictionary)
		}
	}
	
	init(source: MKPlacemark, destination: MKPlacemark, routes: [MKRoute]) {
		self.source = HYCPlacemark.init(with: source)
		self.destination = HYCPlacemark.init(with: destination)
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
	}
}

struct HYCPlacemark: Codable {
	var name: String?
	var title: String?
	var latitude: Double
	var longitude: Double
	var addressDictionary: HYCAddress
	
	init(with placemark: MKPlacemark) {
		name = placemark.name
		title = placemark.title
		latitude = placemark.coordinate.latitude
		longitude = placemark.coordinate.longitude
		addressDictionary = HYCAddress.init(with: placemark.addressDictionary! as! [String: Any])
	}
}

struct HYCAddress: Codable {
	var street: String?
	var zip: String?
	var country: String?
	var subThoroughfare: String?
	var state: String?
	var name: String?
	var subAdministratieArea: String?
	var thoroughfare: String?
	var formattedAddressLines: [String]?
	var city: String?
	var countryCode: String?
	var subLocality: String?
	
	init(with addressDictionary: [String: Any]) {
		street = addressDictionary["Street"] as? String
		zip = addressDictionary["ZIP"] as? String
		country = addressDictionary["Country"] as? String
		subThoroughfare = addressDictionary["SubThoroughfare"] as? String
		state = addressDictionary["State"] as? String
		name = addressDictionary["Name"] as? String
		subAdministratieArea = addressDictionary["SubAdministrativeArea"] as? String
		thoroughfare = addressDictionary["Thoroughfare"] as? String
		formattedAddressLines = addressDictionary["FormattedAddressLines"] as? [String]
		city = addressDictionary["City"] as? String
		countryCode = addressDictionary["CountryCode"] as? String
		subLocality = addressDictionary["SubLocality"] as? String
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
