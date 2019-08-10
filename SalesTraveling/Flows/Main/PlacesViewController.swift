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
	@IBOutlet var barButtonItemResultOfCaculate: UIBarButtonItem! {
		didSet {
			barButtonItemResultOfCaculate.title = "Result".localized
			navigationItem.rightBarButtonItem = barButtonItemResultOfCaculate
		}
	}
	@IBOutlet var constraintLabelRemaingQuotaClose: NSLayoutConstraint!
	@IBOutlet var constraintLabelRemaingQuotaOpen: NSLayoutConstraint!
	@IBOutlet var toolbar: UIToolbar!
	@IBOutlet var searchBar: UISearchBar! {
		didSet {
			searchBar.placeholder = "Where do you want to go?".localized
		}
	}
	
	lazy var firstFetch: Bool = activeAPIFetch()
	var sourcePlacemark: MKPlacemark?
	var placemarks: [MKPlacemark] = []
	let locationManager = CLLocationManager()
	var regionImages: [UIImage] = []
	var tourModels: [TourModel] = []
	var sourcePlacemarkName = "Current location".localized
	
	override func viewDidLoad() {
		super.viewDidLoad()
		layoutLeftBarButtonItem()
		layoutButtonShowRoutes()
		setupLocationManager()
		title = "Tour calculate".localized		
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
			let vc = nvc.viewControllers.first as? TourListViewController,
			let tourModels = sender as? [TourModel] {
			vc.tourModels = tourModels.filter({ (tourModel) -> Bool in
				tourModel.directions.count > 0
			})
		}
	}
	
	//MARK: - IBActions
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@IBAction func barButtonItemResultOfCaculateDidPressed(_ sender: Any) {
		if placemarks.count < 2 {
			presentAlert(of: "Destinations should be in 2~9".localized)
			return
		}
		showResultOfCaculate()
	}
}

//MARK: - Compute Properties
private extension PlacesViewController {
	var timesOfRequestShouldCalledWhenAddNewPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenAddNewPlacemark(placemarks: placemarks.count, userPlacemark: (sourcePlacemark != nil))
	}

	var timesOfRequestShouldCalledWhenChangeExistPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenChangeExistPlacemark(placemarks: placemarks.count, userPlacemark: (sourcePlacemark != nil))
	}
	
	var timesOfRequestShouldCalledWhenChangeUserPlacemark: Int {
		return CountdownManager.shared.timesOfRequestShouldCalledWhenChangeUserPlacemark(placemarks: placemarks.count)
	}
}

//MARK: - Private func
fileprivate extension PlacesViewController {
	@objc func layoutLeftBarButtonItem() {
		let barButtonItem = tableView.isEditing ? barButtonItemDone:barButtonItemEdit
		navigationItem.leftBarButtonItem = barButtonItem!
	}
	
	@objc func scrollToBottom() {
		let rect = CGRect(origin: .zero, size: tableView.contentSize)
		tableView.scrollRectToVisible(rect, animated: true)
	}
	
	func layoutButtonShowRoutes() {}
	
	func showResultOfCaculate() {
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
				if index2 == 0, let sourcePlacemark = sourcePlacemark {
					let source = sourcePlacemark
					let destination = tuple.0
					if let directions = DataManager.shared.findDirection(source: source, destination: destination) {
						tourModels[index].directions.append(directions)
					}
				}
				let source = tuple.0
				let destination = tuple.1
				if let directions = DataManager.shared.findDirection(source: source, destination: destination) {
					tourModels[index].directions.append(directions)
				}
			}
		}
		performSegue(withIdentifier: TourListViewController.identifier, sender: tourModels)
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
		MapMananger.reverseCoordinate(locations.first!.coordinate) { [weak self] (status) in
			switch status {
			case .success(let placemarks):
				self?.sourcePlacemark = placemarks.first
				self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
			case .failure(let error):
				self?.presentAlert(of: error.localizedDescription)
			}
		}
		manager.stopUpdatingLocation()
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("manager didFailWithError: \(error.localizedDescription)")
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
			let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
			cell.imageView?.image = nil
			if let sourcePlacemark = sourcePlacemark {
				cell.textLabel?.text = sourcePlacemarkName
				cell.textLabel?.textColor = UIColor.brand
				cell.detailTextLabel?.text = sourcePlacemark.title
			} else {
				cell.textLabel?.text = "Tap to select your source".localized
				cell.textLabel?.textColor = UIColor.gray
				cell.detailTextLabel?.text = nil
			}
			return cell
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.textLabel?.textColor = UIColor.black
		cell.detailTextLabel?.text = placemark.title
		cell.imageView?.image = regionImages[indexPath.row]
		cell.imageView?.layer.cornerRadius = 10.0
		cell.imageView?.layer.masksToBounds = true
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Source".localized
		}
		
		return "Destinations".localized
	}
}

//MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section == 0 {
			let count = timesOfRequestShouldCalledWhenChangeUserPlacemark
			
			if CountdownManager.shared.canCallRequest(count) {
				performSegue(withIdentifier: LocateViewController.identifier, sender: (indexPath, sourcePlacemark))
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
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			placemarks.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if section == 0 {
			return nil
		}
		return searchBar
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0 {
			return CGFloat.leastNormalMagnitude
		}
		return 44
	}
}

//MARK: - LocateViewControllerProtocol
extension PlacesViewController: LocateViewControllerProtocol {
	func locateViewController(_ vc: LocateViewController, didSelect placemark: MKPlacemark, inRegion image: UIImage) {
		let _ = firstFetch

		CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenAddNewPlacemark
		
		HYCLoadingView.shared.show()
		
		DataManager.shared.fetchDirections(ofNew: placemark, toOld: placemarks, current: sourcePlacemark) { [weak self] (status) in
			
			HYCLoadingView.shared.dismiss()

			if let `self` = self {
				switch status {
				case .failure(let error):
					let errorMessage = String.localizedStringWithFormat("Can't calculate route with %@", error.localizedDescription)
					self.presentAlert(of: errorMessage)
				case .success(let directionModels):
					DataManager.shared.save(directions: directionModels)
					self.placemarks.append(placemark)
					self.regionImages.append(image)
					self.tableView.reloadData()
					self.perform(#selector(self.scrollToBottom), with: nil, afterDelay: 0.25)
				}
			}
		}
	}
	
	func locateViewController(_ vc: LocateViewController, change placemark: MKPlacemark, at indexPath: IndexPath, inRegion image: UIImage) {
		
		HYCLoadingView.shared.show()

		if indexPath.section == 0 {
			CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenChangeUserPlacemark

			DataManager.shared.fetchDirection(ofNew: placemark, toOld: placemarks, completeBlock: { [weak self] (status) in

				HYCLoadingView.shared.dismiss()

				if let `self` = self {
					switch status {
					case .failure(let error):
						let errorMessage = String.localizedStringWithFormat("Can't calculate route with %@", error.localizedDescription)
						self.presentAlert(of: errorMessage)
					case .success(let directionModels):
						DataManager.shared.save(directions: directionModels)
						self.sourcePlacemark = placemark
						self.sourcePlacemarkName = "Source".localized
						self.tableView.reloadSections([indexPath.section], with: .automatic)
					}
				}
			})
		}
		else {
			CountdownManager.shared.countTimes += timesOfRequestShouldCalledWhenChangeExistPlacemark
			
			let oldPlacemarks = placemarks.filter({ (oldPlacemark) -> Bool in
				return oldPlacemark != placemark
			})
			
			DataManager.shared.fetchDirections(ofNew: placemark, toOld: oldPlacemarks, current: sourcePlacemark, completeBlock: { [weak self] (status) in

				HYCLoadingView.shared.dismiss()

				if let `self` = self {
					switch status {
					case .failure(let error):
						let errorMessage = String.localizedStringWithFormat("Can't calculate route with %@", error.localizedDescription)
						self.presentAlert(of: errorMessage)
					case .success(let directionModels):
						DataManager.shared.save(directions: directionModels)
						self.placemarks[indexPath.row] = placemark
						self.regionImages[indexPath.row] = image
						self.tableView.reloadSections([indexPath.section], with: .automatic)
					}
				}
			})
		}
	}
}

extension PlacesViewController: UISearchBarDelegate {
	func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
		let count = timesOfRequestShouldCalledWhenAddNewPlacemark
		
		if CountdownManager.shared.canCallRequest(count) {
			performSegue(withIdentifier: LocateViewController.identifier, sender: nil)
		}
		else {
			presentAlert(of: "API Request is reached limited".localized)
		}
		
		return false
	}
}
