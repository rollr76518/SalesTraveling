//
//  UIAlertController+Extension.swift
//  showu_app_ios
//
//  Created by Hanyu on 2018/3/19.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit

extension UIAlertController {
	convenience init(title: String?, message: String?, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
		self.init(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default, handler: handler)
		self.addAction(action)
	}
}
