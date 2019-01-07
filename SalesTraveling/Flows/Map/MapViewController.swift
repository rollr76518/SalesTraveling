//
//  MapViewController.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/1/7.
//  Copyright © 2019年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
	
	var toppestY: CGFloat {
		return 20.0 + self.navigationController!.navigationBar.frame.maxY
	}
	
	var lowestY: CGFloat {
		return self.tabBarController!.tabBar.frame.minY - 80.0
	}
	
	lazy var addressResultTableViewController = makeAddressResultTableViewController()
	var searchController: UISearchController!

	@IBOutlet var tableView: UITableView!

	var isOpen: Bool = false {
		didSet  {
			if isOpen {
				openMovableView()
			} else {
				closeMovableView()
			}
		}
	}
	
	var placemarks: [MKPlacemark] = [] {
		didSet {
			self.mapView.removeAnnotations(mapView.annotations)
			self.mapView.addAnnotations(placemarks.map({ (placemark) -> MKAnnotation in
				return placemark.pointAnnotation
			}))
			self.tableView.reloadData()
		}
	}
	var sortedPlacemarks: [MKPlacemark] {
		return placemarks
	}
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var movableView: UIVisualEffectView!
	@IBOutlet var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet var labelOfPlacemarks: UILabel!
	
	@IBOutlet var barButtonItemSave: UIBarButtonItem!
	@IBAction func rightBarButtonItemDidPressed(_ sender: Any) {

	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupUISearchController()

		labelOfPlacemarks.text = "Placemarks".localized
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		layoutMovableView()
	}
	
	@IBAction func tapGestureRecognizerDidPressed(_ sender: UITapGestureRecognizer) {
		isOpen = !isOpen
	}
	
	@IBAction func panGestureRecognizerDidPressed(_ sender: UIPanGestureRecognizer) {
		let touchPoint = sender.location(in: sender.view?.superview)
		switch sender.state {
		case .began: break
		case .changed:
			movableView.frame.origin.y = touchPoint.y
		case .ended, .failed, .cancelled:
			setOpenOrClose()
		default: break
		}
		
	}
}

extension MapViewController {
	func makeAddressResultTableViewController() -> AddressResultTableViewController {
		guard let vc = UIStoryboard(name: "Locate", bundle: nil).instantiateViewController(withIdentifier: AddressResultTableViewController.identifier) as? AddressResultTableViewController
			else {
				fatalError("AddressResultTableViewController doesn't exist")
		}
		
		vc.delegate = self
		vc.mapView = mapView
		return vc
	}
	
	func setupUISearchController() {
		searchController = UISearchController(searchResultsController: addressResultTableViewController)
		searchController.searchResultsUpdater = addressResultTableViewController
		searchController.delegate = self
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search".localized
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
	}
}

//MARK: - AddressResultTableViewControllerProtocol
extension MapViewController: AddressResultTableViewControllerProtocol {
	func addressResultTableViewController(_ vc: AddressResultTableViewController, placemark: MKPlacemark) {
		placemarks.append(placemark)
		MapMananger().defaultMapCenter = placemark.coordinate
	}
}

//MARK: - UISearchControllerDelegate
extension MapViewController: UISearchControllerDelegate {

}

// MARK: - Private func
fileprivate extension MapViewController {
	func layoutMovableView() {
		movableView.layer.cornerRadius = 22.0
		movableView.layer.masksToBounds = true
		constriantOfMovableViewHeight.constant = view.frame.height
	}
	
	func setOpenOrClose() {
		if isOpen {
			if movableView.frame.origin.y > toppestY + 30 {
				isOpen = false
			} else {
				isOpen = true
			}
		} else {
			if movableView.frame.origin.y < lowestY - 30 {
				isOpen = true
			} else {
				isOpen = false
			}
		}
	}
	
	func openMovableView() {
		UIView.beginAnimations(nil, context: nil)
		movableView.frame.origin.y = toppestY
		UIView.commitAnimations()
	}
	
	func closeMovableView() {
		UIView.beginAnimations(nil, context: nil)
		movableView.frame.origin.y = lowestY
		UIView.commitAnimations()
	}
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation is MKUserLocation {
			return nil
		}
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		pinView?.pinTintColor = .orange
		pinView?.canShowCallout = true
		pinView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = .orange
		renderer.lineWidth = 4.0
		return renderer
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if let annotation = view.annotation {
			for placemark in sortedPlacemarks {
				if placemark.coordinate.latitude == annotation.coordinate.latitude &&
					placemark.coordinate.longitude == annotation.coordinate.longitude {
					
					let mapItems = [placemark.toMapItem]
					let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
					MKMapItem.openMaps(with: mapItems, launchOptions: options)
				}
			}
		} else {
			print("view.annotation is nil")
		}
	}
}

// MARK: - UITableViewDataSource
extension MapViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedPlacemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let placemark = sortedPlacemarks[indexPath.row]
		cell.textLabel?.text = "\(indexPath.row + 1). "
		if let name = placemark.name {
			cell.textLabel?.text?.append(name)
		}
		cell.detailTextLabel?.text = placemark.title
		return cell
	}
}

// MARK: UITableViewDelegate
extension MapViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		isOpen = false
		
		let placemark = sortedPlacemarks[indexPath.row]
		
		for annotation in mapView.annotations {
			if annotation.coordinate.latitude == placemark.coordinate.latitude &&
				annotation.coordinate.longitude == placemark.coordinate.longitude {
				mapView.selectAnnotation(annotation, animated: true)
			}
		}
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !tableView.frame.contains(touch.location(in: movableView))
	}
}

// MARK: - UIScrollViewDelegate
extension MapViewController: UIScrollViewDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if (scrollView.contentOffset.y < 0) || (scrollView.contentSize.height <= scrollView.frame.size.height) {
			movableView.frame.origin.y -= scrollView.contentOffset.y
			scrollView.contentOffset = CGPoint.zero
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		setOpenOrClose()
	}
}
