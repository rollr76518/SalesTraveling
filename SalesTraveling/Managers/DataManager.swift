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
    
    typealias DirectionsFetcher = (HYCPlacemark, HYCPlacemark, @escaping (Result<[MKRoute], Error>) -> ()) -> Void

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
            
            let syncQueue = DispatchQueue(label: "Queue to sync mutation")
			
            var error: Error?
			var directionsModels = [DirectionModel]()
			let callbackFinishOperation = BlockOperation {
                DispatchQueue.main.async {
                    if let error = error {
                        completeBlock(.failure(error))
                    } else {
                        completeBlock(.success(directionsModels))
                    }
				}
			}
			
            var journeys = [(source: HYCPlacemark, destination: HYCPlacemark)]()
            
            if let userPlacemark = userPlacemark {
                journeys.append((userPlacemark, placemark))
            }
            
            for oldPlacemark in placemarks {
                journeys.append((oldPlacemark, placemark))
                journeys.append((placemark, oldPlacemark))
            }
			            
			for (source, destination) in journeys {
                let blockOperation = BlockOperation(block: {
                    let semaphore = DispatchSemaphore(value: 0)
                    self.directionsFetcher(source, destination, { (state) in
                        switch state {
                        case .failure(let destinationError):
                            syncQueue.sync {
                                error = destinationError
                            }
                            
                        case .success(let routes):
                            let directions = DirectionModel(source: source, destination: destination, routes: routes)
                            syncQueue.sync {
                                directionsModels.append(directions)
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
