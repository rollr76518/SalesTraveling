//
//  UIView+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/25.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

extension UIView {
	
	func toImage() -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: bounds.size)
		let image = renderer.image { context in
			drawHierarchy(in: bounds, afterScreenUpdates: true)
		}
		return image
	}
}
