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
	
	var placemarks: [MKPlacemark] = [] {
		didSet {
			tableView.reloadData()
			buttonCalculate.isEnabled = placemarks.count > 1
		}
	}
	
	var tourModels: [TourModel] = []
    var responeTimes: Int = 0
    
	override func viewDidLoad() {
		super.viewDidLoad()
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
			vc.tourModels = tourModels
		}
	}
	
	
	//MARK: - IBActions
	@IBAction func barButtonItemAddDidPressed(_ sender: Any) {
		performSegue(withIdentifier: "segueSetLocation", sender: nil)
	}
	
	@IBAction func buttonCalculateDidPressed(_ sender: Any) {
		if placemarks.count >= 2 {
            abc()
		}
	}
    
    func abc() {
        let permutations = PermutationManager.permutations(placemarks)
        let tuplesCollection = permutations.map { (placemarks) -> [(MKPlacemark, MKPlacemark)] in
            return PermutationManager.toTuple(placemarks)
        }
        for (index, tuples) in tuplesCollection.enumerated() {
            let tourModel = TourModel.init()
            self.tourModels.append(tourModel)
            
            for tuple in tuples {
                let source = tuple.0
                let destination = tuple.1
                MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
                    switch status {
                    case .success(let response):
                        let directions = DirectionsModel.init(source: source.toMapItem,
                                                              destination: destination.toMapItem,
                                                              routes: response.routes)
                        self.tourModels[index].responses.append(directions)
                        self.responeTimes += 1
                        break
                    case .failure(let error):
                        print("Can't calculate route with \(error)")
                        break
                    }
                    if self.responeTimes >= PermutationManager.factorial(self.placemarks.count) * (self.placemarks.count - 1) {
                        self.responeTimes = 0
                        self.performSegue(withIdentifier: "segueShowDirections", sender: self.tourModels)
                    }
                })
            }
        }
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension PlacesViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		
		return cell
	}
}

//MARK: - LocateViewControllerProtocol
extension PlacesViewController: LocateViewControllerProtocol {
	func locateViewController(_ locateViewController: LocateViewController, didSelect placemark: MKPlacemark) {
		placemarks.append(placemark)
	}
}
