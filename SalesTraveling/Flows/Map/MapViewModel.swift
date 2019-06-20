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
	
	func viewModel(_ viewModel: MapViewModel, didUpdatePlacemarks placemarks: [HYCPlacemark])
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
			placemarks = tourModel.hycPlacemarks
			delegate?.viewModel(self, didUpdatePolylines: tourModel.polylines)
		}
	}
	
	private(set) var placemarks: [HYCPlacemark] = [] {
		didSet {
			delegate?.viewModel(self, didUpdatePlacemarks: placemarks)
		}
	}
	
	private(set) var shouldShowTableView: Bool = false {
		didSet {
			delegate?.viewModel(self, shouldShowTableView: shouldShowTableView)
		}
	}
}

extension MapViewModel {
	
	func add(placemark: MKPlacemark) {
		let placemark = HYCPlacemark(mkPlacemark: placemark)

		if placemarks.isEmpty {
			placemarks = [placemark]
		} else {
			delegate?.viewModel(self, isFetching: true)
			DataManager.shared.fetchDirections(ofNew: placemark, toOld: placemarks, current: nil) { [weak self] (status) in
				guard let self = self else { return }
				
				self.delegate?.viewModel(self, isFetching: false)

				switch status {
				case .failure(let error):
					self.delegate?.viewModel(self, didRecevice: error)
				case .success(let directionModels):
					DataManager.shared.save(directions: directionModels)
					
					var placemarks = self.placemarks
					placemarks.append(placemark)
					self.tourModels = self.showResultOfCaculate(placemarks: placemarks)
				}
			}
		}
	}
	
	func showTableView(show: Bool) {
		shouldShowTableView = show
	}
}

// MARK: - Private method
private extension MapViewModel {
	
	func showResultOfCaculate(placemarks: [HYCPlacemark]) -> [TourModel] {
		var tourModels: [TourModel] = []
		
		let permutations = AlgorithmManager.permutations(placemarks)
		//[1, 2, 3] -> [[1, 2, 3], [1, 3, 2], [2, 3, 1], [2, 1, 3], [3, 1, 2], [3, 2, 1]]
		
		let tuplesCollection = permutations.map { (placemarks) -> [(HYCPlacemark, HYCPlacemark)] in
			return placemarks.toTuple()
		}
		//[[(1, 2), (2, 3)], [(1, 3), (3, 2)], [(2, 3), (3, 1)], [(2, 1), (1, 3)], [(3, 1), (1, 2)], [(3, 2), (2, 1)]]
		
		for (index, tuples) in tuplesCollection.enumerated() {
			let tourModel = TourModel()
			tourModels.append(tourModel)
			
			for (index2, tuple) in tuples.enumerated() {
				//				if index2 == 0, let sourcePlacemark = sourcePlacemark {
				//					let source = sourcePlacemark
				//					let destination = tuple.0
				//					if let directions = DataManager.shared.findDirections(source: source, destination: destination) {
				//						tourModels[index].responses.append(directions)
				//					}
				//				}
				let source = tuple.0
				let destination = tuple.1
				if let direction = DataManager.shared.findDirection(source: source.toMKPlacemark, destination: destination.toMKPlacemark) {
					tourModels[index].directions.append(direction)
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
