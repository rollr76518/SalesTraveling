//
//  MapMananger.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

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
}
