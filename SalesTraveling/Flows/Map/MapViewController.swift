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
		case result = 0
		case source = 1
		case destination = 2
	}

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var mapView: MKMapView! {
		didSet {
			mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.ClassName)
		}
	}
	@IBOutlet weak var movableView: UIVisualEffectView!
	@IBOutlet weak var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet weak var movableViewTopToMapViewBottom: NSLayoutConstraint!
	@IBOutlet weak var barButtonItemDone: UIBarButtonItem!
	@IBOutlet weak var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var segmentedControl: UISegmentedControl! {
		didSet {
			segmentedControl.setTitle("Distance".localized, forSegmentAt: 0)
			segmentedControl.setTitle("Time".localized, forSegmentAt: 1)
		}
	}
	
	private var viewModel = MapViewModel()
	private lazy var addressResultTableViewController = makeAddressResultTableViewController()
	private lazy var searchController = makeSearchController()
	private let locationManager = CLLocationManager()
	private var shouldUpdateLocation = true
	
	private let heightOfUnit: CGFloat = 44.0
	private var switchOnConstantOfMovableView: CGFloat {
		return -(mapView.bounds.height - heightOfUnit)
	}
	
	private var switchOffConstantOfMovableView: CGFloat {
		return -heightOfUnit * 2
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
			movableViewTopToMapViewBottom.constant = -(mapView.bounds.height - touchPoint.y)
		case .ended, .failed, .cancelled:
			magnetTableView()
		default:
			break
		}
	}
	
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@objc
	func layoutLeftBarButtonItem() {
		func frameOfSegmentedControl(frame: CGRect, superframe: CGRect) -> CGRect {
			var newframe = frame
			newframe.size.width = superframe.width/2
			return newframe
		}
		segmentedControl.frame = frameOfSegmentedControl(frame: segmentedControl.frame, superframe: toolbar.frame)
		let container = UIBarButtonItem(customView: segmentedControl)
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let userTrackingBarButtonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
		toolbar.setItems([leftBarButtonItem(), flexibleSpace, container, flexibleSpace, userTrackingBarButtonItem], animated: false)
	}
	
	private func leftBarButtonItem() -> UIBarButtonItem {
		return tableView.isEditing ? barButtonItemDone:barButtonItemEdit
	}
	
	@IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
		let index = sender.selectedSegmentIndex
		guard let preferResult = MapViewModel.PreferResult(rawValue: index) else { return }
		viewModel.set(preferResult: preferResult)
	}
}

// MARK: - Lazy var func
private extension MapViewController {
	
	func makeAddressResultTableViewController() -> AddressResultTableViewController {
		guard let vc = UIStoryboard(name: "AddressResult", bundle: nil).instantiateViewController(withIdentifier: AddressResultTableViewController.ClassName) as? AddressResultTableViewController else {
			fatalError("AddressResultTableViewController doesn't exist")
		}
		vc.dataSource = self
		vc.delegate = self
		return vc
	}
	
	func makeSearchController() -> UISearchController {
		let searchController = UISearchController(searchResultsController: addressResultTableViewController)
		searchController.searchResultsUpdater = addressResultTableViewController
		searchController.delegate = self
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search".localized
		if #available(iOS 13.0, *) {
			searchBar.searchTextField.backgroundColor = .white
		} else {
			// Fallback on earlier versions
		}
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		return searchController
	}
}

//MARK: - AddressResultTableViewControllerDataSource
extension MapViewController: AddressResultTableViewControllerDataSource {
	
	func mapView(for vc: AddressResultTableViewController) -> MKMapView {
		return mapView
	}

	func favoritePlacemarks(for vc: AddressResultTableViewController) -> [HYCPlacemark] {
		return viewModel.favoritePlacemarks()
	}
}

//MARK: - AddressResultTableViewControllerDelegate
extension MapViewController: AddressResultTableViewControllerDelegate {

	func viewController(_ vc: AddressResultTableViewController, didSelectAt placemark: HYCPlacemark) {
		searchController.searchBar.text = nil
		searchController.searchBar.resignFirstResponder()
		
		viewModel.add(placemark: placemark, completion: nil)
	}
	
	func viewController(_ vc: AddressResultTableViewController, didRecevice error: Error) {
		print(error.localizedDescription)
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
			let shouldHide = (movableViewTopToMapViewBottom.constant > (switchOnConstantOfMovableView + buffer))
			viewModel.showTableView(show: !shouldHide)
		} else {
			let shouldShow = (movableViewTopToMapViewBottom.constant < (switchOffConstantOfMovableView - buffer))
			viewModel.showTableView(show: shouldShow)
		}
	}
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		if shouldUpdateLocation, let deviceLocation = userLocation.location {
			shouldUpdateLocation = false
			viewModel.update(device: deviceLocation)
		}
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard let annotation = annotation as? HYCAnntation else { return nil }
		let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.ClassName, for: annotation) as? MKMarkerAnnotationView
		annotationView?.canShowCallout = true
		annotationView?.leftCalloutAccessoryView = UIButton(type: .contactAdd)
		annotationView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
		annotationView?.titleVisibility = .adaptive
		annotationView?.markerTintColor = .brand
		annotationView?.glyphTintColor = .white
		annotationView?.displayPriority = .required
		annotationView?.glyphText = "\(annotation.sorted)"
		return annotationView
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = UIColor.brand.withAlphaComponent(0.65)
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
			// TODO: 提示使用者已加到搜尋紀錄，以便快速搜尋。
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
		case .result:
			return (viewModel.tourModel != nil) ? 1 : 0
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
		case .result:
			let cell2 = UITableViewCell(style: .default, reuseIdentifier: nil)
			cell2.textLabel?.text = viewModel.result
			return cell2
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
		case .result:
			break
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
		case .result:
			return false
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
			movableViewTopToMapViewBottom.constant -= scrollView.contentOffset.y
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
		guard oldValue != placemark else {
			return
		}
		tableView.reloadSections([SectionType.source.rawValue], with: .automatic)
	}
	
	func viewModel(_ viewModel: MapViewModel, reload placemarks: [HYCPlacemark]) {
	
		mapView.removeAnnotations(mapView.annotations)
		let annotations = viewModel.placemarks.enumerated().map { (arg0) -> HYCAnntation in
			let (offset, element) = arg0
			return HYCAnntation(placemark: element, sorted: offset + 1)
		}
		mapView.addAnnotations(annotations)
		
		
		tableView.reloadData()
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
		if polylines.count > 0 {
			let rect = MapMananger.boundingMapRect(polylines: polylines)
			let verticalInset = mapView.frame.height / 10
			let horizatonInset = mapView.frame.width / 10
			let edgeInsets = UIEdgeInsets(top: verticalInset, left: horizatonInset, bottom: verticalInset + (heightOfUnit * 2), right: horizatonInset) // TODO: 88 為 lowestY, 應該綁在一起
			mapView.setVisibleMapRect(rect, edgePadding: edgeInsets, animated: false)
		} else {
			mapView.showAnnotations([mapView.userLocation], animated: true)
		}
	}

	func viewModel(_ viewModel: MapViewModel, didRecevice error: Error) {
		self.presentAlert(of: error.localizedDescription)
	}
	
	func viewModel(_ viewModel: MapViewModel, shouldShowTableView show: Bool) {
		func openMovableView() {
			UIView.animate(withDuration: 0.25) {
				self.movableViewTopToMapViewBottom.constant = self.switchOnConstantOfMovableView
				self.view.layoutIfNeeded()
			}
		}
		
		func closeMovableView() {
			UIView.animate(withDuration: 0.25) {
				self.movableViewTopToMapViewBottom.constant = self.switchOffConstantOfMovableView
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
		mapView.setUserTrackingMode(.follow, animated: true)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("manager didFailWithError: \(error.localizedDescription)")
	}
}
