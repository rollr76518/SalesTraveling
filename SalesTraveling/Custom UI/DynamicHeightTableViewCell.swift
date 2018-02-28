//
//  DynamicHeightTableViewCell.swift
//  SalesTraveling
//
//  Created by Ryan on 2018/2/28.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit

class DynamicHeightTableViewCell: UITableViewCell {

	@IBOutlet var labelTitle: UILabel!
	@IBOutlet var labelSubtitle: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
