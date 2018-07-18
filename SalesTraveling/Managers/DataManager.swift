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
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let directions = try? JSONDecoder().decode(DirectionsModel.self, from: data) else { return nil }
		return directions
	}
}

// MARK: - TourModel
extension DataManager {
	func save(tourModel: TourModel) throws {
		var favoriteTours = self.savedTours()
		favoriteTours.append(tourModel)
		do {
			let data = try JSONEncoder().encode(favoriteTours)
			let key = UserDefaults.Keys.SavedTours
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			throw error
		}
	}
	
	func save(tourModels: [TourModel]) throws {
		do {
			for tourModel in tourModels {
				try save(tourModel: tourModel)
			}
		} catch {
			throw error
		}
	}
	
	func delete(tourModel: TourModel) {
		let newTours = self.savedTours().filter { (oldTourModel) -> Bool in
			return oldTourModel != tourModel
		}
		do {
			let data = try JSONEncoder().encode(newTours)
			let key = UserDefaults.Keys.SavedTours
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			print("Cant delete tourModel with \(error)")
		}
	}
	
	func savedTours() -> [TourModel] {
		let key = UserDefaults.Keys.SavedTours
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let tourModels = try? JSONDecoder().decode([TourModel].self, from: data) else { return [TourModel]() }
		return tourModels
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
		case success([DirectionsModel])
		case failure(Error)
	}
	
	func fetchDirections(ofNew placemark: MKPlacemark, toOld placemarks: [MKPlacemark], completeBlock: @escaping (FetchDirectionStatus)->()) {
		DispatchQueue.global().async {
		
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionsModels = [DirectionsModel]()

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
					MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
						switch status {
						case .failure(let error): 								completeBlock(.failure(error))
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
