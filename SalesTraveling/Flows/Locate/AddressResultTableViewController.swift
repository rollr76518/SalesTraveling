//
//  AddressResultTableViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

protocol AddressResultTableViewControllerProtocol {
	
	func addressResultTableViewController(_ vc: AddressResultTableViewController, placemark: MKPlacemark)
	
	func favoritePlacemarksAtVC(_ vc: AddressResultTableViewController) -> [HYCPlacemark]
}

class AddressResultTableViewController: UITableViewController {
	
	var matchingPlacemarks = [HYCPlacemark]()
	var mapView: MKMapView?
	var delegate: AddressResultTableViewControllerProtocol?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		matchingPlacemarks = self.delegate?.favoritePlacemarksAtVC(self) ?? []
    }
}

// MARK: - UITableViewDataSource
extension AddressResultTableViewController {
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matchingPlacemarks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let placemark = matchingPlacemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		return cell
	}
}

// MARK: - UITableViewDelegate
extension AddressResultTableViewController {
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let placemark = matchingPlacemarks[indexPath.row]
		delegate?.addressResultTableViewController(self, placemark: placemark.toMKPlacemark)
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating
extension AddressResultTableViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		//https://stackoverflow.com/questions/30790244/uisearchcontroller-show-results-even-when-search-bar-is-empty
		//為了讓 Favorites 顯示出來
		view.isHidden = false
		
		guard
			let keywords = searchController.searchBar.text,
			let mapView = mapView
			else {
				return
		}
		
		MapMananger.fetchLocalSearch(with: keywords, region: mapView.region) { [weak self] (status) in
			guard let self = self else { return }
			switch status {
			case .success(let response):
				self.matchingPlacemarks = response.mapItems.map{ HYCPlacemark(mkPlacemark: $0.placemark) }
			case .failure(let error):
				print("fetch local search \(error.localizedDescription)")
				self.matchingPlacemarks = self.delegate?.favoritePlacemarksAtVC(self) ?? []
			}
			self.tableView.reloadData()
		}
	}
}
