//
//  HYCAnntation.swift
//  SalesTraveling
//
//  Created by Ryan on 2020/2/7.
//  Copyright © 2020 Hanyu. All rights reserved.
//

import MapKit.MKAnnotation

class HYCAnntation: NSObject {
	
	private let placemark: HYCPlacemark
	let sorted: Int
	
	init(placemark: HYCPlacemark, sorted: Int) {
		self.placemark = placemark
		self.sorted = sorted
	}
}

extension HYCAnntation: MKAnnotation {
	
	var coordinate: CLLocationCoordinate2D {
		return placemark.coordinate
	}

	var title: String? {
		return placemark.name
	}

    var subtitle: String? {
		return placemark.title
	}
}
