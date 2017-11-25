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
			setBackgroundImage(enableBackgroundColor?.toImage(), for: .normal)
		}
	}
	
	@IBInspectable
	var highlightedBackgroundColor: UIColor? {
		didSet {
			setBackgroundImage(highlightedBackgroundColor?.toImage(), for: .highlighted)
		}
	}
	
	@IBInspectable
	var disableBackgroundColor: UIColor? {
		didSet {
			setBackgroundImage(disableBackgroundColor?.toImage(), for: .disabled)
		}
	}
}
