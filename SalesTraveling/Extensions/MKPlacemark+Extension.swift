//
//  MKPlacemark+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/25.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

extension MKPlacemark {
	var toMapItem: MKMapItem {
		let item = MKMapItem(placemark: self)
		item.name = name
		return item
	}
	
	var pointAnnotation: MKPointAnnotation {
		let annotation = MKPointAnnotation()
		annotation.coordinate = coordinate
		annotation.title = name
		annotation.subtitle = title
		return annotation
	}
}
