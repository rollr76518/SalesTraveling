//
//  LocateViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

protocol LocateViewControllerProtocol {
	func locateViewController(_ locateViewController: LocateViewController, didSelect placemark: MKPlacemark)
}

class LocateViewController: UIViewController {
	let locationManager = CLLocationManager()
	lazy var addressResultTableViewController = makeAddressResultTableViewController()
	var searchController: UISearchController!
	var delegate: LocateViewControllerProtocol?
	var selectedPlacemark: MKPlacemark?
	
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupLocationManager()
		setupUISearchController()
	}
}

//MARK: - Private API
extension LocateViewController {
	fileprivate func makeAddressResultTableViewController() -> AddressResultTableViewController {
		guard let vc = UIStoryboard.init(name: "Locate", bundle: nil).instantiateViewController(withIdentifier: "AddressResultTableViewController") as? AddressResultTableViewController else {
				fatalError("AddressResultTableViewController doesn't exist")
		}
		vc.delegate = self
		vc.mapView = mapView
		return vc
	}

	fileprivate func setupLocationManager() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
	}
	
	fileprivate func setupUISearchController() {
		searchController = UISearchController(searchResultsController: addressResultTableViewController)
		searchController.searchResultsUpdater = addressResultTableViewController
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search"
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
	}
}

//MARK: - CLLocationManagerDelegate
extension LocateViewController: CLLocationManagerDelegate {
	private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status != .authorizedWhenInUse {
			manager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("error:: (error)")
	}
}

//MARK: - MKMapViewDelegate
extension LocateViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation is MKUserLocation {
			return nil
		}
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		pinView?.pinTintColor = .orange
		pinView?.canShowCallout = true
		pinView?.isDraggable = true
		pinView?.rightCalloutAccessoryView = UIButton.init(type: .contactAdd)
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if let selectedPlacemark = selectedPlacemark,
			let delegate = delegate {
			delegate.locateViewController(self, didSelect: selectedPlacemark)
			dismiss(animated: true, completion: nil)
		}
	}
}

//MARK: - AddressResultTableViewControllerProtocol
extension LocateViewController: AddressResultTableViewControllerProtocol {
	func addressResultTableViewController(_ addressResultTableViewController: AddressResultTableViewController, dropPinZoomIn placemark: MKPlacemark) {
		selectedPlacemark = placemark
		
		mapView.removeAnnotations(mapView.annotations)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		annotation.subtitle = MapMananger.parseAddress(placemark: placemark)
		
		mapView.addAnnotation(annotation)
		mapView.selectAnnotation(annotation, animated: true)
		
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(placemark.coordinate, span)
		mapView.setRegion(region, animated: true)
	}
}
