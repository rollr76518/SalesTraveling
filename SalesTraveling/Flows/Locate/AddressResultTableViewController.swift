//
//  AddressResultTableViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

protocol AddressResultTableViewControllerDataSource: AnyObject {
	
	func mapView(for vc: AddressResultTableViewController) -> MKMapView
	func favoritePlacemarks(for vc: AddressResultTableViewController) -> [HYCPlacemark]
}

protocol AddressResultTableViewControllerDelegate: AnyObject {
	
	func viewController(_ vc: AddressResultTableViewController, didSelectAt placemark: HYCPlacemark)
	func viewController(_ vc: AddressResultTableViewController, didRecevice error: Error)
}

class AddressResultTableViewController: UITableViewController {
	
	private var matchingPlacemarks = [HYCPlacemark]()
	private var mapView: MKMapView {
		guard let dataSource = dataSource else {
			fatalError("Must have dataSource")
		}
		return dataSource.mapView(for: self)
	}
	weak var dataSource: AddressResultTableViewControllerDataSource?
	weak var delegate: AddressResultTableViewControllerDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		matchingPlacemarks = dataSource?.favoritePlacemarks(for: self) ?? []
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
		delegate?.viewController(self, didSelectAt: placemark)
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating
extension AddressResultTableViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		//https://stackoverflow.com/questions/30790244/uisearchcontroller-show-results-even-when-search-bar-is-empty
		//為了讓 Favorites 顯示出來
		view.isHidden = false
		
		guard let keywords = searchController.searchBar.text else { return }
		
		MapMananger.fetchLocalSearch(with: keywords, region: mapView.region) { (status) in
			switch status {
			case .success(let response):
				self.matchingPlacemarks = response.mapItems.map{ HYCPlacemark(mkPlacemark: $0.placemark) }
			case .failure(let error):
				self.delegate?.viewController(self, didRecevice: error)
				self.matchingPlacemarks = self.dataSource?.favoritePlacemarks(for: self) ?? []
			}
			self.tableView.reloadData()
		}
	}
}
