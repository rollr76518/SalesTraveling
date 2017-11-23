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
}

class AddressResultTableViewController: UITableViewController {
	var matchingItems: [MKMapItem] = []
	var mapView: MKMapView?
	var delegate: AddressResultTableViewControllerProtocol?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension AddressResultTableViewController {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matchingItems.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let placemark = matchingItems[indexPath.row].placemark
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let placemark = matchingItems[indexPath.row].placemark
		delegate?.addressResultTableViewController(self, placemark: placemark)
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating
extension AddressResultTableViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		guard let keywords = searchController.searchBar.text,
			let mapView = mapView else { return }
		
		MapMananger.fetchLocalSearch(with: keywords, region: mapView.region) { (status) in
			switch status {
			case .success(let response):
				self.matchingItems = response.mapItems
				break
			case .failure(let error):
				print("fetch local search \(error)")
				self.matchingItems = []
				break
			}
			self.tableView.reloadData()
		}
	}
}
