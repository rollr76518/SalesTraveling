//
//  CLLocationCoordinate2D+Extension.swift
//  SalesTraveling
//
//  Created by Ryan on 2018/7/18.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import CoreLocation.CLLocation

extension CLLocationCoordinate2D: Codable {
	
	enum CodingKeys: String, CodingKey {
		case latitude, longitude
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let latitude = try values.decode(Double.self, forKey: .latitude)
		let longitude = try values.decode(Double.self, forKey: .longitude)
		self.init(latitude: latitude, longitude: longitude)
	}
	
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(latitude, forKey: .latitude)
		try container.encode(longitude, forKey: .longitude)
	}
}
