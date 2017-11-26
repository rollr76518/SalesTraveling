//
//  AlgorithmManager.swift
//  SalesTraveling
//
//  Created by Ryan on 2017/11/11.
//  Copyright © 2017年 Hanyu. All rights reserved.
//

import Foundation

class AlgorithmManager {
    class func between<T>(_ object: T, _ objects: [T]) -> [[T]] {
        guard let (head, tail) = objects.decompose() else { return [[object]] }
        return [[object] + objects] + between(object, tail).map { [head] + $0 }
    }
    
    class func permutations<T>(_ objects: [T]) -> [[T]] {
        guard let (head, tail) = objects.decompose() else { return [[]] }
        return permutations(tail).flatMap { between(head, $0) }
    }
    
    class func factorial(_ number: Int) -> Int {
        if number == 1 { return 1 }
        return number * factorial(number - 1)
    }
}
