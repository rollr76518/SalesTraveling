//
//  AlertManager.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/12/3.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

class AlertManager {
	class func basicAlert(title: String, message: String) -> UIAlertController {
		let alert = alertWithHandler(title: title, message: message, handler: nil)
		return alert
	}
	
	class func alertWithHandler(title: String, message: String, handler: ((UIAlertAction) -> Swift.Void)? = nil) -> UIAlertController {
		let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction.init(title: "OK", style: .default, handler: handler)
		alert.addAction(action)
		return alert
	}
}
