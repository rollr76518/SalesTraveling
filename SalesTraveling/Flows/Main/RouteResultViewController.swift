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

	var placemarks: [MKPlacemark] = []
	var responses: [MKDirectionsResponse] = []
	@IBOutlet weak var mapView: MKMapView!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		if let firstObject = responses.first,
			let route = firstObject.routes.first {
			print("routes: \(firstObject.routes)")
			print("expectedTravelTime: \(route.expectedTravelTime)")
			print("distance: \(route.distance)")
			//南港車站 - 台北101
			//expectedTravelTime: 961.0
			//distance: 7692.0
			
			mapView.add(route.polyline, level: .aboveRoads)
			let rect = route.polyline.boundingMapRect
			mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
		}
		
		if let sourcePlacemark = placemarks.first,
			let destinationPlacemark = placemarks.last {
			mapView.addAnnotation(MapMananger.pointAnnotation(placemark: sourcePlacemark))
			mapView.addAnnotation(MapMananger.pointAnnotation(placemark: destinationPlacemark))
		}
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
