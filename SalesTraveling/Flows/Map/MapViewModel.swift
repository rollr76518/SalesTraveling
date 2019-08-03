//
//  MapViewModel.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/19.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import Foundation
import MapKit.MKPlacemark

protocol MapViewModelDelegate {
	
	func viewModel(_ viewModel: MapViewModel, didUpdateUserPlacemark placemark: HYCPlacemark, from oldValue: HYCPlacemark?)
	func viewModel(_ viewModel: MapViewModel, didUpdatePlacemarks placemarks: [HYCPlacemark], oldValue: [HYCPlacemark])
	func viewModel(_ viewModel: MapViewModel, isFetching: Bool)
	func viewModel(_ viewModel: MapViewModel, didUpdatePolylines polylines: [MKPolyline])
	func viewModel(_ viewModel: MapViewModel, didRecevice error: Error)
	func viewModel(_ viewModel: MapViewModel, shouldShowTableView show: Bool)
}

class MapViewModel {
	
	enum PreferResult {
		case distance
		case time
	}
	
	var delegate: MapViewModelDelegate?
	
	private(set) var preferResult: PreferResult = .distance {
		didSet {
			tourModel = tourModel(preferResult: preferResult, in: tourModels)
		}
	}
	
	private(set) var tourModels: [TourModel] = [] {
		didSet {
			tourModel = tourModel(preferResult: preferResult, in: tourModels)
		}
	}
	
	private(set) var tourModel: TourModel? {
		didSet {
			guard let tourModel = tourModel else { return }
			delegate?.viewModel(self, didUpdatePolylines: tourModel.polylines)
		}
	}
	
	private(set) var placemarks: [HYCPlacemark] = [] {
		didSet {
			delegate?.viewModel(self, didUpdatePlacemarks: placemarks, oldValue: oldValue)
		}
	}
	
	private(set) var shouldShowTableView: Bool = false {
		didSet {
			delegate?.viewModel(self, shouldShowTableView: shouldShowTableView)
		}
	}
	
	private var error: Error? {
		didSet {
			guard let error = error else { return }
			delegate?.viewModel(self, didRecevice: error)
		}
	}
	
	private var deviceLocation: CLLocation? {
		didSet {
			guard let deviceLocation = deviceLocation else { return }
			
			delegate?.viewModel(self, isFetching: true)
			
			MapMananger.reverseCoordinate(deviceLocation.coordinate) { [weak self] (status) in
				guard let self = self else { return }

				self.delegate?.viewModel(self, isFetching: false)

				switch status {
				case .failure(let error):
					self.error = error
				case .success(let placemarks):
					guard let first = placemarks.first else { return }
					let placemark = HYCPlacemark(mkPlacemark: first)
					self.userPlacemark = placemark
					if ProcessInfo.processInfo.environment["is_mock_bulid_with_locations"] == "true" {
						self.addMockPlacemarks()
					}
				}
			}
		}
	}
	
	private(set) var userPlacemark: HYCPlacemark? {
		didSet {
			guard let placemark = userPlacemark else { return }
			delegate?.viewModel(self, didUpdateUserPlacemark: placemark, from: oldValue)
		}
	}
}

extension MapViewModel {
	
	func add(placemark: MKPlacemark, completion: (() -> Void)?) {
		let placemark = HYCPlacemark(mkPlacemark: placemark)

		delegate?.viewModel(self, isFetching: true)

		DataManager.shared.fetchDirections(ofNew: placemark, toOld: placemarks, current: userPlacemark) { [weak self] (status) in
			guard let self = self else { return }
			
			self.delegate?.viewModel(self, isFetching: false)
			
			switch status {
			case .failure(let error):
				self.error = error
				completion?()
			case .success(let directionModels):
				DataManager.shared.save(directions: directionModels)
				
				var placemarks = self.placemarks
				placemarks.append(placemark)
				self.placemarks = placemarks
				self.tourModels = self.showResultOfCaculate(startAt: self.userPlacemark, placemarks: placemarks)
				completion?()
			}
		}
	}
	
	func showTableView(show: Bool) {
		shouldShowTableView = show
	}
	
	func update(device location: CLLocation) {
		deviceLocation = location
	}
	
	func deletePlacemark(at index: Int) {
		placemarks.remove(at: index)
		tourModels = showResultOfCaculate(startAt: userPlacemark, placemarks: placemarks)
	}
}

// MARK: - Private method
private extension MapViewModel {
	
	func showResultOfCaculate(startAt userPlacemark: HYCPlacemark?, placemarks: [HYCPlacemark]) -> [TourModel] {
		var tourModels: [TourModel] = []
		
		//TODO: 改成比較清楚的處理流
		//只有一個點的時候不需要做排列組合的計算
		if placemarks.count == 1 {
			if let source = userPlacemark, let destination = placemarks.first {
				if let directions = DataManager.shared.findDirection(source: source.toMKPlacemark, destination: destination.toMKPlacemark) {
					var tourModel = TourModel()
					tourModel.directions.append(directions)
					tourModels.append(tourModel)
				}
			}
		} else {
			//[1, 2, 3] -> [[1, 2, 3], [1, 3, 2], [2, 3, 1], [2, 1, 3], [3, 1, 2], [3, 2, 1]]
			let permutations = AlgorithmManager.permutations(placemarks)
			
			//[[(1, 2), (2, 3)], [(1, 3), (3, 2)], [(2, 3), (3, 1)], [(2, 1), (1, 3)], [(3, 1), (1, 2)], [(3, 2), (2, 1)]]
			let tuplesCollection = permutations.map { (placemarks) -> [(HYCPlacemark, HYCPlacemark)] in
				return placemarks.toTuple()
			}
			
			for (index, tuples) in tuplesCollection.enumerated() {
				let tourModel = TourModel()
				tourModels.append(tourModel)
				
				for (nestedIndex, tuple) in tuples.enumerated() {
					//先弄起點
					if nestedIndex == 0, let userPlacemark = userPlacemark {
						let source = userPlacemark, destination = tuple.0
						if let directions = DataManager.shared.findDirection(source: source.toMKPlacemark, destination: destination.toMKPlacemark) {
							tourModels[index].directions.append(directions)
						}
					}
					//再弄中間點
					let source = tuple.0, destination = tuple.1
					if let direction = DataManager.shared.findDirection(source: source.toMKPlacemark, destination: destination.toMKPlacemark) {
						tourModels[index].directions.append(direction)
					}
				}
			}
		}
		
		return tourModels
	}
	
	func tourModel(preferResult: PreferResult, in tourModels: [TourModel]) -> TourModel? {
		switch preferResult {
		case .distance:
			return tourModels.sorted().first
		case .time:
			return tourModels.sorted(by: { (lhs, rhs) -> Bool in
				return lhs.sumOfExpectedTravelTime < rhs.sumOfExpectedTravelTime
			}).first
		}
	}
}

extension MapViewModel {
	
	func addMockPlacemarks() {
		DispatchQueue.global().async {
			let queue = OperationQueue()
			
			let placemarks = [
				MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0416801, 121.508074)), //西門町
				MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0157677, 121.5555731)), //木柵動物園
				MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0209217, 121.5750736)) //內湖好市多
			]
			
			placemarks.forEach({ (placemark) in
				let blockOperation = BlockOperation(block: { [weak self] in
					guard let self = self else { return }
					let semaphore = DispatchSemaphore(value: 0)
					DispatchQueue.main.async { [weak self] in
						self?.add(placemark: placemark, completion: {
							semaphore.signal()
						})
					}
					semaphore.wait()
				})
				queue.addOperation(blockOperation)
			})
			
			queue.waitUntilAllOperationsAreFinished()
		}
	}
}
