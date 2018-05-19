//
//  RouteResultViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

//https://stackoverflow.com/questions/37967555/how-to-mimic-ios-10-maps-bottom-sheet
class RouteResultViewController: UIViewController {
	
	let toppestY: CGFloat = 80.0
	let lowestY = (UIScreen.main.bounds.height - 80)
	
	@IBOutlet var tableView: UITableView!
	var tourModel: TourModel!
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
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var movableView: UIVisualEffectView!
	@IBOutlet var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet var labelOfPlacemark: UILabel!
	
	@IBAction func rightBarButtonItemDidPressed(_ sender: Any) {
//		let mapItems = tourModel.placemarks.map({ (placemark) -> MKMapItem in
//			return placemark.toMapItem
//		})
//		let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
//		MKMapItem.openMaps(with: mapItems, launchOptions: options)
		
		//TODO: 只支援 Google Map
		let activity = UIActivityViewController(activityItems: [tourModel.stopInformation], applicationActivities: nil)
		present(activity, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		fetchRoutes()
		layoutPinViews()
		labelOfPlacemark.text = "Placemarks".localized
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		layoutMovableView()
	}
	
	@IBAction func tapGestureRecognizerDidPressed(_ sender: UITapGestureRecognizer) {
		if isOpen() {
			closeMovableView()
		}
		else {
			openMovableView()
		}
	}
	
	@IBAction func panGestureRecognizerDidPressed(_ sender: UIPanGestureRecognizer) {
		let touchPoint = sender.location(in: sender.view?.superview)
		switch sender.state {
		case .began: break
		case .changed:
			UIView.beginAnimations(nil, context: nil)
			movableView.frame.origin.y = touchPoint.y
			UIView.commitAnimations()
			break
		case .ended, .failed, .cancelled:
			if touchPoint.y < UIScreen.main.bounds.height/2 {
				openMovableView()
			}
			else {
				closeMovableView()
			}
			break
		default: break
		}

	}
}

// MARK: - Private func
fileprivate extension RouteResultViewController {
	func fetchRoutes() {
		let tuples = tourModel.placemarks.toTuple()
		//TODO: 修改寫法
		for tuple in tuples {
			let source = tuple.0
			let destination = tuple.1
			MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
				switch status {
				case .success(let directions):
					guard let route = directions.routes.first else { break }
					self.routes.append(route)
					break
				case .failure(let error): print(error); break
				}
			})
		}
	}
	
	func layoutPinViews() {
		for placemark in tourModel.placemarks {
			mapView.addAnnotation(placemark.pointAnnotation)
		}
	}
	
	func layoutPolylines() {
		for polyline in polylines {
			mapView.add(polyline, level: .aboveRoads)
		}
		let rect = MapMananger.boundingMapRect(polylines: polylines)
		mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsetsMake(10, 10, 10, 10), animated: false)
	}
	
	func layoutMovableView() {
		movableView.layer.cornerRadius = 22.0
		movableView.layer.masksToBounds = true
		constriantOfMovableViewHeight.constant = view.frame.height
	}
	
	func isOpen() -> Bool {
		return movableView.frame.origin.y == toppestY
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
extension RouteResultViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation is MKUserLocation {
			return nil
		}
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		pinView?.pinTintColor = .orange
		pinView?.canShowCallout = true
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = .orange
		renderer.lineWidth = 4.0
		return renderer
	}
}

// MARK: - UITableViewDataSource
extension RouteResultViewController: UITableViewDataSource {
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
		//TODO: 增加每個路線的 share
		return cell
	}
}

// MARK: UITableViewDelegate
extension RouteResultViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		closeMovableView()
		
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
extension RouteResultViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !tableView.frame.contains(touch.location(in: movableView))
	}
}
