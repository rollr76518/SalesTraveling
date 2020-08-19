//
//  DirectionModel.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/21.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import MapKit

struct DirectionModel: Codable, Equatable {
	
	let source: HYCPlacemark
	let destination: HYCPlacemark
	let distance: CLLocationDistance
	let expectedTravelTime: TimeInterval
	let polylineData: Data
	var polyline: MKPolyline {
		let buf = UnsafeMutableBufferPointer<MKMapPoint>.allocate(capacity: polylineData.count / MemoryLayout<MKMapPoint>.size)
		let _ = polylineData.copyBytes(to: buf)
		return MKPolyline(points: buf.baseAddress!, count: buf.count)
	}
	
	var sourcePlacemark: MKPlacemark {
		get {
			let postalAddress = source.toPostalAddress
			return MKPlacemark(coordinate: source.coordinate, postalAddress: postalAddress)
		}
	}
	
	var destinationPlacemark: MKPlacemark {
		get {
			let postalAddress = destination.toPostalAddress
			return MKPlacemark(coordinate: destination.coordinate, postalAddress: postalAddress)
		}
	}
	
	init(source: MKPlacemark, destination: MKPlacemark, routes: [MKRoute]) {
		self.source = HYCPlacemark(mkPlacemark: source)
		self.destination = HYCPlacemark(mkPlacemark: destination)
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
		let polyline = routes.first!.polyline
		self.polylineData = Data(buffer: UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
	}
	
	init(source: HYCPlacemark, destination: HYCPlacemark, routes: [MKRoute]) {
		self.source = source
		self.destination = destination
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
		let polyline = routes.first!.polyline
		self.polylineData = Data(buffer: UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
	}
	
}
