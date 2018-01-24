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
	func locateViewController(_ vc: LocateViewController, didSelect placemark: MKPlacemark, inRegion image: UIImage)
	func locateViewController(_ vc: LocateViewController, change placemark: MKPlacemark, at indexPath: IndexPath, inRegion image: UIImage)
}

class LocateViewController: UIViewController {
	lazy var addressResultTableViewController = makeAddressResultTableViewController()
	var searchController: UISearchController!
	var delegate: LocateViewControllerProtocol?
	var selectedPlacemark: MKPlacemark?
	var tappedPoint: CGPoint?
	var tuple: (IndexPath, MKPlacemark)?
	
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupUISearchController()
		handleDefaultPlacemark()
	}
	
	@IBAction func barButtonItemCloseDidPressed(_ sender: Any) {
		if let navigationController = navigationController {
			navigationController.dismiss(animated: true, completion: nil)
		}
	}
	@IBAction func tapMap(_ sender: Any) {
		if let recognizer = sender as? UITapGestureRecognizer {
			tappedPoint = recognizer.location(in: view)
		}
	}
	
	func handleDefaultPlacemark() {
		if let tuple = tuple {
			let placemark = tuple.1
			MapMananger.showRegion(mapView, spanDegrees: 0.01, coordinate: placemark.coordinate)
			addAnnotation(placemark.coordinate)
		}
	}
}

//MARK: - Private API
fileprivate extension LocateViewController {
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
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search".localized
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
	}
	
	func addAnnotation(_ coordinate: CLLocationCoordinate2D) {
		MapMananger.reverseCoordinate(coordinate, completion: { (status) in
			switch status {
			case .success(let placemarks):
				if let placemark = placemarks.first {
					self.selectedPlacemark = placemark
					self.mapView.removeAnnotations(self.mapView.annotations)
					let newAnnotation = placemark.pointAnnotation
					self.mapView.addAnnotation(newAnnotation)
					self.mapView.selectAnnotation(newAnnotation, animated: true)
				}
				break
			case .failure(let error):
				print("reverseCoordinate: \(error)")
				break
			}
		})
	}
}

//MARK: - MKMapViewDelegate
extension LocateViewController: MKMapViewDelegate {
//	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
//		if let _ = selectedPlacemark {
//			return
//		}
//
//		MapMananger.showRegion(mapView, spanDegrees: 0.01, coordinate: userLocation.coordinate)
//		addAnnotation(userLocation.coordinate)
//	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation is MKUserLocation {
			return nil
		}
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		pinView?.pinTintColor = .orange
		pinView?.canShowCallout = true
		pinView?.animatesDrop = false
		pinView?.isDraggable = true
		pinView?.rightCalloutAccessoryView = UIButton(type: .contactAdd)
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		switch newState {
		case .ending:
			view.dragState = .none
			if let annotation = view.annotation {
				addAnnotation(annotation.coordinate)
			}
			break
		default:
			break
		}
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		mapView.deselectAnnotation(view.annotation, animated: false)
		let width: CGFloat = 100
		let rect = CGRect(x: view.frame.midX - view.centerOffset.x - width/2,
						  y: view.frame.midY - view.centerOffset.y - width/2,
						  width: width, height: width)
		if let selectedPlacemark = selectedPlacemark,
			let delegate = delegate,
			let image = mapView.toImage().crop(rect: rect)  {
			if let tuple = tuple {
				delegate.locateViewController(self, change: selectedPlacemark, at: tuple.0, inRegion: image)
			}
			else {
				delegate.locateViewController(self, didSelect: selectedPlacemark, inRegion: image)
			}
			dismiss(animated: true, completion: nil)
		}
	}
	
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let point = tappedPoint {
			let coordinateTapped = mapView.convert(point, toCoordinateFrom: view)
			addAnnotation(coordinateTapped)
			tappedPoint = nil
		}
	}
}

//MARK: - AddressResultTableViewControllerProtocol
extension LocateViewController: AddressResultTableViewControllerProtocol {
	func addressResultTableViewController(_ vc: AddressResultTableViewController, placemark: MKPlacemark) {
		selectedPlacemark = placemark
		
		let annotation = placemark.pointAnnotation
		mapView.removeAnnotations(mapView.annotations)
		mapView.addAnnotation(annotation)
		mapView.selectAnnotation(annotation, animated: true)
		
		MapMananger.showRegion(mapView, spanDegrees: 0.01, coordinate: placemark.coordinate)
	}
}

//MARK: - UIGestureRecognizerDelegate
extension LocateViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !(touch.view is MKPinAnnotationView)
	}
}
