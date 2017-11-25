//
//  DataManager.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/26.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import Foundation
import MapKit.MKPlacemark

class DataManager {
	
	static let shared = DataManager()
	
	func saveDirections(source: MKPlacemark, destination: MKPlacemark, routes: [MKRoute]) {
		let directions = DirectionsModel(source: source, destination: destination, routes: routes)
		let json = try! JSONEncoder().encode(directions)
		let key = createKeyBy(source: source, destination: destination)
		UserDefaults.standard.set(json, forKey: key)
	}
	
	func findDirections(source: MKPlacemark, destination: MKPlacemark) -> DirectionsModel? {
		let key = createKeyBy(source: source, destination: destination)
		guard let json = UserDefaults.standard.object(forKey: key) as? Data ,
			let directions = try? JSONDecoder().decode(DirectionsModel.self, from: json) else { return nil }
		return directions
	}
}

fileprivate extension DataManager {
	func createKeyBy(source: MKPlacemark, destination: MKPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
}
