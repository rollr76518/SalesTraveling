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
	func dropPinZoomIn(placemark:MKPlacemark)
}

class AddressResultTableViewController: UITableViewController {
	var matchingItems: [MKMapItem] = []
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
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell2", for: indexPath)
		let placemark = matchingItems[indexPath.row].placemark
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = MapMananger.parseAddress(placemark: placemark)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let placemark = matchingItems[indexPath.row].placemark
		delegate?.dropPinZoomIn(placemark: placemark)
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating
extension AddressResultTableViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		guard let searchBarText = searchController.searchBar.text else { return }
		let request = MKLocalSearchRequest()
		request.naturalLanguageQuery = searchBarText
		let search = MKLocalSearch(request: request)
		search.start { response, _ in
			guard let response = response else {
				return
			}
			self.matchingItems = response.mapItems
			self.tableView.reloadData()
		}
	}
}
