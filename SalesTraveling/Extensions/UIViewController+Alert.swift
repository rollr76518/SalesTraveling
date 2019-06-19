//
//  UIViewController+Alert.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/19.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import UIKit

extension UIViewController {
	
	func presentAlert(of message: String) {
		let alert = UIAlertController(title: "Prompt".localized, message: message)
		present(alert, animated: true, completion: nil)
	}
}
