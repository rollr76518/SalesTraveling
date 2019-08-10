//
//  UIImage+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/15.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import UIKit

extension UIImage {
	
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
}
