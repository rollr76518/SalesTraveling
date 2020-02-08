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

// MARK: - Direction
extension DataManager {
	
	func save(direction: DirectionModel) {
		do {
			let data = try JSONEncoder().encode(direction)
			let key = createKeyBy(source: direction.source, destination: direction.destination)
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			print("Cant save direction with \(error)")
		}
	}

	func save(directions: [DirectionModel]) {
		for directionModel in directions {
			save(direction: directionModel)
		}
	}
	
	func findDirection(source: MKPlacemark, destination: MKPlacemark) -> DirectionModel? {
		let key = createKeyBy(source: source, destination: destination)
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let direction = try? JSONDecoder().decode(DirectionModel.self, from: data) else { return nil }
		return direction
	}
}

extension DataManager {
	
	func saveDefaultMapCenter(point: CLLocationCoordinate2D) {
		do {
			let data = try JSONEncoder().encode(point)
			let key = UserDefaults.Keys.DefaultMapCenter
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			print("Cant save default map center with \(error)")
		}
	}
	
	func defaultMapCenter() -> CLLocationCoordinate2D {
		let key = UserDefaults.Keys.DefaultMapCenter
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let point = try? JSONDecoder().decode(CLLocationCoordinate2D.self, from: data) else {
				let locationOfTaipei101 = CLLocationCoordinate2D(latitude: 25.034175, longitude: 121.564488)
				return locationOfTaipei101
		}
		return point
	}
}

// MARK: - Fetch Diretcions with Queue
extension DataManager {
	
	enum FetchDirectionStatus {
		case success([DirectionModel])
		case failure(Error)
	}
	
	func fetchDirection(ofNew placemark: MKPlacemark, toOld placemarks: [MKPlacemark], completeBlock: @escaping (FetchDirectionStatus)->()) {
		DispatchQueue.global().async {
		
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionModels = [DirectionModel]()

			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(directionModels))
				}
			}
			
			for oldPlacemark in placemarks {
				let source = placemark
				let destination = oldPlacemark
				
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					MapMananger.calculateDirection(from: source, to: destination, completion: { (state) in
						switch state {
						case .failure(let error):
							completeBlock(.failure(error))
						case .success(let response):
							let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
							directionModels.append(directions)
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
			
			var directionModels = [DirectionModel]()
			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(directionModels))
				}
			}
			
			if let userPlacemark = userPlacemark {
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					let source = userPlacemark
					let destination = placemark
					MapMananger.calculateDirection(from: userPlacemark, to: placemark, completion: { (status) in
						switch status {
						case .success(let response):
							let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
							directionModels.append(directions)
						case .failure(let error):
							completeBlock(.failure(error))
						}
						semaphore.signal()
					})
					semaphore.wait()
				})
				callbackFinishOperation.addDependency(blockOperation)
				queue.addOperation(blockOperation)
			}
			
			for oldPlacemark in placemarks {
				for tuple in [(oldPlacemark, placemark), (placemark, oldPlacemark)] {
					let source = tuple.0
					let destination = tuple.1
					
					let blockOperation = BlockOperation(block: {
						let semaphore = DispatchSemaphore(value: 0)
						MapMananger.calculateDirection(from: source, to: destination, completion: { (state) in
							switch state {
							case .failure(let error):
								completeBlock(.failure(error))
							case .success(let response):
								let direction = DirectionModel(source: source, destination: destination, routes: response.routes)
								directionModels.append(direction)
							}
							semaphore.signal()
						})
						semaphore.wait()
					})
					
					callbackFinishOperation.addDependency(blockOperation)
					queue.addOperation(blockOperation)
				}
			}
			queue.addOperation(callbackFinishOperation)
			queue.waitUntilAllOperationsAreFinished()
		}
	}
	
	enum FetchRouteStatus {
		case success([MKRoute])
		case failure(Error)
	}
	
	func fetchRoutes(placemarks: [MKPlacemark], completeBlock: @escaping (FetchRouteStatus)->()) {
		DispatchQueue.global().async {
			
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var routes = [MKRoute]()
			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(routes))
				}
			}
			
			let tuples = placemarks.toTuple()
			
			for tuple in tuples {
				let source = tuple.0
				let destination = tuple.1
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					MapMananger.calculateDirection(from: source, to: destination, completion: { (status) in
						switch status {
						case .failure(let error):
							completeBlock(.failure(error))
						case .success(let response):
							if let route = response.routes.first {
								routes.append(route)
							}
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
}

private extension DataManager {
	
	func createKeyBy(source: MKPlacemark, destination: MKPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
}

// MARK: - HYCPlacemark
extension DataManager {

	private func createKeyBy(source: HYCPlacemark, destination: HYCPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
	
	func fetchDirections(ofNew placemark: HYCPlacemark, toOld placemarks: [HYCPlacemark], current userPlacemark: HYCPlacemark?, completeBlock: @escaping (FetchDirectionStatus)->()) {
		DispatchQueue.global().async {
			
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionsModels = [DirectionModel]()
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
							let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
							directionsModels.append(directions)
						case .failure(let error):
							completeBlock(.failure(error))
						}
						semaphore.signal()
					})
					semaphore.wait()
				})
				callbackFinishOperation.addDependency(blockOperation)
				queue.addOperation(blockOperation)
			}
			
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
								let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
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
			queue.addOperation(callbackFinishOperation)
			queue.waitUntilAllOperationsAreFinished()
		}
	}
}

//Favorite placemark
extension DataManager {
	
	func addToFavorites(placemark: HYCPlacemark) throws {
		do {
			try addToFavorites(placemarks: [placemark])
		} catch {
			throw error
		}
	}
	
	func addToFavorites(placemarks: [HYCPlacemark]) throws {
		var favorites = favoritePlacemarks()
		placemarks.forEach { (placemark) in
			favorites.insert(placemark)
		}
		do {
			let data = try JSONEncoder().encode(favorites)
			let key = UserDefaults.Keys.favoritePlacemarks
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			throw error
		}
	}
	
	func favoritePlacemarks() -> Set<HYCPlacemark> {
		let key = UserDefaults.Keys.favoritePlacemarks
		guard
			let data = UserDefaults.standard.object(forKey: key) as? Data,
			let placemarks = try? JSONDecoder().decode(Set<HYCPlacemark>.self, from: data)
			else {
				return Set<HYCPlacemark>()
		}
		return placemarks
	}
}
