//
//  TourViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

//https://stackoverflow.com/questions/37967555/how-to-mimic-ios-10-maps-bottom-sheet
class TourViewController: UIViewController {
	
	let toppestY: CGFloat = 80.0
	let lowestY = (UIScreen.main.bounds.height - 80)
	
	@IBOutlet var tableView: UITableView!
	var tourModel: TourModel!
	var isInTabBar: Bool!
	var routes: [MKRoute] = [] {
		didSet {
			if routes.count >= tourModel.placemarks.count - 1 {
				layoutPolylines()
			}
		}
	}
	var polylines: [MKPolyline] {
		return routes.map{ $0.polyline }
	}
	
	var isOpen: Bool = false {
		didSet  {
			if isOpen {
				openMovableView()
			} else {
				closeMovableView()
			}
		}
	}
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var movableView: UIVisualEffectView!
	@IBOutlet var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet var labelOfPlacemarks: UILabel!
	
	@IBOutlet var barButtonItemSave: UIBarButtonItem!
	@IBAction func rightBarButtonItemDidPressed(_ sender: Any) {
		do {
			try DataManager.shared.save(tourModel: tourModel)
			presentAlert(of: "Save to favorite!".localized)
		} catch {
			print("Cant save tourModel with \(error.localizedDescription)")
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		fetchRoutes()
		layoutPinViews()
		labelOfPlacemarks.text = "Placemarks".localized
		title = "Tour".localized
		
		if !isInTabBar {
			navigationItem.rightBarButtonItem = barButtonItemSave
		}
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

// MARK: - Private func
fileprivate extension TourViewController {
	func fetchRoutes() {
		HYCLoadingView.shared.show()
		
		DataManager.shared.fetchRoutes(placemarks: tourModel.placemarks) { [weak self] (status) in
			
			HYCLoadingView.shared.dismiss()
			
			switch status {
			case .failure(let error):
				self?.presentAlert(of: error.localizedDescription)
			case .success(let routes):
				self?.routes = routes
			}
		}
	}
	
	func layoutPinViews() {
		mapView.addAnnotations(tourModel.placemarks)
	}
	
	func layoutPolylines() {
		mapView.addOverlays(polylines, level: .aboveRoads)
		let rect = MapMananger.boundingMapRect(polylines: polylines)
		mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsetsMake(10, 10, 10, 10), animated: false)
	}
	
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
extension TourViewController: MKMapViewDelegate {
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
			for placemark in tourModel.placemarks {
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
extension TourViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tourModel.placemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let placemark = tourModel.placemarks[indexPath.row]
		cell.textLabel?.text = "\(indexPath.row + 1). "
		if let name = placemark.name {
			 cell.textLabel?.text?.append(name)
		}
		cell.detailTextLabel?.text = placemark.title
		return cell
	}
}

// MARK: UITableViewDelegate
extension TourViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		isOpen = false
		
		let placemark = tourModel.placemarks[indexPath.row]
		
		for annotation in mapView.annotations {
			if annotation.coordinate.latitude == placemark.coordinate.latitude &&
				annotation.coordinate.longitude == placemark.coordinate.longitude {
				mapView.selectAnnotation(annotation, animated: true)
			}
		}
	}
}

// MARK: - UIGestureRecognizerDelegate
extension TourViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !tableView.frame.contains(touch.location(in: movableView))
	}
}

// MARK: - UIScrollViewDelegate
extension TourViewController: UIScrollViewDelegate {
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
