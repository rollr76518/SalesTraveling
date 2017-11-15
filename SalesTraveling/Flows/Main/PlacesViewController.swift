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
    @IBOutlet var barButtonItemDone: UIBarButtonItem!
    @IBOutlet var barButtonItemEdit: UIBarButtonItem!
    
    var placemarks: [MKPlacemark] = [] {
        didSet {
            buttonCalculate.isEnabled = placemarks.count > 1
        }
    }
    
    var regionImages: [UIImage] = []
	var tourModels: [TourModel] = []
    var responeTimes: Int = 0
    
	override func viewDidLoad() {
		super.viewDidLoad()
        layoutLeftBarButtonItem()
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
	
    @IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
    }
    
    @IBAction func buttonCalculateDidPressed(_ sender: Any) {
		if placemarks.count >= 2 {
            fetchRoutes()
		}
	}
}

//MARK: - Private func
extension PlacesViewController {
    @objc fileprivate func layoutLeftBarButtonItem() {
        navigationItem.leftBarButtonItem = tableView.isEditing ? barButtonItemDone:barButtonItemEdit
    }
    
    fileprivate func fetchRoutes() {
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

//MARK: - UITableViewDataSource
extension PlacesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let placemark = placemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		cell.imageView?.image = regionImages[indexPath.row]
        
		return cell
	}
}

//MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
        placemarks.append(placemark)
        regionImages.append(image)
        tableView.reloadData()
    }
}
