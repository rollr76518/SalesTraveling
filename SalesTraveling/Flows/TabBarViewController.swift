//
//  TabBarViewController.swift
//  SalesTraveling
//
//  Created by Ryan on 2018/5/30.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
	
	lazy var searchTab = createNavigationControllerOfSearchTab()
	lazy var favoritesTab = createNavigationControllerOfFavoritesTab()

    override func viewDidLoad() {
        super.viewDidLoad()

		setViewControllers([searchTab, favoritesTab], animated: false)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		let favoriteTours = DataManager.shared.favoriteTours()
		favoritesViewController.tourModels = favoriteTours
	}
}

private extension TabBarViewController {
	func createNavigationControllerOfSearchTab() -> UINavigationController {
		let nvc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
		return nvc
	}
	
	func createNavigationControllerOfFavoritesTab() -> UINavigationController {
		let nvc = UIStoryboard(name: "Favorites", bundle: nil).instantiateInitialViewController() as! UINavigationController
		return nvc
	}
	
	var favoritesViewController: TourListViewController	{
		let vc = favoritesTab.viewControllers.first as! TourListViewController
		return vc
	}
}
