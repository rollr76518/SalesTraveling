//
//  HYCPlacemark.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/15.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import MapKit.MKPlacemark

class HYCPlacemark: NSObject, Codable {
	var title: String?
	var subtitle: String?
	var latitude: Double
	var longitude: Double
	
	var street: String?
	var city: String?
	var state: String?
	
	var name: String?
	var thoroughfare: String?
	var subThoroughfare: String?
	var locality: String?
	var subLocality: String?
	var administrativeArea: String?
	var subAdministrativeArea: String?
	var postalCode: String?
	var isoCountryCode: String?
	var country: String?
	var inlandWater: String?
	var ocean: String?
	var areasOfInterest: [String]?
	
	init(mkPlacemark: MKPlacemark) {
		name = mkPlacemark.name
		title = mkPlacemark.title
		if mkPlacemark.responds(to: #selector(getter: MKAnnotation.subtitle)) {
			subtitle = mkPlacemark.subtitle
		}
		latitude = mkPlacemark.coordinate.latitude
		longitude = mkPlacemark.coordinate.longitude
		street = mkPlacemark.postalAddress?.street
		city = mkPlacemark.postalAddress?.city
		state = mkPlacemark.postalAddress?.state
		postalCode = mkPlacemark.postalAddress?.postalCode
		country = mkPlacemark.postalAddress?.country
		isoCountryCode = mkPlacemark.postalAddress?.isoCountryCode
		subAdministrativeArea = mkPlacemark.postalAddress?.subAdministrativeArea
		subLocality = mkPlacemark.postalAddress?.subLocality
	}
	
	// NSObject 的 == 要 override 這個 method
	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? HYCPlacemark {
			return self.latitude == other.latitude && self.longitude == other.longitude
		} else {
			return false
		}
	}
}

extension HYCPlacemark {
	
	var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2DMake(latitude, longitude)
	}
}

extension HYCPlacemark {
	
	var toMKPlacemark: MKPlacemark {
		var addressDictionary: [String : Any] = [:]
		addressDictionary["name"] = name
		addressDictionary["thoroughfare"] = thoroughfare
		addressDictionary["locality"] = locality
		addressDictionary["subLocality"] = subLocality
		addressDictionary["administrativeArea"] = administrativeArea
		addressDictionary["subAdministrativeArea"] = subAdministrativeArea
		addressDictionary["postalCode"] = postalCode
		addressDictionary["isoCountryCode"] = isoCountryCode
		addressDictionary["country"] = country
		addressDictionary["inlandWater"] = inlandWater
		addressDictionary["ocean"] = ocean
		addressDictionary["areasOfInterest"] = areasOfInterest
		
		return MKPlacemark(coordinate: CLLocationCoordinate2DMake(latitude, longitude), addressDictionary: addressDictionary)
	}
	
	var toMapItem: MKMapItem {
		let item = MKMapItem(placemark: self.toMKPlacemark)
		item.name = name
		return item
	}
}

extension HYCPlacemark {
	
	override var description: String {
		return """
		
		name: \(String(describing: name))
		title: \(String(describing: title))
		subtitle: \(String(describing: subtitle))
		latitude: \(latitude)
		longitude: \(longitude)
		
		"""
	}
}
