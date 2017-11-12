//
//  Array+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/11.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import Foundation

extension Array {
    func decompose() -> (Iterator.Element, [Iterator.Element])? {
        guard let first = first else { return nil }
        return (first, Array(self[1..<count]))
    }
}
