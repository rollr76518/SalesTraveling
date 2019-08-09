//
//  TourListViewController.swift
//  SalesTraveling
//
//  Created by Ryan on 2018/6/12.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

class TourListViewController: UIViewController {
	
	var isInTabBar: Bool = false

	var tourModels: [TourModel]! {
		didSet {
			tourModelsSorted = tourModels.sorted()
		}
	}
	private var tourModelsSorted: [TourModel]!
	@IBOutlet var labelRemainingQuota: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var barButtonItemSortByDistance: UIBarButtonItem! {
		didSet {
			barButtonItemSortByDistance.title = "Sorted by distance".localized
		}
	}
	@IBOutlet var barButtonItemSortByTime: UIBarButtonItem! {
		didSet {
			barButtonItemSortByTime.title = "Sorted by time".localized
		}
	}
	@IBOutlet var barButtonItemClose: UIBarButtonItem!
	@IBOutlet var barButtonItemDone: UIBarButtonItem!
	@IBOutlet var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet var constraintOfLabelRemaingQuotaBottom: NSLayoutConstraint!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(countDownAPI),
											   name: NSNotification.Name.CountDown, object: nil)
		
		if !isInTabBar {
			navigationItem.leftBarButtonItem = barButtonItemSortByTime
			navigationItem.rightBarButtonItem = barButtonItemClose
			title = "Result".localized
		} else {
			perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItemEdit, afterDelay: 0.25)
			title = "Saved Tours".localized
			constraintOfLabelRemaingQuotaBottom.constant = 0
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if isInTabBar {
			let savedTours = DataManager.shared.savedTours()
			tourModels = savedTours.sorted()
		}
		
		tableView.reloadData()
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? TourViewController,
			let tourModel = sender as? TourModel {
			vc.tourModel = tourModel
			vc.isInTabBar = isInTabBar
		}
	}
	// MAKR: - IBActions
	@IBAction func barButtonItemDoneDidPressed(_ sender: Any) {
		navigationController?.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func barButtonItemSortByDistanceDidPressed(_ sender: UIBarButtonItem) {
		tourModelsSorted = tourModels.sorted()
		tableView.reloadData()
		perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItemSortByTime, afterDelay: 0.25)
	}
	
	@IBAction func barButtonItemSortByTimeDidPressed(_ sender: UIBarButtonItem) {
		tourModelsSorted = tourModels.sorted(by: { (lhs, rhs) -> Bool in
			return lhs.sumOfExpectedTravelTime < rhs.sumOfExpectedTravelTime
		})
		tableView.reloadData()
		perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItemSortByDistance, afterDelay: 0.25)
	}
	
	@IBAction func barButtonItemEditAndDoneDidPressed(_ sender: UIBarButtonItem) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		let barButtonItem = tableView.isEditing ? barButtonItemDone:barButtonItemEdit
		perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItem, afterDelay: 0.25)
	}
}

fileprivate extension TourListViewController {
	@objc func countDownAPI(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Int],
			let countTimes = userInfo["countTimes"], let second = userInfo["second"] {
			labelRemainingQuota.text = String(format: "API remaining %d/50 times, reset after %d seconds".localized, countTimes, second)
		}
	}
	
	@objc func layoutLeftBarButtonItem(_ barButtonItem: UIBarButtonItem) {
		navigationItem.leftBarButtonItem = barButtonItem
	}
}

// MARK: - UITableViewDataSource
extension TourListViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return min(tourModelsSorted.count, 10)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let tourModel = tourModelsSorted[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "ios11", for: indexPath)
		cell.textLabel?.text = tourModel.routeInformation
		cell.detailTextLabel?.text = tourModel.stopInformation
		return cell
	}
}

// MARK: - UITableViewDelegate
extension TourListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let tourModel = tourModelsSorted[indexPath.row]
		if CountdownManager.shared.canCallRequest(tourModel.placemarks.count - 1) {
			performSegue(withIdentifier: TourViewController.identifier, sender: tourModel)
		}
		else {
			presentAlert(of: "API Request is reached limited".localized)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			let tourModel = tourModelsSorted[indexPath.row]
			DataManager.shared.delete(tourModel: tourModel)
			tourModels = DataManager.shared.savedTours().sorted()
			tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}
}
