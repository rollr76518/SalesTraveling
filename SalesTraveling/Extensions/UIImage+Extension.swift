//
//  UIImage+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/15.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageFromView(_ view: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    func crop(rect: CGRect) -> UIImage? {
        var scaledRect = rect
        scaledRect.origin.x *= scale
        scaledRect.origin.y *= scale
        scaledRect.size.width *= scale
        scaledRect.size.height *= scale
        guard let imageRef: CGImage = cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    }
	
	class func imageFromColor(_ color: UIColor) -> UIImage {
		let size = CGSize.init(width: 1, height: 1)
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image(actions: { rendererContext in
			color.setFill()
			rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
		})
	}
}
