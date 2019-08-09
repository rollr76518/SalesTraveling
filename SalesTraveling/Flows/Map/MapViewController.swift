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
	
	enum SectionType: Int, CaseIterable {
		case source = 0
		case destination = 1
	}

	@IBOutlet var tableView: UITableView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var movableView: UIVisualEffectView!
	@IBOutlet var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet weak var topOfMovableView: NSLayoutConstraint!
	@IBOutlet weak var titleOfPlacemarks: UIBarButtonItem! {
		didSet {
			let attributed = [
				NSAttributedString.Key.foregroundColor: UIColor.black,
				NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.bold)]
			titleOfPlacemarks.title = "Placemarks".localized
			titleOfPlacemarks.setTitleTextAttributes(attributed, for: .disabled)
		}
	}
	@IBOutlet var barButtonItemSave: UIBarButtonItem!
	@IBOutlet var barButtonItemDone: UIBarButtonItem!
	@IBOutlet var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	
	private var viewModel = MapViewModel()
	private lazy var addressResultTableViewController = makeAddressResultTableViewController()
	private lazy var searchController: UISearchController = makeSearchController()
	private let locationManager = CLLocationManager()

	private var toppestY: CGFloat {
		return -(mapView.bounds.height - 20)
	}
	
	private var lowestY: CGFloat {
		return -80.0
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		let _ = searchController
		
		viewModel.delegate = self
		
		setupLocationManager()
		
		layoutLeftBarButtonItem()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		layoutMovableView()
	}
	
	//MARK: - IBActions
	@IBAction func tapGestureRecognizerDidPressed(_ sender: UITapGestureRecognizer) {
		viewModel.showTableView(show: !viewModel.shouldShowTableView)
	}
	
	@IBAction func panGestureRecognizerDidPressed(_ sender: UIPanGestureRecognizer) {
		let touchPoint = sender.location(in: mapView)
		switch sender.state {
		case .began:
			break
		case .changed:
			topOfMovableView.constant = -(mapView.bounds.height - touchPoint.y)
		case .ended, .failed, .cancelled:
			magnetTableView()
		default:
			break
		}
	}
	
	@IBAction func rightBarButtonItemDidPressed(_ sender: Any) {
		viewModel.saveCurrentTourToFavorite()
	}
	
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@objc
	func layoutLeftBarButtonItem() {
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let userTrackingBarButtonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
		toolbar.setItems([leftBarButtonItem(), flexibleSpace, titleOfPlacemarks, flexibleSpace, userTrackingBarButtonItem], animated: false)
	}
	
	private func leftBarButtonItem() -> UIBarButtonItem {
		return tableView.isEditing ? barButtonItemDone:barButtonItemEdit
	}
}

// MARK: - Lazy var func
private extension MapViewController {
	
	func makeAddressResultTableViewController() -> AddressResultTableViewController {
		guard let vc = UIStoryboard(name: "Locate", bundle: nil).instantiateViewController(withIdentifier: AddressResultTableViewController.identifier) as? AddressResultTableViewController else {
			fatalError("AddressResultTableViewController doesn't exist")
		}
		
		vc.delegate = self
		vc.mapView = mapView
		return vc
	}
	
	func makeSearchController() -> UISearchController {
		let searchController = UISearchController(searchResultsController: addressResultTableViewController)
		searchController.searchResultsUpdater = addressResultTableViewController
		searchController.delegate = self
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search".localized
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		return searchController
	}
}

//MARK: - AddressResultTableViewControllerProtocol
extension MapViewController: AddressResultTableViewControllerProtocol {
	
	func addressResultTableViewController(_ vc: AddressResultTableViewController, placemark: MKPlacemark) {
		searchController.searchBar.text = nil
		searchController.searchBar.resignFirstResponder()
		
		viewModel.add(placemark: placemark, completion: nil)
	}
	
	func favoritePlacemarksAtVC(_ vc: AddressResultTableViewController) -> [HYCPlacemark] {
		return viewModel.favoritePlacemarks()
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
	
	func setupLocationManager() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
	}
	
	func  magnetTableView() {
		let buffer = self.toolbar.bounds.height //覺得 44.0 是一個不錯的數值(一個 cell 高)
		if viewModel.shouldShowTableView {
			let shouldHide = (topOfMovableView.constant > (toppestY + buffer))
			viewModel.showTableView(show: !shouldHide)
		} else {
			let shouldShow = (topOfMovableView.constant < (lowestY - buffer))
			viewModel.showTableView(show: shouldShow)
		}
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
		pinView?.leftCalloutAccessoryView = UIButton(type: .contactAdd)
		pinView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = UIColor.blue.withAlphaComponent(0.35)
		renderer.lineWidth = 4.0
		return renderer
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		guard
			let annotation = view.annotation,
			let placemark = viewModel.placemark(at: annotation.coordinate)
			else {
				print("view.annotation is nil")
				return
		}
		switch control {
		case let left where left == view.leftCalloutAccessoryView:
			viewModel.addToFavorite(placemark)
		case let right where right == view.rightCalloutAccessoryView:
			let mapItems = [placemark.toMapItem]
			let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
			MKMapItem.openMaps(with: mapItems, launchOptions: options)
		default:
			break
		}
	}
}

// MARK: - UITableViewDataSource
extension MapViewController: UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return SectionType.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let type = SectionType(rawValue: section) else {
			return 0
		}
		switch type {
		case .source:
			return (viewModel.userPlacemark != nil) ? 1 : 0
		case .destination:
			return viewModel.placemarks.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		guard let type = SectionType(rawValue: indexPath.section) else {
			return cell
		}
		switch type {
		case .source:
			let placemark = viewModel.userPlacemark
			cell.textLabel?.text = "Source".localized + ": " + "Current location".localized
			cell.detailTextLabel?.text = placemark?.title
		case .destination:
			let placemark = viewModel.placemarks[indexPath.row]
			cell.textLabel?.text = "\(indexPath.row + 1). " + (placemark.name ?? "")
			cell.detailTextLabel?.text = placemark.title
		}
		return cell
	}
}

// MARK: UITableViewDelegate
extension MapViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		viewModel.showTableView(show: false)

		guard let type = SectionType(rawValue: indexPath.section) else {
			return
		}
		switch type {
		case .source:
			let placemark = viewModel.userPlacemark
			for annotation in mapView.annotations {
				if annotation.coordinate.latitude == placemark?.coordinate.latitude &&
					annotation.coordinate.longitude == placemark?.coordinate.longitude {
					mapView.selectAnnotation(annotation, animated: true)
				}
			}
		case .destination:
			let placemark = viewModel.placemarks[indexPath.row]
			for annotation in mapView.annotations {
				if annotation.coordinate.latitude == placemark.coordinate.latitude &&
					annotation.coordinate.longitude == placemark.coordinate.longitude {
					mapView.selectAnnotation(annotation, animated: true)
				}
			}
		}
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		guard let type = SectionType(rawValue: indexPath.section) else {
			return false
		}
		switch type {
		case .source:
			return false
		case .destination:
			return true
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			viewModel.deletePlacemark(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .automatic)
			//刪除完之後還要往上拉一格，因為文字排序要重設
			//TODO: 目前使用1秒是 workaround，應該要抓到正確的時機後 reload
			//這招沒用 https://stackoverflow.com/questions/3832474/uitableview-row-animation-duration-and-completion-callback
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				tableView.reloadSections([SectionType.destination.rawValue], with: .automatic)
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
			topOfMovableView.constant -= scrollView.contentOffset.y
			scrollView.contentOffset = CGPoint.zero
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		 magnetTableView()
	}
}

// MARK: - MapViewModelDelegate
extension MapViewController: MapViewModelDelegate {
	
	func viewModel(_ viewModel: MapViewModel, didUpdateUserPlacemark placemark: HYCPlacemark, from oldValue: HYCPlacemark?) {
		mapView.setUserTrackingMode(.follow, animated: false)
		tableView.reloadSections([SectionType.source.rawValue], with: .automatic)
	}
	
	func viewModel(_ viewModel: MapViewModel, didUpdatePlacemarks placemarks: [HYCPlacemark], oldValue: [HYCPlacemark]) {
		//清除現有資料，避免重覆
		let anntationsBesideUser = mapView.annotations.filter { (annotation) -> Bool in
			return (annotation.coordinate.latitude != viewModel.userPlacemark?.coordinate.latitude &&
				annotation.coordinate.longitude != viewModel.userPlacemark?.coordinate.longitude)
		}
		mapView.removeAnnotations(anntationsBesideUser)
		//載入最新的資料
		mapView.addAnnotations(placemarks.map({ (placemark) -> MKAnnotation in
			return placemark.pointAnnotation
		}))
		
		//刪除的話不進行更新
		if placemarks.count >= oldValue.count {
			tableView.reloadSections([SectionType.destination.rawValue], with: .automatic)
		}
	}
	
	func viewModel(_ viewModel: MapViewModel, isFetching: Bool) {
		if isFetching {
			HYCLoadingView.shared.show()
		} else {
			HYCLoadingView.shared.dismiss()
		}
	}
	
	func viewModel(_ viewModel: MapViewModel, didUpdatePolylines polylines: [MKPolyline]) {
		mapView.removeOverlays(mapView.overlays)
		mapView.addOverlays(polylines, level: .aboveRoads)
		let rect = MapMananger.boundingMapRect(polylines: polylines)
		let verticalInset = mapView.frame.height / 10
		let horizatonInset = mapView.frame.width / 10
		mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: verticalInset, left: horizatonInset, bottom: verticalInset, right: horizatonInset), animated: false)
	}

	func viewModel(_ viewModel: MapViewModel, didRecevice error: Error) {
		self.presentAlert(of: error.localizedDescription)
	}
	
	func viewModel(_ viewModel: MapViewModel, shouldShowTableView show: Bool) {
		func openMovableView() {
			UIView.animate(withDuration: 0.25) {
				self.topOfMovableView.constant = self.toppestY
				self.view.layoutIfNeeded()
			}
		}
		
		func closeMovableView() {
			UIView.animate(withDuration: 0.25) {
				self.topOfMovableView.constant = self.lowestY
				self.view.layoutIfNeeded()
			}
		}
		
		if show {
			openMovableView()
		} else {
			closeMovableView()
		}
	}
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
	
	private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status != .authorizedWhenInUse {
			manager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let deviceLocation = locations.first {
			viewModel.update(device: deviceLocation)
		}
		manager.stopUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("manager didFailWithError: \(error.localizedDescription)")
	}
}
