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
	var tuple: (IndexPath, MKPlacemark?)?
	
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupUISearchController()
		handleDefaultPlacemark()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if tuple == nil {
			searchController.isActive = true
		}
	}
	
	@IBAction func barButtonItemCloseDidPressed(_ sender: Any) {
		if let navigationController = navigationController {
			navigationController.dismiss(animated: true, completion: nil)
		}
	}
	@IBAction func longPressOnMap(_ sender: Any) {
		if let recognizer = sender as? UILongPressGestureRecognizer {
			switch recognizer.state {
			case .began:
				let tappedPoint = recognizer.location(in: view)
				let coordinateTapped = mapView.convert(tappedPoint, toCoordinateFrom: view)
				addAnnotation(coordinateTapped)
			case .changed,
				 .ended,
				 .failed,
				 .possible,
				 .cancelled: break
			}
		}
	}
	
	func handleDefaultPlacemark() {
		if let tuple = tuple, let placemark = tuple.1 {
			MapMananger.showRegion(mapView, spanDegrees: 0.01, coordinate: placemark.coordinate)
			addAnnotation(placemark.coordinate)
		} else {
		 	let center = MapMananger().defaultMapCenter
			MapMananger.showRegion(mapView, spanDegrees: 0.01, coordinate: center)
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
		searchController.delegate = self

		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search".localized
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
	}
	
	func addAnnotation(_ coordinate: CLLocationCoordinate2D) {
		MapMananger.reverseCoordinate(coordinate, completion: { [weak self] (status) in
			switch status {
			case .success(let placemarks):
				if let placemark = placemarks.first, let strongSelf = self {
					self?.selectedPlacemark = placemark
					self?.mapView.removeAnnotations(strongSelf.mapView.annotations)
					let newAnnotation = placemark.pointAnnotation
					self?.mapView.addAnnotation(newAnnotation)
					self?.mapView.selectAnnotation(newAnnotation, animated: false)
				}
			case .failure(let error):
				let errorMessage = String.localizedStringWithFormat("Can't reverse coordinate with %@", error.localizedDescription)
				self?.presentAlert(of: errorMessage)
			}
		})
		
		MapMananger().defaultMapCenter = coordinate
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
		pinView?.canShowCallout = true
		pinView?.animatesDrop = false
		pinView?.isDraggable = true
		pinView?.rightCalloutAccessoryView = UIButton(type: .contactAdd)
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
		switch newState {
		case .ending:
			view.dragState = .none
			if let annotation = view.annotation {
				addAnnotation(annotation.coordinate)
			}
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
				dismiss(animated: true, completion: {
					delegate.locateViewController(self, change: selectedPlacemark, at: tuple.0, inRegion: image)
				})
			}
			else {
				dismiss(animated: true, completion: {
					delegate.locateViewController(self, didSelect: selectedPlacemark, inRegion: image)
				})
			}
		}
	}
}

//MARK: - UISearchControllerDelegate
extension LocateViewController: UISearchControllerDelegate {
	func didPresentSearchController(_ searchController: UISearchController) {
		if tuple == nil {
			UIView.animate(withDuration: 1.0, animations: {
				//
			}) { (finished) in
				self.searchController.searchBar.becomeFirstResponder()
			}
		}
	}
}

//MARK: - UIGestureRecognizerDelegate
extension LocateViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !(touch.view is MKPinAnnotationView)
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
		MapMananger().defaultMapCenter = placemark.coordinate
	}
}

