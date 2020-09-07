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
	var coordinate: CLLocationCoordinate2D
	
	// PostalAddress properties
	var street: String?
	var city: String?
	var state: String?
	
	// address dictionary properties
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
		coordinate = mkPlacemark.coordinate
		street = mkPlacemark.postalAddress?.street
		city = mkPlacemark.postalAddress?.city
		state = mkPlacemark.postalAddress?.state
		postalCode = mkPlacemark.postalAddress?.postalCode
		country = mkPlacemark.postalAddress?.country
		isoCountryCode = mkPlacemark.postalAddress?.isoCountryCode
		subAdministrativeArea = mkPlacemark.postalAddress?.subAdministrativeArea
		subLocality = mkPlacemark.postalAddress?.subLocality
	}
	
    internal init(title: String? = nil, subtitle: String? = nil, coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0), street: String? = nil, city: String? = nil, state: String? = nil, name: String? = nil, thoroughfare: String? = nil, subThoroughfare: String? = nil, locality: String? = nil, subLocality: String? = nil, administrativeArea: String? = nil, subAdministrativeArea: String? = nil, postalCode: String? = nil, isoCountryCode: String? = nil, country: String? = nil, inlandWater: String? = nil, ocean: String? = nil, areasOfInterest: [String]? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.street = street
        self.city = city
        self.state = state
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.isoCountryCode = isoCountryCode
        self.country = country
        self.inlandWater = inlandWater
        self.ocean = ocean
        self.areasOfInterest = areasOfInterest
    }
    
	// NSObject 的 == 要 override 這個 method
	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? HYCPlacemark {
			return coordinate.latitude == other.coordinate.latitude && coordinate.longitude == other.coordinate.longitude
		} else {
			return false
		}
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
		return MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
	}
	
	var toMapItem: MKMapItem {
		let item = MKMapItem(placemark: toMKPlacemark)
		item.name = name
		return item
	}
}

extension HYCPlacemark {
    
    override var description: String {
    
        return """
        name: \(String(describing: name))
        """
        
    }
    
}
