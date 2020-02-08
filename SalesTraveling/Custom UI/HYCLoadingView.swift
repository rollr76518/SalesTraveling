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
	
	private lazy var backgroundView = makeTranslucentView()
	private lazy var activityIndicatorView = makeActivityIndicatorView()
}

extension HYCLoadingView {
	
	func show() {
		guard let mainWindow = UIApplication.shared.windows.first else { return }
		mainWindow.insertSubview(backgroundView, at: mainWindow.subviews.count)
		NSLayoutConstraint.activate([
			backgroundView.topAnchor.constraint(equalTo: mainWindow.topAnchor),
			backgroundView.bottomAnchor.constraint(equalTo: mainWindow.bottomAnchor),
			backgroundView.leadingAnchor.constraint(equalTo: mainWindow.leadingAnchor),
			backgroundView.trailingAnchor.constraint(equalTo: mainWindow.trailingAnchor)
			])
	}
	
	func startIndicatorAnimation() {
		activityIndicatorView.startAnimating()
	}
	
	func stopIndicatorAnimation() {
		activityIndicatorView.stopAnimating()
	}
	
	func dismiss() {
		backgroundView.removeFromSuperview()
	}
}

extension HYCLoadingView {
	
	private func makeTranslucentView() -> UIView {
		let view = UIView(frame: .zero)
		view.backgroundColor = .black
		view.alpha = 0.65
		view.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(activityIndicatorView)
		NSLayoutConstraint.activate([
			activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
			])
		return view
	}
	
	private func makeActivityIndicatorView() -> UIActivityIndicatorView {
		let view = UIActivityIndicatorView(style: .whiteLarge)
		view.startAnimating()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}
}
