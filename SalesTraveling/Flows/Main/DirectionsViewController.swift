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
	var responseResults: [[MKDirectionsResponse]] = []

	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {		
		if let vc = segue.destination as? RouteResultViewController,
			let responses = sender as? [MKDirectionsResponse] {
			vc.responses = responses
			vc.placemarks = placemarks
		}
    }
	
	@IBAction func barButtonItemDoneDidPressed(_ sender: Any) {
		navigationController?.dismiss(animated: true, completion: nil)
	}
}

extension DirectionsViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return responseResults.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		guard let object = responseResults[indexPath.row].first,
			let route = object.routes.first else { return cell }
		cell.textLabel?.text = "Time:" + "\(route.expectedTravelTime)" + ", " + "Distance" + "\(route.distance)"
		if let sourceName = placemarks.first?.name,
			let destinationName = placemarks.last?.name {
			cell.detailTextLabel?.text = sourceName + "->" + destinationName
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let responses = responseResults[indexPath.row]
		performSegue(withIdentifier: "segueShowDirectionResult", sender: responses)
	}
}
