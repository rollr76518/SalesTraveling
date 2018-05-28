//
//  UIViewController+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

extension UIViewController {
	class var identifier: String {
		return String(describing: self)
	}
	
	func presentAlert(of message: String) {
		let alert = UIAlertController(title: "Prompt".localized, message: message)
		present(alert, animated: true, completion: nil)
	}
}
