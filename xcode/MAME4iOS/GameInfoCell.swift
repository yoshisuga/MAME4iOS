//
//  GameInfoCell
//  MAME4iOS
//
//  Created by ToddLa on 4/5/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

import Foundation
import UIKit

// Two different cell types, horz or vertical
//
// +-----------------+   +----------+-----------------+
// |                 |   |          |                 |
// |                 |   |  Image   | Text            |
// |      Image      |   |          |                 |
// |                 |   +----------+-----------------+
// |                 |
// +-----------------+
// |      Text       |
// |                 |
// +-----------------+
//

@objcMembers
class GameInfoCell : UICollectionViewCell {
    
    let text = UILabel()
    let image = UIImageView()
    
    var horizontal: Bool = true             // cell type horz or vert
    var textInsets: UIEdgeInsets = .zero    // insets used for text
    var selectScale: CGFloat = 1.0          // scale when selected
    var imageAspect: CGFloat = 0.0          // override the image aspect
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(text)
        contentView.addSubview(image)
        prepareForReuse()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _backgroundColor:UIColor?
    override var backgroundColor: UIColor? {
        set {
            _backgroundColor = newValue // save this color for selection/focus
            contentView.backgroundColor = _backgroundColor
        }
        get {
            return _backgroundColor
        }
    }
    
    var cornerRadius:CGFloat = 0.0 {
        didSet {
            // if the cell background is clear set the radius of the image only
            if contentView.backgroundColor == .clear || contentView.backgroundColor == nil {
                contentView.layer.cornerRadius = 0.0
                contentView.clipsToBounds = false
                image.layer.cornerRadius = cornerRadius
            }
            else {
                contentView.layer.cornerRadius = cornerRadius;
                contentView.clipsToBounds = cornerRadius != 0.0
                image.layer.cornerRadius = 0.0
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setNeedsLayout()
        
        horizontal = true
        backgroundColor = .clear
        cornerRadius = 0.0
        textInsets = UIEdgeInsets(top:4, left:8, bottom:4, right:8)
        isSelected = false
        selectScale = 1.0;

        text.text = nil
        text.attributedText = nil
        text.font = nil
        text.textColor = nil
        text.numberOfLines = 0
        text.lineBreakMode = .byTruncatingTail
        text.adjustsFontSizeToFitWidth = false
        text.textAlignment = .left

        image.image = nil;
        image.highlightedImage = nil
        image.contentMode = .scaleAspectFit
        image.layer.minificationFilter = CALayerContentsFilter.trilinear
        image.layer.minificationFilterBias = 0.0
        image.clipsToBounds = true
        #if os(tvOS)
            image.adjustsImageWhenAncestorFocused = true
        #endif
        
        stopWait()
        
        backgroundView = nil

        // remove any GRs
        while let gr = gestureRecognizers?.first {
            removeGestureRecognizer(gr)
        }
    }
    
    // MARK: wait
    
    func startWait() {
        guard !(image.subviews.last is UIActivityIndicatorView) else { return }
        let wait = UIActivityIndicatorView()
        wait.style = (bounds.size.width <= 100.0) ? .medium : .large
        wait.sizeToFit()
        
        wait.color = self.tintColor
        image.addSubview(wait)

        wait.translatesAutoresizingMaskIntoConstraints = false
        wait.centerXAnchor.constraint(equalTo:image.centerXAnchor).isActive = true
        wait.centerYAnchor.constraint(equalTo:image.centerYAnchor).isActive = true
        wait.startAnimating()
    }
    func stopWait() {
        if let view = image.subviews.last as? UIActivityIndicatorView {
            view.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var rect = bounds
        
        if let size = image.image?.size, size != .zero {
            // use imageAspect unless it is zero
            let aspect = (imageAspect != 0.0) ? imageAspect : (size.width / size.height)
            
            if horizontal {
                let image_w = floor(rect.height * aspect)
                image.frame = CGRect(x:0, y:0, width:image_w, height:rect.height)
                rect = rect.inset(by:UIEdgeInsets(top:0, left:image_w, bottom:0, right:0))
            }
            else {
                let image_h = floor(rect.width / aspect)
                image.frame = CGRect(x:0, y:0, width:rect.width, height:image_h)
                rect = rect.inset(by:UIEdgeInsets(top:image_h, left:0, bottom:0, right:0))
            }
        }
        
        rect = rect.inset(by:textInsets)
        if !horizontal {
            // align text to the top in vertical cell
            let text_h = text.sizeThatFits(rect.size).height
            rect = rect.inset(by:UIEdgeInsets(top:0, left:0, bottom:max(rect.height - text_h,0), right:0))
        }
        text.frame = rect

        #if os(tvOS)
        // move the text down (or right) if away from the image when focused
        if isFocused && image.adjustsImageWhenAncestorFocused && image.image != nil {
            if horizontal {
                let dx = image.focusedFrameGuide.layoutFrame.maxX - image.frame.maxX
                text.frame = rect.offsetBy(dx:dx, dy:0)
            }
            else {
                let dy = image.focusedFrameGuide.layoutFrame.maxY - image.frame.maxY
                text.frame = rect.offsetBy(dx:0, dy:dy)
            }
        }
        
        // remove the clipsToBounds on imageView so focus effect is not clipped
        if image.adjustsImageWhenAncestorFocused && image.clipsToBounds && cornerRadius != 0 {
            let rect = image.bounds
            image.image = UIGraphicsImageRenderer(size:rect.size).image() { ctx in
                UIBezierPath(roundedRect:rect, byRoundingCorners:.allCorners, cornerRadii:CGSize(width:cornerRadius, height:cornerRadius)).addClip()
                image.draw(rect)
            }
            image.clipsToBounds = false
            image.masksFocusEffectToContents = true
        }
        #endif
    }
    
    // MARK: blur
    
    func addBlur(_ style:UIBlurEffect.Style) {
        if backgroundView == nil {
            let blur = UIBlurEffect(style:style)
            let effectView = UIVisualEffectView(effect:blur)
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            effectView.frame = bounds
            backgroundView = effectView
        }
     }
    
    // MARK: focus and selection
    
    private func updateSelected() {
        let selected = isSelected || isFocused
        
        if image.image == nil || !(_backgroundColor == .clear || _backgroundColor == nil) {
            self.contentView.backgroundColor = selected ? tintColor.withAlphaComponent(0.333) : _backgroundColor
            return
        }
        
        #if os(iOS)
            image.layer.borderColor = tintColor.withAlphaComponent(0.800).cgColor
            image.layer.borderWidth = selected ? (cornerRadius / 4.0) : 0.0

            let scale = isHighlighted ? (2.0 - selectScale) : (selected ? selectScale : 1.0)
            image.transform = CGAffineTransform(scaleX: scale, y: scale);
        #endif
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelected()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateSelected()
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            self.updateSelected()
        }
    }
}

// MARK: GameInfoHeader - same as GameInfoCell

class GameInfoHeader : GameInfoCell {
    let expandCollapseButton: UIButton = {
       let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentMode = .scaleAspectFill
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.setImage(UIImage(systemName: "minus.square"), for: .normal)
        button.setImage(UIImage(systemName: "plus.square"), for: .selected)
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        return button
    }()
    
    #if os(tvOS)
    override var canBecomeFocused: Bool {
        return true
    }
    #endif
    
    var didToggleClosure: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(expandCollapseButton)
        NSLayoutConstraint.activate([
            expandCollapseButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            expandCollapseButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        expandCollapseButton.addTarget(self, action: #selector(expandCollapseButtonPressed(_:)), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func expandCollapseButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        didToggleClosure?()
    }
}

// MARK: GameInfoCellLayout - a subclass that will invalidate the layout (for real) on a size change

class GameInfoCellLayout : UICollectionViewFlowLayout {
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return super.shouldInvalidateLayout(forBoundsChange: newBounds) || (collectionView?.bounds.size ?? .zero) != newBounds.size
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        if let context = context as? UICollectionViewFlowLayoutInvalidationContext, let oldBounds = collectionView?.bounds {
            context.invalidateFlowLayoutDelegateMetrics = (oldBounds.size != newBounds.size) || context.invalidateFlowLayoutAttributes
        }
        return context
    }
}
