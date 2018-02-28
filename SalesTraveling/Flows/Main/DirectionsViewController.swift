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

	var tourModels: [TourModel]!
	@IBOutlet var labelRemainingQuota: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(countDownAPI),
											   name: NSNotification.Name(rawValue: notification_count_down), object: nil)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {		
		if let vc = segue.destination as? RouteResultViewController,
			let tourModel = sender as? TourModel {
			vc.tourModel = tourModel
		}
    }
	
	@IBAction func barButtonItemDoneDidPressed(_ sender: Any) {
		navigationController?.dismiss(animated: true, completion: nil)
	}
}

fileprivate extension DirectionsViewController {
	@objc func countDownAPI(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Int],
			let countTimes = userInfo["countTimes"], let second = userInfo["second"] {
			labelRemainingQuota.text = String(format: "API remaining %d/50 times, reset after %d seconds".localized, countTimes, second)
		}
	}
}

// MARK: - UITableViewDataSource
extension DirectionsViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tourModels.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let tourModel = tourModels[indexPath.row]

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
		
		let tourModel = tourModels[indexPath.row]
		if CountdownManager.shared.canFetchAPI(tourModel.placemarks.count - 1) {
			performSegue(withIdentifier: RouteResultViewController.identifier, sender: tourModel)
		}
		else {
			let alert = AlertManager.basicAlert(title: "Prompt".localized, message: "API Request is reached limited".localized)
			present(alert, animated: true, completion: nil)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
}
