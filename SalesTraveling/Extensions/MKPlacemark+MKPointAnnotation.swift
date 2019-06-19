//
//  MKPlacemark+MKPointAnnotation.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/19.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import MapKit

extension MKPlacemark {
	
	var pointAnnotation: MKPointAnnotation {
		let annotation = MKPointAnnotation()
		annotation.coordinate = coordinate
		annotation.title = name
		annotation.subtitle = title
		return annotation
	}
}
