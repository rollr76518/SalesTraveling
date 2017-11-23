//
//  DynamicColorButton.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/23.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

@IBDesignable
class DynamicColorButton: UIButton {

	@IBInspectable
	var enableBackgroundColor: UIColor? {
		didSet {
			setBackgroundImage(UIImage.imageFromColor(enableBackgroundColor!), for: .normal)
		}
	}
	
	@IBInspectable
	var highlightedBackgroundColor: UIColor? {
		didSet {
			setBackgroundImage(UIImage.imageFromColor(highlightedBackgroundColor!), for: .highlighted)
		}
	}
	
	@IBInspectable
	var disableBackgroundColor: UIColor? {
		didSet {
			setBackgroundImage(UIImage.imageFromColor(disableBackgroundColor!), for: .disabled)
		}
	}
}
