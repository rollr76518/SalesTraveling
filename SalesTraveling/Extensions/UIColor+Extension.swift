//
//  UIColor+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/25.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

extension UIColor {
	static let brand = #colorLiteral(red: 0.1764705882, green: 0.168627451, blue: 0.3411764706, alpha: 1)
}

extension UIColor {
	func toImage() -> UIImage {
		let size = CGSize(width: 1, height: 1)
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image(actions: { rendererContext in
			setFill()
			rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
		})
	}
}
