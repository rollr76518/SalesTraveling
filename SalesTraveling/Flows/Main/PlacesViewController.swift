//
//  PlacesViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var buttonCalculate: UIButton!
	
	var placemarks: [MKPlacemark] = [] {
		didSet {
			tableView.reloadData()
			buttonCalculate.isEnabled = placemarks.count > 1
		}
	}
	
	var tourModels: [TourModel] = [] {
		didSet {
			if tourModels.count >= (placemarks.count - 1) {
				self.performSegue(withIdentifier: "segueShowDirections", sender: tourModels)
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let nvc = segue.destination as? UINavigationController,
			let vc = nvc.viewControllers.first as? LocateViewController {
			vc.delegate = self
		}
		
		if let nvc = segue.destination as? UINavigationController,
		let vc = nvc.viewControllers.first as? DirectionsViewController,
		let tourModels = sender as? [TourModel] {
			vc.tourModels = tourModels
			vc.placemarks = placemarks
		}
	}
	
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		performSegue(withIdentifier: "segueSetLocation", sender: nil)
	}
	
	@IBAction func buttonCalculateDidPressed(_ sender: Any) {
		if let begin = placemarks.first, let destination = placemarks.last, placemarks.count > 1 {
			MapMananger.showRoute(from: begin.coordinate, to: destination.coordinate, completion: { (status) in
				switch status {
				case .success(let response):
//					self.responseResults.append([response])
					break
				case .failure(let error):
					print("Can't calculate route with \(error)")
					break
				}
			})
		}
	}
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension PlacesViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		
		return cell
	}
}

//MARK: - LocateViewControllerProtocol
extension PlacesViewController: LocateViewControllerProtocol {
	func locateViewController(_ locateViewController: LocateViewController, didSelect placemark: MKPlacemark) {
		placemarks.append(placemark)
	}
}
