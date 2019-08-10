//
//  HYCPlacemark+PostalAddress.swift
//  SalesTraveling
//
//  Created by Ryan on 2019/6/19.
//  Copyright © 2019 Hanyu. All rights reserved.
//

import Contacts.CNPostalAddress

extension HYCPlacemark {
	
	var toPostalAddress: CNPostalAddress {
		let postalAddress = CNMutablePostalAddress()
		postalAddress.street = street ?? ""
		postalAddress.city = city ?? ""
		postalAddress.state = state ?? ""
		postalAddress.postalCode = postalCode ?? ""
		postalAddress.country = country ?? ""
		postalAddress.isoCountryCode = isoCountryCode ?? ""
		postalAddress.subAdministrativeArea = subAdministrativeArea ?? ""
		postalAddress.subLocality = subLocality ?? ""
		return postalAddress.copy() as! CNPostalAddress
	}
	
}
