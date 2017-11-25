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
	@IBOutlet weak var buttonShowRoutes: UIButton!
	@IBOutlet var barButtonItemDone: UIBarButtonItem!
	@IBOutlet var barButtonItemEdit: UIBarButtonItem!
	
	var placemarks: [MKPlacemark] = [] {
		didSet {
			buttonShowRoutes.isEnabled = placemarks.count > 1
		}
	}
	
	var regionImages: [UIImage] = []
	var tourModels: [TourModel] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		layoutLeftBarButtonItem()
		layoutButtonShowRoutes()
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
		}
	}
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		performSegue(withIdentifier: LocateViewController.identifier, sender: nil)
	}
	
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@IBAction func buttonShowRoutesDidPressed(_ sender: Any) {
		fetchRoutes()
	}
}

//MARK: - Private func
fileprivate extension PlacesViewController {
	@objc func layoutLeftBarButtonItem() {
		navigationItem.leftBarButtonItem = tableView.isEditing ? barButtonItemDone:barButtonItemEdit
	}
	
	func layoutButtonShowRoutes() {
		buttonShowRoutes.setTitle("Show Routes".localized, for: .normal)
	}
	
	func fetchRoutes() {
		tourModels = []
		
		let permutations = PermutationManager.permutations(placemarks)
		let tuplesCollection = permutations.map { (placemarks) -> [(MKPlacemark, MKPlacemark)] in
			return placemarks.toTuple()
		}
		
		for (index, tuples) in tuplesCollection.enumerated() {
			let tourModel = TourModel()
			tourModels.append(tourModel)
			
			for tuple in tuples {
				let source = tuple.0
				let destination = tuple.1
				let key = "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
				guard let json = UserDefaults.standard.object(forKey: key) as? Data else { break }
				let directions = try! JSONDecoder().decode(DirectionsModel.self, from: json)
				tourModels[index].responses.append(directions)
			}
		}
		performSegue(withIdentifier: DirectionsViewController.identifier, sender: tourModels)
	}
}

//MARK: - UITableViewDataSource
extension PlacesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		cell.imageView?.image = regionImages[indexPath.row]
		
		return cell
	}
}

//MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return .delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			placemarks.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}
}

//MARK: - LocateViewControllerProtocol
extension PlacesViewController: LocateViewControllerProtocol {
	func locateViewController(_ vc: LocateViewController, didSelect placemark: MKPlacemark, inRegion image: UIImage) {
		for Oldplacemark in placemarks {
			for tuple in [(Oldplacemark, placemark), (placemark, Oldplacemark)] {
				let source = tuple.0
				let destination = tuple.1
				MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
					switch status {
					case .success(let response):
						let directions = DirectionsModel(source: source, destination: destination, routes: response.routes)
						let key = "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
						let json = try! JSONEncoder().encode(directions)
						UserDefaults.standard.set(json, forKey: key)
						break
					case .failure(let error):
						print("Can't calculate route with \(error)")
						break
					}
				})
			}
		}
		placemarks.append(placemark)
		regionImages.append(image)
		tableView.reloadData()
	}
}
