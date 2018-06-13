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
	private var tourModelsSorted: [TourModel]! {
		didSet {
			if isViewLoaded {
				tableView.reloadData()
			}
		}
	}
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
	@IBOutlet var barbuttonItemClose: UIBarButtonItem!
	@IBOutlet var constraintOfLabelRemaingQuotaBottom: NSLayoutConstraint!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(countDownAPI),
											   name: NSNotification.Name.CountDown, object: nil)
		
		if !isInTabBar {
			navigationItem.leftBarButtonItem = barButtonItemSortByTime
			navigationItem.rightBarButtonItem = barbuttonItemClose
			title = "Result of caculate".localized
		} else {
			title = "Saved Tours".localized
			constraintOfLabelRemaingQuotaBottom.constant = 0
		}
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
		perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItemSortByTime, afterDelay: 0.25)
	}
	
	@IBAction func barButtonItemSortByTimeDidPressed(_ sender: UIBarButtonItem) {
		tourModelsSorted = tourModels.sorted(by: { (lhs, rhs) -> Bool in
			return lhs.sumOfExpectedTravelTime < rhs.sumOfExpectedTravelTime
		})
		perform(#selector(layoutLeftBarButtonItem(_:)), with: barButtonItemSortByDistance, afterDelay: 0.25)
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
		
//		if #available(iOS 11, *) {
			let cell = tableView.dequeueReusableCell(withIdentifier: "ios11", for: indexPath)
			cell.textLabel?.text = tourModel.routeInformation
			cell.detailTextLabel?.text = tourModel.stopInformation
			return cell
//		} else {
//			let cell = tableView.dequeueReusableCell(withIdentifier: "ios10", for: indexPath) as! DynamicHeightTableViewCell
//			cell.labelTitle.text = tourModel.routeInformation
//			cell.labelSubtitle.text = tourModel.stopInformation
//			return cell
//		}
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
		return UITableViewAutomaticDimension
	}
}
