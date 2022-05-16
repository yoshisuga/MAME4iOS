//
//  GameInfoController.swift
//  MAME4iOS
//
//  Created by Todd Laney on 5/8/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

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
    
    private let textView = UITextView()
    
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
        view.backgroundColor = UIColor.systemBackground
        #if os(iOS)
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:.done, target:self, action:#selector(done))
            textView.isEditable = false
            textView.isSelectable = false
        #else
            let dx = UIScreen.main.bounds.width/4
            textView.textContainerInset.left = dx
            textView.textContainerInset.right = dx
        
            // TODO: I tried and tried to get the focus engine to give focus to the UITextView
            // but I gave up, and am just gonna do a manual pan gesture handler and scroll myself!!
            let pan = UIPanGestureRecognizer(target:self, action:#selector(pan(_:)))
            pan.allowedTouchTypes = [NSNumber(value:UITouch.TouchType.indirect.rawValue)]
            view.addGestureRecognizer(pan)
        #endif
        
        textView.isScrollEnabled = true
        textView.backgroundColor = .init(white: 0.111, alpha: 1.0)
        view.addSubview(textView)
        setupConstraints()

        let text = NSMutableAttributedString(string:"")
        
        if let image = UIImage(contentsOfFile:game.gameLocalImageURL.path) {
            // TODO: scale the image if it is too big?
            text.append(NSAttributedString(image:image).centered)
            text.append(NSAttributedString(string:"\n\n"))
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
            
        textView.attributedText = text
    }
    
    private func setupConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
#if os(iOS)
    @objc func done() {
        presentingViewController?.dismiss(animated: true)
    }
#else
    @objc func pan(_ pan:UIPanGestureRecognizer) {
        let translation = pan.translation(in:view)
        pan.setTranslation(.zero, in:view)
        
        guard abs(translation.y) >= abs(translation.x) else { return }
        
        var contentOffset = textView.contentOffset
        contentOffset.y -= translation.y;
        if (pan.state == .ended) {
            contentOffset.y = max(0.0, min(textView.contentSize.height - textView.bounds.size.height, contentOffset.y))
            textView.setContentOffset(contentOffset, animated:true)
        }
        else {
            textView.setContentOffset(contentOffset, animated:false)
        }
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

