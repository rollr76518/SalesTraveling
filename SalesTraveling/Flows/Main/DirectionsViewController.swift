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

	var placemarks: [MKPlacemark] = []
	var tourModel: TourModel!

	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {		
		if let vc = segue.destination as? RouteResultViewController,
			let tourModel = sender as? TourModel {
			vc.tourModel = tourModel
			vc.placemarks = placemarks
		}
    }
	
	@IBAction func barButtonItemDoneDidPressed(_ sender: Any) {
		navigationController?.dismiss(animated: true, completion: nil)
	}
}

extension DirectionsViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		cell.textLabel?.text = MapMananger.routeInfomation(tourModel)
		cell.detailTextLabel?.text = MapMananger.placemarkNames(placemarks)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "segueShowDirectionResult", sender: tourModel)
	}
}
