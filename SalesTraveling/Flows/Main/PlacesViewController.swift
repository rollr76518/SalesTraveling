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
	@IBOutlet var barButtonItemDone: UIBarButtonItem!
	@IBOutlet var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet var barButtonItemCalculate: UIBarButtonItem!
	@IBOutlet var constraintLabelRemaingQuotaClose: NSLayoutConstraint!
	@IBOutlet var constraintLabelRemaingQuotaOpen: NSLayoutConstraint!
	@IBOutlet var constraintToolbarOpen: NSLayoutConstraint!
	@IBOutlet var constraintToolbarClose: NSLayoutConstraint!
	lazy var firstFetch: Bool = activeAPIFetch()
	var userPlacemark: MKPlacemark?
	var placemarks: [MKPlacemark] = [] {
		didSet {
			let shouldShow = placemarks.count >= 2
			UIView.animate(withDuration: 0.25) {
				self.constraintToolbarOpen.priority = shouldShow ? .defaultHigh:.defaultLow
				self.constraintToolbarClose.priority = shouldShow ? .defaultLow:.defaultHigh
				self.view.layoutIfNeeded()
			}
		}
	}
	let locationManager = CLLocationManager()
	var regionImages: [UIImage] = []
	var tourModels: [TourModel] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		layoutLeftBarButtonItem()
		layoutButtonShowRoutes()
		setupLocationManager()
		barButtonItemCalculate.title = "Calculate".localized
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let nvc = segue.destination as? UINavigationController,
			let vc = nvc.viewControllers.first as? LocateViewController {
			vc.delegate = self
			if let tuple = sender as? (IndexPath, MKPlacemark?) {
				vc.tuple = tuple
			}
		}
		
		if let nvc = segue.destination as? UINavigationController,
			let vc = nvc.viewControllers.first as? DirectionsViewController,
			let tourModels = sender as? [TourModel] {
			vc.tourModels = tourModels.filter({ (tourModel) -> Bool in
				tourModel.responses.count > 0
			})
		}
	}
	
	//MARK: - IBActions
	@IBAction func rightBarButtonItemDidPressed(_ sender: Any) {
		let count = timesOfRequestShouldCalledWhenAddNewPlacemark
		
		if CountdownManager.shared.canCallRequest(count) {
			performSegue(withIdentifier: LocateViewController.identifier, sender: nil)
		}
		else {
			presentAlert(of: "API Request is reached limited".localized)
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

//MARK: - Compute Properties
private extension PlacesViewController {
	var timesOfRequestShouldCalledWhenAddNewPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenAddNewPlacemark(placemarks: placemarks.count, userPlacemark: (userPlacemark != nil))
	}

	var timesOfRequestShouldCalledWhenChangeExistPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenChangeExistPlacemark(placemarks: placemarks.count, userPlacemark: (userPlacemark != nil))
	}
	
	var timesOfRequestShouldCalledWhenChangeUserPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenChangeUserPlacemark(placemarks: placemarks.count)
	}
}

//MARK: - Private func
fileprivate extension PlacesViewController {
	@objc func layoutLeftBarButtonItem() {
		navigationItem.leftBarButtonItem = tableView.isEditing ? barButtonItemDone:barButtonItemEdit
	}
	
	func layoutButtonShowRoutes() {}
	
	func showRoutes() {
		tourModels = []
		
		let permutations = AlgorithmManager.permutations(placemarks)
		//[1, 2, 3] -> [[1, 2, 3], [1, 3, 2], [2, 3, 1], [2, 1, 3], [3, 1, 2], [3, 2, 1]]
		
		let tuplesCollection = permutations.map { (placemarks) -> [(MKPlacemark, MKPlacemark)] in
			return placemarks.toTuple()
		}
		//[[(1, 2), (2, 3)], [(1, 3), (3, 2)], [(2, 3), (3, 1)], [(2, 1), (1, 3)], [(3, 1), (1, 2)], [(3, 2), (2, 1)]]
		
		for (index, tuples) in tuplesCollection.enumerated() {
			let tourModel = TourModel()
			tourModels.append(tourModel)
			
			for (index2, tuple) in tuples.enumerated() {
				if index2 == 0, let userPlacemark = userPlacemark {
					let source = userPlacemark
					let destination = tuple.0
					if let directions = DataManager.shared.findDirections(source: source, destination: destination) {
						tourModels[index].responses.append(directions)
					}
				}
				let source = tuple.0
				let destination = tuple.1
				if let directions = DataManager.shared.findDirections(source: source, destination: destination) {
					tourModels[index].responses.append(directions)
				}
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
		NotificationCenter.default.addObserver(self, selector: #selector(countDown),
											   name: NSNotification.Name.CountDown, object: nil)
		return true
	}
	
	@objc func countDown(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Int],
			let countTimes = userInfo["countTimes"], let second = userInfo["second"] {
			labelRemainingQuota.text = String(format: "API remaining %d/50 times, reset after %d seconds".localized, countTimes, second)
		}
	}
	
	func setupLocationManager() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
	}
}

//MARK: - CLLocationManagerDelegate
extension PlacesViewController: CLLocationManagerDelegate {
	private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status != .authorizedWhenInUse {
			manager.requestLocation()
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		MapMananger.reverseCoordinate(locations.first!.coordinate) { (status) in
			switch status {
			case .success(let placemarks):
				self.userPlacemark = placemarks.first
				self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
			case .failure(let error):
				self.presentAlert(of: error.localizedDescription)
				break
			}
		}
		manager.stopUpdatingLocation()
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("manager didFailWithError: \(error)")
	}
}

//MARK: - UITableViewDataSource
extension PlacesViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 1
		}
		return placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "sourceCell", for: indexPath)
			if let userPlacemark = userPlacemark {
				cell.textLabel?.text = userPlacemark.name
			}
			return cell
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		cell.imageView?.image = regionImages[indexPath.row]
		cell.imageView?.layer.cornerRadius = 10.0
		cell.imageView?.layer.masksToBounds = true
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "From".localized
		}
		
		return "To".localized
	}
}

//MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section == 0 {
			let count = timesOfRequestShouldCalledWhenChangeUserPlacemark
			
			if CountdownManager.shared.canCallRequest(count) {
				performSegue(withIdentifier: LocateViewController.identifier, sender: (indexPath, userPlacemark))
			}
			else {
				presentAlert(of: "API Request is reached limited".localized)
			}
		}
		else {
			let count = timesOfRequestShouldCalledWhenChangeExistPlacemark
			
			if CountdownManager.shared.canCallRequest(count) {
				let placemark = placemarks[indexPath.row]
				performSegue(withIdentifier: LocateViewController.identifier, sender: (indexPath, placemark))
			}
			else {
				presentAlert(of: "API Request is reached limited".localized)
			}
		}
	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if indexPath.section == 0 {
			return false
		}
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
		let _ = firstFetch

		CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenAddNewPlacemark
		
		HYCLoadingView.shared.show()
		
		DataManager.shared.fetchDirections(ofNew: placemark, toOld: placemarks, current: userPlacemark) { (status) in
			switch status {
			case .failure(let error):
				self.presentAlert(of: "Can't calculate route with \(error)")
			case .success(let directionModels):
				DataManager.shared.save(directions: directionModels)
			}
			
			HYCLoadingView.shared.dismiss()
			self.placemarks.append(placemark)
			self.regionImages.append(image)
			self.tableView.reloadData()
		}
	}
	
	func locateViewController(_ vc: LocateViewController, change placemark: MKPlacemark, at indexPath: IndexPath, inRegion image: UIImage) {
		
		
		HYCLoadingView.shared.show()

		if indexPath.section == 0 {
			CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenChangeUserPlacemark

			DataManager.shared.fetchDirections(ofNew: placemark, toOld: placemarks, completeBlock: { (status) in
				switch status {
				case .failure(let error):
					self.presentAlert(of: "Can't calculate route with \(error)")
				case .success(let directionModels):
					DataManager.shared.save(directions: directionModels)
					self.userPlacemark = placemark
					self.tableView.reloadSections([indexPath.section], with: .automatic)
				}
				
				HYCLoadingView.shared.dismiss()
			})
		}
		else {
			CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenChangeExistPlacemark
			
			let oldPlacemarks = placemarks.filter({ (oldPlacemark) -> Bool in
				return oldPlacemark != placemark
			})
			
			DataManager.shared.fetchDirections(ofNew: placemark, toOld: oldPlacemarks, current: userPlacemark, completeBlock: { (status) in
				switch status {
				case .failure(let error):
					self.presentAlert(of: "Can't calculate route with \(error)")
				case .success(let directionModels):
					DataManager.shared.save(directions: directionModels)
					self.placemarks[indexPath.row] = placemark
					self.regionImages[indexPath.row] = image
					self.tableView.reloadSections([indexPath.section], with: .automatic)
				}
				
				HYCLoadingView.shared.dismiss()
			})
		}
	}
}
