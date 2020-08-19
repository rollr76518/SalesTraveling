//
//  DataManager.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/26.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import Foundation
import MapKit

class DataManager {
    static let shared = DataManager()

    typealias DirectionsFetcher = (HYCPlacemark, HYCPlacemark, @escaping (Result<[MKRoute], Error>) -> Void) -> Void
    
    private let directionsFetcher: DirectionsFetcher
    
    init(directionsFetcher: @escaping DirectionsFetcher = MapMananger.calculateDirections) {
        self.directionsFetcher = directionsFetcher
    }
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
	
	func findDirection(source: HYCPlacemark, destination: HYCPlacemark) -> DirectionModel? {
		let key = createKeyBy(source: source, destination: destination)
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let direction = try? JSONDecoder().decode(DirectionModel.self, from: data) else { return nil }
		return direction
	}
}

// MARK: - HYCPlacemark
extension DataManager {

	private func createKeyBy(source: HYCPlacemark, destination: HYCPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
	
	func fetchDirections(ofNew placemark: HYCPlacemark, toOld placemarks: [HYCPlacemark], current userPlacemark: HYCPlacemark?, completeBlock: @escaping (Result<[DirectionModel], Error>)->()) {
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
                    self.directionsFetcher(userPlacemark, placemark, { (status) in
						switch status {
						case .success(let routes):
							let directions = DirectionModel(source: source, destination: destination, routes: routes)
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
                        self.directionsFetcher(source, destination, { (state) in
							switch state {
							case .failure(let error):
								completeBlock(.failure(error))
							case .success(let routes):
								let directions = DirectionModel(source: source, destination: destination, routes: routes)
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

// MARK: - Favorite placemark
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
			let key = UserDefaults.Keys.FavoritePlacemarks
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			throw error
		}
	}
	
	func favoritePlacemarks() -> Set<HYCPlacemark> {
		let key = UserDefaults.Keys.FavoritePlacemarks
		guard
			let data = UserDefaults.standard.object(forKey: key) as? Data,
			let placemarks = try? JSONDecoder().decode(Set<HYCPlacemark>.self, from: data)
			else {
				return Set<HYCPlacemark>()
		}
		return placemarks
	}
}
