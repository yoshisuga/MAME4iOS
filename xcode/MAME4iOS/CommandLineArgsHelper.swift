//
//  CommandLineArgsHelper.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 3/6/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Darwin

extension GameInfo {
    var gameInfoCommandLineArgsTitle: String {
        "\(gameName)-\(gameDriver)"
    }
}

@objcMembers class CommandLineArgsHelper: NSObject {
    
    let gameInfo: GameInfo
    
    init(gameInfo: GameInfo) {
        self.gameInfo = gameInfo
    }
    
    func commandLineArgs() -> String? {
        return UserDefaults.standard.string(forKey: gameInfo.gameInfoCommandLineArgsTitle)
    }
    
    func saveCommandLineArgs(_ args: String) {
        if args.isEmpty {
            UserDefaults.standard.removeObject(forKey: gameInfo.gameInfoCommandLineArgsTitle)
            return
        }
        UserDefaults.standard.set(args, forKey: gameInfo.gameInfoCommandLineArgsTitle)
    }
    
    func delete() {
        UserDefaults.standard.removeObject(forKey: gameInfo.gameInfoCommandLineArgsTitle)
    }
    
    var viewController: UIViewController {
        return UINavigationController(rootViewController: CommandLineArgsViewController(commandLineArgsHelper: self))
    }
}

class CommandLineArgsViewController: UIViewController {
    let commandLineArgsHelper: CommandLineArgsHelper

    let helpLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("Enter command line arguments when executing MAME. Note that this is for advanced users only.", comment: "")
        label.numberOfLines = 0
        return label
    }()
    let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.label.cgColor
        textView.layer.cornerRadius = 12.0
        #if os(tvOS)
        textView.font = UIFont(name: "Courier-Bold", size: 18)
        #else
        textView.font = UIFont(name: "Courier-Bold", size: UIFont.systemFontSize)
        #endif
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
        textView.autocorrectionType = .no
        return textView
    }()
    let saveButton = UIButton(type: .custom)
    
    init(gameInfo: GameInfo) {
        self.commandLineArgsHelper = CommandLineArgsHelper(gameInfo: gameInfo)
        super.init(nibName: nil, bundle: nil)
    }
    
    init(commandLineArgsHelper: CommandLineArgsHelper) {
        self.commandLineArgsHelper = commandLineArgsHelper
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    private func setupViews() {
        #if os(tvOS)
        view.backgroundColor = .black
        #else
        view.backgroundColor = .systemBackground
        #endif
        view.addSubview(helpLabel)
        helpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        helpLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        helpLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        view.addSubview(textView)
        textView.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 16).isActive = true
        textView.leadingAnchor.constraint(equalTo: helpLabel.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: helpLabel.trailingAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true
        saveButton.addTarget(self, action: #selector(saveButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.setTitleColor(.label, for: .normal)
        saveButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
        saveButton.backgroundColor = view.tintColor
        saveButton.layer.cornerRadius = 12.0
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8).isActive = true
        saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.title = NSLocalizedString("Command Line Arguments", comment: "")
    }
    
    private func loadData() {
        let args = commandLineArgsHelper.commandLineArgs()
        textView.text = args
    }
    
    @objc func saveButtonPressed(_ sender: UIButton) {
        commandLineArgsHelper.saveCommandLineArgs(textView.text)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
