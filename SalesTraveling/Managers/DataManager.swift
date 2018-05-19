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
	func save(direction: DirectionsModel) {
		do {
			let data = try JSONEncoder().encode(direction)
			let key = createKeyBy(source: direction.sourcePlacemark, destination: direction.destinationPlacemark)
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			print("Cant save directions with \(error)")
		}
	}

	func save(directions: [DirectionsModel]) {
		for directionModel in directions {
			save(direction: directionModel)
		}
	}
	
	func findDirections(source: MKPlacemark, destination: MKPlacemark) -> DirectionsModel? {
		let key = createKeyBy(source: source, destination: destination)
		guard let data = UserDefaults.standard.object(forKey: key) as? Data ,
			let directions = try? JSONDecoder().decode(DirectionsModel.self, from: data) else { return nil }
		return directions
	}
}

// MARK: - Fetch Diretcions with Queue
extension DataManager {
	enum FetchDirectionStatus {
		case success([DirectionsModel])
		case failure(Error)
	}
	
	func fetchDirections(ofNew placemark: MKPlacemark, toOld placemarks: [MKPlacemark], completeBlock: @escaping (FetchDirectionStatus)->()) {
		DispatchQueue.global().async {
		
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionsModels = [DirectionsModel]()
			if placemarks.count == 0 {
				DispatchQueue.main.async {
					completeBlock(.success(directionsModels))
				}
				return
			}
			

			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(directionsModels))
				}
			}
			
			for oldPlacemark in placemarks {
				let source = placemark
				let destination = oldPlacemark
				
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					MapMananger.calculateDirections(from: source, to: destination, completion: { (state) in
						switch state {
						case .failure(let error):
							completeBlock(.failure(error))
						case .success(let response):
							let directions = DirectionsModel(source: source, destination: destination, routes: response.routes)
							directionsModels.append(directions)
						}
						semaphore.signal()
					})
					semaphore.wait()
				})
				
				callbackFinishOperation.addDependency(blockOperation)
				queue.addOperation(blockOperation)
			}
			
			queue.addOperation(callbackFinishOperation)
			queue.waitUntilAllOperationsAreFinished()
		}
	}
	
	
	func fetchDirections(ofNew placemark: MKPlacemark, toOld placemarks: [MKPlacemark], current userPlacemark: MKPlacemark?, completeBlock: @escaping (FetchDirectionStatus)->()) {
		DispatchQueue.global().async {
			
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionsModels = [DirectionsModel]()
			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(directionsModels))
				}
			}
			
			if let userPlacemark = userPlacemark {
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					let source = userPlacemark
					let destination = placemark
					MapMananger.calculateDirections(from: userPlacemark, to: placemark, completion: { (status) in
						switch status {
						case .success(let response):
							let directions = DirectionsModel(source: source, destination: destination, routes: response.routes)
							directionsModels.append(directions)
							break
						case .failure(let error):
							completeBlock(.failure(error))
							break
						}
						semaphore.signal()
					})
					semaphore.wait()
				})
				callbackFinishOperation.addDependency(blockOperation)
				queue.addOperation(blockOperation)
			}
			
			
			if placemarks.count != 0 {
				for oldPlacemark in placemarks {
					for tuple in [(oldPlacemark, placemark), (placemark, oldPlacemark)] {
						let source = tuple.0
						let destination = tuple.1
						
						let blockOperation = BlockOperation(block: {
							let semaphore = DispatchSemaphore(value: 0)
							MapMananger.calculateDirections(from: source, to: destination, completion: { (state) in
								switch state {
								case .failure(let error):
									completeBlock(.failure(error))
								case .success(let response):
									let directions = DirectionsModel(source: source, destination: destination, routes: response.routes)
									directionsModels.append(directions)
								}
								semaphore.signal()
							})
							semaphore.wait()
						})
						
						callbackFinishOperation.addDependency(blockOperation)
						queue.addOperation(blockOperation)
					}
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
