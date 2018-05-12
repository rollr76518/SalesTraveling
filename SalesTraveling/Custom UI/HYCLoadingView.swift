//
//  HYCLoadingView.swift
//  IndicatorPractice
//
//  Created by Ryan on 2018/5/12.
//  Copyright © 2018年 Hanyu. All rights reserved.
//

import UIKit

class HYCLoadingView {
	static let shared = HYCLoadingView()
	
	private lazy var backgroundView = createTranslucentView()
	private var activityIndicatorView: UIActivityIndicatorView? = nil
}

private extension HYCLoadingView {
	func createVisualEffectView() -> UIVisualEffectView {
		let view = UIVisualEffectView(frame: UIScreen.main.bounds)
		view.effect = UIBlurEffect(style: .dark)
		addActivityIndicatorView(to: view.contentView)
		return view
	}
	
	func createTranslucentView() -> UIView {
		let view = UIView(frame: UIScreen.main.bounds)
		view.backgroundColor = .gray
		view.alpha = 0.7
		addActivityIndicatorView(to: view)
		return view
	}
	
	func addActivityIndicatorView(to superView: UIView) {
		let view = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
		view.startAnimating()
		view.center = superView.center
		superView.addSubview(view)
	}
	
}

extension HYCLoadingView {
	func show() {
		guard let topWindow = UIApplication.shared.windows.last else { return }
		topWindow.insertSubview(backgroundView, at: topWindow.subviews.count)
	}
	
	func startIndicatorAnimation() {
		activityIndicatorView?.startAnimating()
	}
	
	func stopIndicatorAnimation() {
		activityIndicatorView?.stopAnimating()
	}
	
	func dismiss() {
		backgroundView.removeFromSuperview()
	}
}
