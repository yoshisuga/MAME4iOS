//
//  UICollectionView+ZeroState.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 4/16/24.
//  Copyright © 2024 MAME4iOS Team. All rights reserved.
//

import UIKit

extension UICollectionView {
  
  @objc func showZeroState() {
    guard self.backgroundView == nil else { return }

    let backgroundView = UIView()
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    #if TARGET_APPSTORE
    titleLabel.text = "Welcome to ArcadeMania!"
    #else
    titleLabel.text = "Welcome to ArcadeMania!"
    #endif
    titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
    backgroundView.addSubview(titleLabel)
    let messageLabel = UILabel()
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.font = UIFont.systemFont(ofSize: 18)
    #if TARGET_APPSTORE
    messageLabel.text = "ROMs are needed to use ArcadeMania.\nUse the ➕ button to import ROMs from Files.\n\nYou can start by downloading ROMs available for free at mamedev.org."
    #else
    messageLabel.text = "ROMs are needed to use MAME.\nUse the ➕ button to import ROMs from Files.\n\nYou can start by downloading ROMs available for free at mamedev.org."
    #endif
    messageLabel.numberOfLines = 0
    backgroundView.addSubview(messageLabel)
    messageLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
    messageLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: 20).isActive = true
    messageLabel.leadingAnchor.constraint(equalTo: backgroundView.readableContentGuide.leadingAnchor, constant: 16).isActive = true
    messageLabel.trailingAnchor.constraint(equalTo: backgroundView.readableContentGuide.trailingAnchor, constant: -16).isActive = true

    titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -20).isActive = true
    
    let button = UIButton(type: .custom)
    button.setTitleColor(.label, for: .normal)
    button.setTitle("Download from mamedev.org", for: .normal)
    button.backgroundColor = tintColor
    button.layer.cornerRadius = 12
    button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
    button.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.addSubview(button)
    button.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
    button.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20).isActive = true
    button.addTarget(self, action: #selector(goToDownloadLink(_:)), for: .touchUpInside)    
    self.backgroundView = backgroundView
  }
  
  @objc func goToDownloadLink(_ sender: UIButton?) {
    Task {
      await UIApplication.shared.open(URL(string: "https://www.mamedev.org/roms")!)
    }
  }
}
