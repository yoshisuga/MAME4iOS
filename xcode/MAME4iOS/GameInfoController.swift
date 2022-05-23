//
//  GameInfoController.swift
//  MAME4iOS
//
//  Created by Todd Laney on 5/8/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

#if os(tvOS)
class TVOSScrollView: UIScrollView {
    override var canBecomeFocused: Bool { true }
}
#endif

@objcMembers class GameInfoController : UIViewController {

    private let attributes : [UIFont.TextStyle:[NSAttributedString.Key:Any]] = [
        .largeTitle: [
            .font:UIFont.systemFont(ofSize:UIFont.preferredFont(forTextStyle:.body).pointSize * 2, weight:.heavy),
            .foregroundColor:UIColor.white,
            .paragraphStyle: NSParagraphStyle.center,
        ],
        .headline: [
            .font:UIFont.preferredFont(forTextStyle:.headline),
            .foregroundColor:UIColor.white,
        ],
        .body: [
            .font:UIFont.preferredFont(forTextStyle:.body),
            .foregroundColor:UIColor.lightGray,
        ]
    ]
    
    private let game:GameInfo
    
    #if os(tvOS)
    private let scrollView = TVOSScrollView()
    #else
    private let scrollView = UIScrollView()
    #endif
    private let contentView = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()
        
    init(game:GameInfo) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
        title = "Info"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(iOS)
            view.backgroundColor = UIColor.systemBackground
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:.done, target:self, action:#selector(done))
        #else
        scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.backgroundColor = UIColor.black
        #endif
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        label.backgroundColor = .init(white: 0.111, alpha: 1.0)
        label.numberOfLines = 0
        contentView.addSubview(label)
        setupConstraints()

        let text = NSMutableAttributedString(string:"")
        
        if let image = UIImage(contentsOfFile:game.gameLocalImageURL.path) {
            imageView.image = image
        }
        
        // TODO: swiftify GameInfo so we dont need a ugly cast to [String:String]
        text.append(ChooseGameController.getGameText(game as? [String:String]))
        text.append(NSAttributedString(string:"\n\n"))

        text.append(getMetaText())

        if let info = getInfoText("history") {
            text.append(NSAttributedString(string:"History\n", attributes:attributes[.largeTitle]))
            text.append(info)
        }
            
        if let info = getInfoText("mameinfo") {
            text.append(NSAttributedString(string:"MAME Info\n", attributes:attributes[.largeTitle]))
            text.append(info)
        }
            
        label.attributedText = text
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        #if os(tvOS)
        let scrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        let labelHorizontalConstraints = [
            label.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        #else
        let scrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        let labelHorizontalConstraints = [
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ]
        #endif
        
        var constraints = [
            scrollViewTopConstraint,
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 400),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        constraints.append(contentsOf: labelHorizontalConstraints)
        NSLayoutConstraint.activate(constraints)
    }
    
#if os(iOS)
    @objc func done() {
        presentingViewController?.dismiss(animated: true)
    }
#endif
}

private extension GameInfoController {

    func getMetaText() -> NSAttributedString {
        
        let text = NSMutableAttributedString()
        
        var keyWidth = 0.0
        let keys = (game.allKeys as? [String]) ?? []
        for key in keys.sorted(by:<) {
            guard var val = game[key] as? String, !val.isEmpty else { continue }
            if val.contains(",") && !val.contains(", ") {
                val = val.replacingOccurrences(of: ",", with: ", ")
            }
            let keyText = NSAttributedString(string:"\(key)\t", attributes:attributes[.headline])
            let valText = NSAttributedString(string:"\(val)\n", attributes:attributes[.body])

            text.append(keyText)
            text.append(valText)
            keyWidth = max(keyWidth, ceil(keyText.size().width))
        }
        keyWidth += 4.0;

        let para = NSMutableParagraphStyle()
        para.tabStops = [NSTextTab(textAlignment:.left, location:keyWidth)]
        para.defaultTabInterval = keyWidth
        para.headIndent = keyWidth
        para.firstLineHeadIndent = 0
        para.paragraphSpacing = 0
        
        text.addAttribute(.paragraphStyle, value:para, range:NSRange(location:0, length:text.length))
        
        return text;
    }
    
    func getInfoText(_ name:String) -> NSAttributedString?
    {
        let db = InfoDatabase(path: getDocumentPath("dats/\(name).dat"))

        return db.attributedString(forKey:game.gameName, attributes:attributes) ??
               db.attributedString(forKey:game.gameParent, attributes:attributes)
    }
}

private extension NSAttributedString {
    convenience init(image:UIImage) {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        self.init(attachment: imageAttachment)
    }
}

private extension NSParagraphStyle {
    class var center : NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return paragraph
    }
}
private extension NSAttributedString {
    var centered:NSAttributedString {
        let text = NSMutableAttributedString(attributedString:self)
        text.addAttribute(.paragraphStyle, value:NSParagraphStyle.center, range:NSRange(location:0, length:text.length))
        return text
    }
}

#if os(tvOS)
extension UIFont.TextStyle {
    // HACK: re-use callout as largeTitle on tvOS
    static let largeTitle = UIFont.TextStyle.callout
}
#endif

