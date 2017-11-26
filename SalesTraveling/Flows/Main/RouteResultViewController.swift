//
//  RouteResultViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2017/10/22.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit
import MapKit

class RouteResultViewController: UIViewController {
	
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		fetchRoutes()
		layoutPinViews()
	}
}

// MARK: - Private func
fileprivate extension RouteResultViewController {
	func fetchRoutes() {
		let tuples = tourModel.placemarks.toTuple()
		
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
		mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
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
