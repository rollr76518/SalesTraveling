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
	
	@IBOutlet var labelRemainingQuota: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var buttonShowRoutes: UIButton!
	@IBOutlet var barButtonItemDone: UIBarButtonItem!
	@IBOutlet var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet var constraintLabelRemaingQuotaClose: NSLayoutConstraint!
	@IBOutlet var constraintLabelRemaingQuotaOpen: NSLayoutConstraint!
	lazy var firstFetch: Bool = activeAPIFetch()
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
			vc.tourModels = tourModels.sorted()
		}
	}
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		if CountdownManager.shared.canFetchAPI(placemarks.count) {
			performSegue(withIdentifier: LocateViewController.identifier, sender: nil)
		}
		else {
			// Show Alert
		}
	}
	
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@IBAction func buttonShowRoutesDidPressed(_ sender: Any) {
		showRoutes()
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
	
	func showRoutes() {
		tourModels = []
		
		let permutations = AlgorithmManager.permutations(placemarks)
		let tuplesCollection = permutations.map { (placemarks) -> [(MKPlacemark, MKPlacemark)] in
			return placemarks.toTuple()
		}
		
		for (index, tuples) in tuplesCollection.enumerated() {
			let tourModel = TourModel()
			tourModels.append(tourModel)
			
			for tuple in tuples {
				let source = tuple.0
				let destination = tuple.1
				guard let directions = DataManager.shared.findDirections(source: source, destination: destination) else {
					break
				}
				tourModels[index].responses.append(directions)
			}
		}
		performSegue(withIdentifier: DirectionsViewController.identifier, sender: tourModels)
	}
	
	func activeAPIFetch() -> Bool {
		UIView.animate(withDuration: 0.25) {
			self.constraintLabelRemaingQuotaOpen.priority = .defaultHigh
			self.constraintLabelRemaingQuotaClose.priority = .defaultLow
			self.view.layoutIfNeeded()
		}
		CountdownManager.shared.startTimer()
		NotificationCenter.default.addObserver(self, selector: #selector(countDownAPI),
											   name: NSNotification.Name(rawValue: notification_count_down), object: nil)
		return true
	}
	
	@objc func countDownAPI(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Int],
			let countTimes = userInfo["countTimes"], let second = userInfo["second"] {
			labelRemainingQuota.text = String(format: "API remaining %d/50 times, reset after %d seconds".localized, countTimes, second)
		}
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
				CountdownManager.shared.countTimes += 1
				let _ = firstFetch
				MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
					switch status {
					case .success(let response):
						DataManager.shared.saveDirections(source: source, destination: destination, routes: response.routes)
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
