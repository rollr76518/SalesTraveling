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
				for polyline in polylines {
					mapView.add(polyline, level: .aboveRoads)
				}
				
				let rect = boundingMapRect
				mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
			}
		}
	}
	var polylines: [MKPolyline] {
		return routes.map{ $0.polyline }
	}
	var boundingMapRect: MKMapRect {
		var westPoint: Double?
		var northPoint: Double?
		var eastPoint: Double?
		var southPoint: Double?
		
		for polyline in polylines {
			if let west = westPoint, let north = northPoint, let east = eastPoint, let south = southPoint {
				
				if polyline.boundingMapRect.origin.x < west {
					westPoint = polyline.boundingMapRect.origin.x
				}
				if polyline.boundingMapRect.origin.y < north {
					northPoint = polyline.boundingMapRect.origin.y
				}
				if polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width > east {
					eastPoint = polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width
				}
				if polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height > south {
					southPoint = polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height
				}
			}
			else {
				westPoint = polyline.boundingMapRect.origin.x
				northPoint = polyline.boundingMapRect.origin.y
				eastPoint = polyline.boundingMapRect.origin.x + polyline.boundingMapRect.size.width
				southPoint = polyline.boundingMapRect.origin.y + polyline.boundingMapRect.size.height
			}
		}
		
		print("westPoint\(westPoint)")
		print("northPoint\(northPoint)")
		print("eastPoint\(eastPoint)")
		print("southPoint\(southPoint)")

		return MKMapRect.init(origin: MKMapPointMake(westPoint!, northPoint!), size: MKMapSizeMake(eastPoint! - westPoint!, southPoint! - northPoint!))
	}
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let tuples = PermutationManager.toTuple(tourModel.placemarks)
		
		for tuple in tuples {
			let source = tuple.0
			let destination = tuple.1
			MapMananger.calculateDirections(from: source, to: destination, completion: { (status) in
				switch status {
				case .success(let directions):
					guard let route = directions.routes.first else {
						print(directions)
						break
					}
					self.routes.append(route)
					break
				case .failure(let error): print(error); break
				}
			})
		}
		
		for placemark in tourModel.placemarks {
			mapView.addAnnotation(MapMananger.pointAnnotation(placemark: placemark))
		}
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
