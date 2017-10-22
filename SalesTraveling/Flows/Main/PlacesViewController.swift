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
	@IBOutlet weak var buttonCalculate: UIButton!
	
	var annotations: [MKAnnotation] = [] {
		didSet {
			self.tableView.reloadData()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let nvc = segue.destination as? UINavigationController,
			let vc = nvc.viewControllers.first as? LocateViewController {
			vc.delegate = self
		}
	}
	
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		performSegue(withIdentifier: "segueSetLocation", sender: nil)
	}
	
	@IBAction func buttonCalculateDidPressed(_ sender: Any) {
		
	}
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension PlacesViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return annotations.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let annotation = annotations[indexPath.row]
		guard let title = annotation.title,
			let subtitle = annotation.subtitle else { return cell }
		
		cell.textLabel?.text = title
		cell.detailTextLabel?.text = subtitle
		
		return cell
	}
}

//MARK: - LocateViewControllerProtocol
extension PlacesViewController: LocateViewControllerProtocol {
	func locateViewController(_ locateViewController: LocateViewController, didSelect annotation: MKAnnotation) {
		annotations.append(annotation)
	}
}
