//
//  UIViewController+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit.UIViewController

extension UIViewController {
	
	class var identifier: String {
		return String(describing: self)
	}
}
