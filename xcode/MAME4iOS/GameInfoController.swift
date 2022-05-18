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
        super.init(nibName:nil, bundle:nil)
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
            textView.isEditable = false
            textView.isSelectable = false
            textView.textContainerInset.left = 8
            textView.textContainerInset.right = 8
        #else
            view.backgroundColor = UIColor(white: 0.111, alpha: 1.0)
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
        textView.contentInsetAdjustmentBehavior = .never
        textView.backgroundColor = nil
        view.addSubview(textView)
        setupConstraints()

        let text = NSMutableAttributedString(string:"")

        // get the title image for the game, and scale it down if it is too big.
        var image = ChooseGameController.getGameIcon(game)
        if let window = (UIApplication.shared.value(forKey:"keyWindow") as? UIWindow) {
            let maxWidth = window.bounds.size.width - (textView.textContainerInset.left + textView.textContainerInset.right + 16)
            if image.size.width > maxWidth {
                image = image.resize(to: CGSize(width:maxWidth, height:0))
            }
        }
        text.append(NSAttributedString(image:image).centered)
        text.append(NSAttributedString(string:"\n\n"))
        
        text.append(ChooseGameController.getGameText(game))
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
        let dict = game.gameDictionary
        for key in dict.keys.sorted(by:<) {
            guard var val = dict[key], !val.isEmpty else { continue }
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

// TODO: put this somewhere else? ImageCache?
private extension UIImage {
    /**
    resize UIImage to given size in points.
    if size == (0,0) no resizing will be done.
    if width or height is 0 it is computed via aspect ratio.
    */
    func resize(to size:CGSize) -> UIImage {
        var size = size
        
        if size.width == 0 && size.height == 0 {
            return self
        } else if size.width == 0 {
            size.width = floor(size.height * self.size.width / self.size.height)
        } else if size.height == 0 {
            size.height = floor(size.width * self.size.height / self.size.width)
        }
        
        return UIGraphicsImageRenderer(size:size).image { ctx in
            self.draw(in: CGRect(origin:.zero, size:size))
        }
    }
}

#if os(tvOS)
extension UIFont.TextStyle {
    // HACK: re-use callout as largeTitle on tvOS
    static let largeTitle = UIFont.TextStyle.callout
}
#endif

