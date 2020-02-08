//
//  MapViewModel.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/19.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import Foundation
import MapKit.MKPlacemark

protocol MapViewModelDelegate: AnyObject {
	
	func viewModel(_ viewModel: MapViewModel, didUpdateUserPlacemark placemark: HYCPlacemark, from oldValue: HYCPlacemark?)
	func viewModel(_ viewModel: MapViewModel, reload placemarks: [HYCPlacemark])
	func viewModel(_ viewModel: MapViewModel, isFetching: Bool)
	func viewModel(_ viewModel: MapViewModel, didUpdatePolylines polylines: [MKPolyline])
	func viewModel(_ viewModel: MapViewModel, didRecevice error: Error)
	func viewModel(_ viewModel: MapViewModel, shouldShowTableView show: Bool)
}

class MapViewModel {
	
	enum ViewModelError: Error, LocalizedError {
		case tourModelIsNil
		
		var errorDescription: String? {
			switch self {
			case .tourModelIsNil:
				return "There is no calculated tour can be saved.".localized
			}
		}
	}
	
	enum PreferResult: Int {
		case distance = 0
		case time = 1
	}
	
	weak var delegate: MapViewModelDelegate?
	
	private var _placemarks: [HYCPlacemark] = []
	
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
			delegate?.viewModel(self, reload: tourModel.destinations)
		}
	}
	
	var result: String? {
		return tourModel?.routeInformation
	}
	
	var placemarks: [HYCPlacemark] {
		return tourModel?.destinations ?? []
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
			
			MapMananger.reverseCoordinate(deviceLocation.coordinate) { (status) in
				self.delegate?.viewModel(self, isFetching: false)

				switch status {
				case .failure(let error):
					self.error = error
				case .success(let placemarks):
					guard let first = placemarks.first else { return }
					let placemark = HYCPlacemark(mkPlacemark: first)
					self.userPlacemark = placemark
				}
			}
		}
	}
	
	private(set) var userPlacemark: HYCPlacemark? {
		didSet {
			guard let placemark = userPlacemark else { return }
			delegate?.viewModel(self, didUpdateUserPlacemark: placemark, from: oldValue)
			
			guard placemark != oldValue else { return }
			if self._placemarks.count == 0 {
				if ProcessInfo.processInfo.environment["is_mock_bulid_with_locations"] == "true" {
					self.addMockPlacemarks()
				}
			} else {
				let tempPlacemarks = _placemarks
				_placemarks = []
				add(placemarks: tempPlacemarks) { [weak self] (result) in
					guard let self = self else { return }
					switch result {
					case .failure(let error):
						self.error = error
					case .success:
						self.delegate?.viewModel(self, didUpdateUserPlacemark: placemark, from: oldValue)
					}
				}
			}
		}
	}
}

extension MapViewModel {
	
	func add(placemark: HYCPlacemark, completion: ((Result<Void, Error>) -> Void)?) {

		delegate?.viewModel(self, isFetching: true)

		DataManager.shared.fetchDirections(ofNew: placemark, toOld: _placemarks, current: userPlacemark) { (status) in
			self.delegate?.viewModel(self, isFetching: false)
			
			switch status {
			case .failure(let error):
				completion?(.failure(error))
			case .success(let directionModels):
				DataManager.shared.save(directions: directionModels)
				
				var placemarks = self._placemarks
				placemarks.append(placemark)
				self._placemarks = placemarks
				self.tourModels = self.showResultOfCaculate(startAt: self.userPlacemark, placemarks: placemarks)
				completion?(.success(Void()))
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
		let placemark = placemarks[index]
		_placemarks.removeAll { (_placemark) -> Bool in
			return _placemark == placemark
		}
		tourModels = showResultOfCaculate(startAt: userPlacemark, placemarks: _placemarks)
	}
	
	func set(preferResult: PreferResult) {
		self.preferResult = preferResult
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
				if let directions = DataManager.shared.findDirection(source: source, destination: destination) {
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
						if let directions = DataManager.shared.findDirection(source: source, destination: destination) {
							tourModels[index].directions.append(directions)
						}
					}
					//再弄中間點
					let source = tuple.0, destination = tuple.1
					if let direction = DataManager.shared.findDirection(source: source, destination: destination) {
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
		let a = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0416801, 121.508074)))
		a.name = "西門町"
		a.title = "臺北市萬華區中華路一段"
		let b = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.0157677, 121.5555731)))
		b.name = "木柵動物園"
		b.title = "臺北市文山區新光路二段30號"
		let c = HYCPlacemark(mkPlacemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(25.063985, 121.575923)))
		c.name = "內湖好市多"
		c.title = "114台北市內湖區舊宗路一段268號"
		
		add(placemarks: [a, b, c]) { [weak self] (result) in
			switch result {
			case .failure(let error):
				self?.error = error
			case .success:
				break
			}
		}
	}
	
	func add(placemarks: [HYCPlacemark], completion: ((Result<Void, Error>) -> Void)?) {
		DispatchQueue.global().async {
			let queue = OperationQueue()
			queue.maxConcurrentOperationCount = 1
			
			placemarks.forEach({ (placemark) in
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					DispatchQueue.main.async {
						self.add(placemark: placemark, completion: { (result) in
							switch result {
							case .failure(let error):
								completion?(.failure(error))
								semaphore.signal()
								queue.cancelAllOperations()
							case .success:
								semaphore.signal()
							}
						})
					}
					semaphore.wait()
				})
				queue.addOperation(blockOperation)
			})
			
			queue.waitUntilAllOperationsAreFinished()
			DispatchQueue.main.async {
				completion?(.success(Void()))
			}
		}
	}
}

extension MapViewModel {
	
	func placemark(at coordinate: CLLocationCoordinate2D) -> HYCPlacemark? {
		return _placemarks.first { (placemark) -> Bool in
			return placemark.coordinate.latitude == coordinate.latitude &&
				placemark.coordinate.longitude == coordinate.longitude
		}
	}
	
	func addToFavorite(_ placemark: HYCPlacemark) {
		do {
			try DataManager.shared.addToFavorites(placemark: placemark)
		} catch {
			self.error = error
		}
	}
	
	func favoritePlacemarks() -> [HYCPlacemark] {
		let userCoordinate = self.userPlacemark?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
		let set = DataManager.shared.favoritePlacemarks()
		return set
			//用與目前使用者的距離來排序
			.sorted(by: { (lhs, rhs) -> Bool in
				func distance(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Double {
					return sqrt(pow((source.latitude - destination.latitude), 2) + pow((source.longitude - destination.longitude), 2))
				}
				let distanceOflhs = distance(source: lhs.coordinate, destination: userCoordinate)
				let distanceOfrhs = distance(source: rhs.coordinate, destination: userCoordinate)
				return distanceOflhs > distanceOfrhs
			})
	}
}
