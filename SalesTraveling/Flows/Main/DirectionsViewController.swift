//
//  DirectionsViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

class DirectionsViewController: UIViewController {

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
			barButtonItemSortByDistance.title = "Distance".localized
		}
	}
	@IBOutlet var barButtonItemSortByTime: UIBarButtonItem! {
		didSet {
			barButtonItemSortByTime.title = "Time".localized
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(countDownAPI),
											   name: NSNotification.Name.CountDown, object: nil)
		
		navigationItem.leftBarButtonItem = barButtonItemSortByTime
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {		
		if let vc = segue.destination as? RouteResultViewController,
			let tourModel = sender as? TourModel {
			vc.tourModel = tourModel
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

fileprivate extension DirectionsViewController {
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
extension DirectionsViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return min(tourModelsSorted.count, 10)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let tourModel = tourModelsSorted[indexPath.row]

		if #available(iOS 11, *) {
			let cell = tableView.dequeueReusableCell(withIdentifier: "ios11", for: indexPath)
			cell.textLabel?.text = tourModel.routeInformation
			cell.detailTextLabel?.text = tourModel.stopInformation
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "ios10", for: indexPath) as! DynamicHeightTableViewCell
			cell.labelTitle.text = tourModel.routeInformation
			cell.labelSubtitle.text = tourModel.stopInformation
			return cell
		}
	}
}

// MARK: - UITableViewDelegate
extension DirectionsViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let tourModel = tourModelsSorted[indexPath.row]
		if CountdownManager.shared.canCallRequest(tourModel.placemarks.count - 1) {
			performSegue(withIdentifier: RouteResultViewController.identifier, sender: tourModel)
		}
		else {
			self.presentAlert(of: "API Request is reached limited".localized)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
}
