//
//  InformationViewController.swift
//  SalesTraveling
//
//  Created by Hanyu on 2018/7/24.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit

class InformationViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension InformationViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
}

extension InformationViewController: UITableViewDelegate {
	
}
