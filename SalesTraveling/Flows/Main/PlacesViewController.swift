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
	
	var tourModel: TourModel = TourModel() {
		didSet {
			if tourModel.responses.count >= (placemarks.count - 1) {
				self.performSegue(withIdentifier: "segueShowDirections", sender: tourModel)
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
		let tourModel = sender as? TourModel {
			vc.tourModel = tourModel
			vc.placemarks = placemarks
		}
	}
	
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		performSegue(withIdentifier: "segueSetLocation", sender: nil)
	}
	
	@IBAction func buttonCalculateDidPressed(_ sender: Any) {
		if placemarks.count >= 2 {
			MapMananger.calculateDirections(from: placemarks[0].coordinate, to: placemarks[1].coordinate, completion: { (status) in
				switch status {
				case .success(let response):
					self.tourModel.responses.append(response)
					break
				case .failure(let error):
					print("Can't calculate route with \(error)")
					break
				}
				if self.tourModel.responses.count >= (self.placemarks.count - 1) {
					self.performSegue(withIdentifier: "segueShowDirections", sender: self.tourModel)
				}
			})
			
			MapMananger.calculateDirections(from: placemarks[1].coordinate, to: placemarks[2].coordinate, completion: { (status) in
				switch status {
				case .success(let response):
					self.tourModel.responses.append(response)
					break
				case .failure(let error):
					print("Can't calculate route with \(error)")
					break
				}
				if self.tourModel.responses.count >= (self.placemarks.count - 1) {
					self.performSegue(withIdentifier: "segueShowDirections", sender: self.tourModel)
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
