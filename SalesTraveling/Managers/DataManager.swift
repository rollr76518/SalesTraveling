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
}

// MARK: - Directions
extension DataManager {
	func save(directions: DirectionsModel) {
		do {
			let json = try JSONEncoder().encode(directions)
			let key = createKeyBy(source: directions.sourcePlacemark, destination: directions.destinationPlacemark)
			UserDefaults.standard.set(json, forKey: key)
		} catch {
			print("Cant save directions with \(error)")
		}
	}
	
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

// MARK: - Fetch Map with Queue
extension DataManager {
	func fetchRoutes(placemarks: [MKPlacemark], placemark: MKPlacemark, completeBlock: @escaping ([DirectionsModel])->()) {
		DispatchQueue.global().async {
		
			let queue = OperationQueue()
			queue.name = "Fetch Routes"
			
			var directionsModels = [DirectionsModel]()
			if placemarks.count == 0 {
				DispatchQueue.main.async {
					completeBlock(directionsModels)
				}
				return
			}
			

			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(directionsModels)
				}
			}
			
			for oldPlacemark in placemarks {
				for tuple in [(oldPlacemark, placemark), (placemark, oldPlacemark)] {
					let source = tuple.0
					let destination = tuple.1
					CountdownManager.shared.countTimes += 1
					
					let blockOperation = BlockOperation(block: {
						DispatchQueue.global().async {
						let semaphore = DispatchSemaphore(value: 0)
						MapMananger.calculateDirections(from: source, to: destination, completion: { (state) in
							switch state {
							case .success(let response):
								let directions = DirectionsModel(source: source, destination: destination, routes: response.routes)
								directionsModels.append(directions)
								print(directions)
								print(directionsModels)
							case .failure(let error):
								print(error)
							}
							semaphore.signal()
						})
						semaphore.wait()
						}
					})
					
					callbackFinishOperation.addDependency(blockOperation)
					queue.addOperation(blockOperation)
				}
			}
			
			queue.addOperation(callbackFinishOperation)
			queue.waitUntilAllOperationsAreFinished()
		}
	}
}

private extension DataManager {
	func createKeyBy(source: MKPlacemark, destination: MKPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
}
