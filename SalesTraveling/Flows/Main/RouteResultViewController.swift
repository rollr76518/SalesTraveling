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
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		for polyline in tourModel.polylines {
			mapView.add(polyline, level: .aboveRoads)
		}
		
		for placemark in tourModel.placemarks {
			mapView.addAnnotation(MapMananger.pointAnnotation(placemark: placemark))
		}
		
		let rect = tourModel.boundingMapRect
		mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
    }
}

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
