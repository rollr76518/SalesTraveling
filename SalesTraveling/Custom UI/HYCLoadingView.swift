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
		let view = UIVisualEffectView(frame: .zero)
		view.effect = UIBlurEffect(style: .dark)
		addActivityIndicatorView(to: view.contentView)
		return view
	}
	
	func createTranslucentView() -> UIView {
		let view = UIView(frame: .zero)
		view.backgroundColor = .gray
		view.alpha = 0.7
		addActivityIndicatorView(to: view)
		return view
	}
	
	func addActivityIndicatorView(to superView: UIView) {
		let view = UIActivityIndicatorView(style: .whiteLarge)
		view.startAnimating()
		superView.addSubview(view)
		view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			view.centerXAnchor.constraint(equalTo: superView.centerXAnchor),
			view.centerYAnchor.constraint(equalTo: superView.centerYAnchor)
			])
	}
	
}

extension HYCLoadingView {
	func show() {
		guard let mainWindow = UIApplication.shared.windows.first else { return }
		mainWindow.insertSubview(backgroundView, at: mainWindow.subviews.count)
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			backgroundView.topAnchor.constraint(equalTo: mainWindow.topAnchor),
			backgroundView.bottomAnchor.constraint(equalTo: mainWindow.bottomAnchor),
			backgroundView.leadingAnchor.constraint(equalTo: mainWindow.leadingAnchor),
			backgroundView.trailingAnchor.constraint(equalTo: mainWindow.trailingAnchor)
			])
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
