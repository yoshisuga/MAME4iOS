//  TVAlertController.swift
//  Wombat
//
//  implement a custom UIAlertController for tvOS, using a UIStackView full of buttons and some duct tape.
//
//  Oh it also works on iOS...
//
//  **NOTE** this file "takes over" (aka mocks) the UIAlertController class
//
//  if you use UIAlertController(title:message:preferredStyle:) from Swift
//  OR [UIAlertController alertControllerWithTitle:message:preferredStyle:] from ObjC
//  you will really be creating a TVAlertController, that is API compatible with an UIAlertController
//
//  TVAlertController also adds a few extra extra things....
//      * setProgress
//          - add a progress bar
//      * dismissWithAction, dismissWithDefault, dismissWithCancel, cancelAction
//          - helper functions to dismiss a UIAlertController/TVAlertController
//          - onDismiss handler and cancelAction, will always be called on dismiss of any kind.
//      * addButton, addButons, addToolbar, etc
//          - more flexible way to add buttons to TVAlertController
//          - multiple buttons per row, custom colors, etc
//      * addText, addTitle, addControl
//          - add non-buttons too.
//      * addValue
//          - add a user tweakable float value, with a title
//          - uses a UISlider, UISwitch on iOS. and a UIProgressView on tvOS
//      * handleButtonPress
//          - supports focus system "like" navigation on iOS
//      * convertToMenu
//          - convert a UIAlertController to a UIMenu so it can be used as a context menu
//
//  TVAlertController can be presented three ways
//      * fullscreen        - set modalPresentationStyle = .fullscreen, .overFullscreen
//      * popover (iOS)     - set modalPresentationStyle = .popover
//      * child             - set modalPresentationStyle = .none
//
//  UIViewController helpers
//      * showAlert         - simple alert with buttons
//      * topViewController - get topmost preseented ViewController, or self if none
//
//  UIAlertAction helpers
//      * init with symbol  - create a UIAlertAction with a symbol
//      * init with image   - create a UIAlertAction with a image
//
//  Created by Todd Laney on 22/01/2022.
//
import UIKit

// these are the defaults assuming Dark mode, etc.
private let _fullscreenColor = UIColor.black.withAlphaComponent(0.5)
private let _backgroundColor = UIColor(red:0.1, green:0.1, blue:0.1, alpha:1)
private let _defaultButtonColor = UIColor(red:0.44, green:0.44, blue:0.46, alpha:0.4)   // close match to UISegmentedControll button background
//private let _defaultButtonColor = UIColor(red:0.34, green:0.34, blue:0.37, alpha:0.5)   // close match to UISegmentedControll button background
//private let _defaultButtonColor = UIColor(red:0.22, green:0.22, blue:0.25, alpha:0.5)   // close match to UISegmentedControll button background
private let _destructiveButtonColor = UIColor.systemRed.withAlphaComponent(0.5)
private let _cancelButtonColor = UIColor.systemRed.withAlphaComponent(0.5)
private let _grabHandleColor = _defaultButtonColor
private let _grabHandleSize = 4.0
private let _borderWidth = 4.0
private let _fontTitleF = 1.25
private let _animateDuration = 0.150

// os specific defaults
#if os(tvOS)
    private let _blurFullscreen = false
    private let _font = UIFont.systemFont(ofSize: 24.0)
    private let _inset = UIEdgeInsets(top:16, left:16, bottom:16, right:16)
    private let _minWidthF:CGFloat = 0.25
    private let _maxWidthF:CGFloat = 0.25
    private let _maxHeightF:CGFloat = 0.85
#else
    private let _blurFullscreen = true
    #if targetEnvironment(macCatalyst)
        private let _font = UIFont.systemFont(ofSize: 24.0)
    #else
        private let _font = UIFont.preferredFont(forTextStyle: .body)
    #endif
    private let _inset = UIEdgeInsets(top:16, left:16, bottom:16, right:16)
    private let _minWidthF:CGFloat = 0.222
    private let _maxWidthF:CGFloat = 0.333
    private let _maxCompactWidthF:CGFloat = 0.80
    private let _maxHeightF:CGFloat = 0.85
#endif

// MARK: TVAlertController - mock (aka take over) UIAlertViewController

// take over (aka mock) the swift UIAlertController initializer and return our class always....
func UIAlertController(title: String?, message: String?, preferredStyle style: UIAlertController.Style) -> UIAlertController {
    return unsafeBitCast(TVAlertController(title:title, message: message, preferredStyle: style), to:UIAlertController.self)
}

extension UIAlertController {
    // take over objc alertControllerWithTitle:message:preferredStyle: too
    @objc class func alertController(title:String?, message:String?, preferredStyle style: UIAlertController.Style) -> UIAlertController {
        return UIAlertController(title:title, message:message, preferredStyle:style)
    }
}

extension TVAlertController {
    @objc override func isKind(of aClass: AnyClass) -> Bool {
        // pretend we are a UIAlertController
        if aClass == UIAlertController.self || aClass == TVAlertController.self {
            return true
        }
        return super.isKind(of:aClass)
    }
}

// MARK: TVAlertController

final class TVAlertController: UIViewController {

    @objc private(set) var preferredStyle = UIAlertController.Style.alert
    @objc private(set) var actions = [UIAlertAction]()
    @objc private(set) var textFields:[UITextField]?
    @objc private(set) var cancelAction: UIAlertAction?
    @objc              var preferredAction: UIAlertAction?
    
    var moveable = true
    var sizeable = true

    var dismissHandler: (() -> Void)?

    private let stack0 = UIStackView(axis:.vertical)
    private let stack1 = UIStackView(axis:.vertical)
    private let scroll = UIScrollView()

    // MARK: init
    
    @objc convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style) {
        self.init(nibName:nil, bundle: nil)
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.modalPresentationStyle = .overFullScreen
        self.spacing = floor(_font.lineHeight / 4.0)
    }
    
    @objc var spacing: CGFloat {
        get {
            return stack0.spacing
        }
        set {
            stack0.spacing = newValue
            stack1.spacing = newValue
        }
    }
    
    @objc var font = _font {
        didSet {
            spacing = floor(font.lineHeight / 4.0);
        }
    }
    
    @objc var inset = _inset
    
    // MARK: UIAlertController
    
    private let tagTitle = 0x42
    private let tagMessage = 0x43
    private let tagGrab = 0x44
    private let tagProgress = 0x137
    private let tagProgressText = 0x138
    private let tagAction = 0x8675309

    private func setText(_ stack:UIStackView, _ tag:Int, _ text:String?) {
        if let label = stack.viewWithTag(tag) as? UILabel {
            label.text = text
        }
        else if let text = text {
            let label = makeText(text, align:.center, isTitle:(tag == tagTitle), tag:tag)
            //let idx = (stack.viewWithTag(tagTitle) != nil) ? 1 : 0
            let idx = (tag == tagTitle) ? 0 : stack.arrangedSubviews.count
            stack.insertArrangedSubview(label, at:idx)
            if stack === stack0 {
                label.layoutMargins = UIEdgeInsets(top:0, left:inset.left, bottom:0, right: inset.right)
            }
        }
    }
    private func getText(_ stack:UIStackView, _ tag:Int) -> String? {
        let label = stack.viewWithTag(tag) as? UILabel
        return label?.text
    }

    @objc override var title: String? {
        set {
            setText(stack0, tagTitle, newValue)
        }
        get {
            return getText(stack0, tagTitle)
        }
    }

    @objc var message: String? {
        set {
            setText(stack0, tagMessage, newValue)
        }
        get {
            return getText(stack0, tagMessage)
        }
    }

    @objc func addView(_ view:UIView) {
        stack1.addArrangedSubview(view)
    }
    
    @objc func addControl(_ control:UIControl, action: UIAlertAction) {
        control.tag = idx2tag(actions.count)
        control.addTarget(self, action: #selector(buttonPress(_:)), for: .primaryActionTriggered)
        actions.append(action)
        addView(control)
    }
    @objc func addControl(_ control:UIControl, handler: @escaping () -> Void) {
        let action = UIAlertAction() { _ in
            handler()
        }
        addControl(control, action:action)
    }
    
    @objc func addAction(_ action: UIAlertAction) {
        if action.style == .cancel {
            cancelAction = action
            if preferredStyle == .actionSheet {
                return
            }
            if actions.count > 2 {
                addSeparator(height:spacing, color:.clear)
            }
        }
        addControl(makeButton(action), action:action)
    }
    
    @objc func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        let textField = UITextField()
        textField.font = font
        textField.borderStyle = .roundedRect
        let h = font.lineHeight * 1.5
        let w = maxWidth
        textField.addConstraint(NSLayoutConstraint(item:textField, attribute:.height, relatedBy:.equal, toItem:nil, attribute:.notAnAttribute, multiplier:1.0, constant:h))
        textField.addConstraint(NSLayoutConstraint(item:textField, attribute:.width, relatedBy:.greaterThanOrEqual, toItem:nil, attribute:.notAnAttribute, multiplier:1.0, constant:w))
        textFields = textFields ?? []
        textFields?.append(textField)
        configurationHandler?(textField)
        addView(textField)
    }
    
    // MARK : remove
    
    @objc func removeAll() {
        actions.removeAll()
        for view in stack1.arrangedSubviews {
            view.removeFromSuperview()
        }
    }

    // MARK: blur

    private func addBlur(_ view:UIView, style:UIBlurEffect.Style) {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style:style))
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.frame = view.bounds
        view.addSubview(blur)
        view.sendSubviewToBack(blur)
    }
    
    // MARK: grab

    private func addGrab(_ view:UIView) {
        inset.left += CGFloat(_grabHandleSize * 2.0)
        let grab = UIView()
        grab.tag = tagGrab
        grab.backgroundColor = _grabHandleColor
        grab.layer.cornerRadius = CGFloat(_grabHandleSize * 0.5)
        view.addSubview(grab)
    }
    
    private func moveGrab(_ view:UIView) {
        if let grab = view.viewWithTag(tagGrab) {
            let height = view.bounds.height
            let h = min(height * 0.5, 64.0)
            let w = CGFloat(_grabHandleSize)
            grab.frame = CGRect(x:(inset.left - w)/2, y:(height - h)/2, width:w, height:h)
        }
    }
    
    // MARK: load
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup a tap to dissmiss
        #if os(tvOS)
            let tap = UITapGestureRecognizer(target:self, action: #selector(tapBackgroundToDismiss(_:)))
            tap.allowedPressTypes = [NSNumber(value:UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(tap)
        #else
            view.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(tapBackgroundToDismiss(_:))))
        #endif
        
        // setup move and size gestures
        #if os(iOS)
            if modalPresentationStyle == .none {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                pan.delegate = self
                view.addGestureRecognizer(pan)

                let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
                pinch.delegate = self
                pinch.delaysTouchesBegan = true
                view.addGestureRecognizer(pinch)
            }
        #endif
        
        // view
        //   fullscreen-blur (dark, ios)
        //   back
        //     blur (thin material, ios)
        //     grab-handle (ios, optional)
        //     stack0
        //       title-label
        //       message-label
        //       scroll
        //         stack1
        //           button for action #1
        //           button for action #2
        //                   ...
        //           button for action #N
        scroll.addSubview(stack1)
        stack0.addArrangedSubview(scroll)

        let back = UIView()
        back.addSubview(stack0)
        view.addSubview(back)

        back.layer.cornerRadius = min(inset.top,inset.left)
        back.backgroundColor = isFullscreen ? _backgroundColor : nil
        view.backgroundColor = (isFullscreen && !_blurFullscreen) ? _fullscreenColor : nil
        
        #if os(iOS)
            if modalPresentationStyle != .popover && back.backgroundColor == nil {
                addBlur(back, style: .systemUltraThinMaterialDark)
                back.clipsToBounds = true;
            }
            if isFullscreen && _blurFullscreen {
                addBlur(view, style:.dark)
            }
            if modalPresentationStyle == .none && moveable {
                addGrab(back)
            }
        #else
            if back.backgroundColor == nil {
                back.backgroundColor = .init(white:0.222, alpha:0.6)
            }
        #endif
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        set {
            var style = newValue
            if style == .fullScreen {
                style = .overFullScreen
            }
            #if os(tvOS)
                if style == .overFullScreen && _blurFullscreen {
                    style = .blurOverFullScreen
                }
            #endif
            
            super.modalPresentationStyle = style
            super.modalTransitionStyle = .crossDissolve
            
            #if os(iOS)
                if style == .popover {
                    popoverPresentationController?.delegate = self
                }
            #endif
        }
        get {
            return super.modalPresentationStyle
        }
    }
    
    // MARK: layout and size
    
    // are we fullscreen (aka not a popover)
    private var isFullscreen: Bool {
        #if os(tvOS)
            return modalPresentationStyle != .none
        #else
            return modalPresentationStyle != .none && modalPresentationStyle != .popover
        #endif
    }

    private var maxWidth: CGFloat {
        let width = self.windowSize.width

        #if targetEnvironment(macCatalyst)
            if self.windowSize.width < self.windowSize.height {
                return width * _maxCompactWidthF
            }
        #endif

        #if os(iOS)
            if UITraitCollection.current.horizontalSizeClass == .compact {
                return width * _maxCompactWidthF
            }
            if UITraitCollection.current.userInterfaceIdiom == .pad && width < UIScreen.main.bounds.width {
                return width * _maxCompactWidthF
            }
        #endif
        
        return width * _maxWidthF
    }

    private var minWidth: CGFloat {
        let width = self.windowSize.width
        return isFullscreen ? width * _minWidthF : 0.0
    }

    private var maxHeight: CGFloat {
        let height = self.windowSize.height
        return height * _maxHeightF
    }

    override var preferredContentSize: CGSize {
        get {
            var size = super.preferredContentSize
            if size == .zero {
                let size0 = stack0.systemLayoutSizeFitting(.zero)
                let size1 = stack1.systemLayoutSizeFitting(.zero)

                size.width = max(size0.width, size1.width)
                size.width = max(size.width, minWidth)
                size.height = size0.height + size1.height
                size.height = min(size.height, maxHeight)
            }
            if size != .zero {
                size.width  += (inset.left + inset.right)
                size.height += (inset.top + inset.bottom)
            }
            return size
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard let content = view.subviews.last else {return}

        let rect = CGRect(origin: .zero, size: self.preferredContentSize)
        content.bounds = rect
        stack0.frame = rect.inset(by:UIEdgeInsets(top:inset.top, left:0, bottom: inset.bottom, right:0))
        moveGrab(content)
        
        let size1 = stack1.systemLayoutSizeFitting(.zero)
        stack1.frame = CGRect(x:inset.left, y:0, width:rect.inset(by:inset).width, height:size1.height)
        scroll.contentSize = CGSize(width:rect.width, height:size1.height)

        let safe = view.bounds.inset(by: view.safeAreaInsets)
        content.center = CGPoint(x: safe.midX, y: safe.midY)
        
        if _borderWidth != 0.0 && isFullscreen {
            content.layer.borderWidth = CGFloat(_borderWidth)
            content.layer.borderColor = view.tintColor.cgColor
        }
    }
    
    // MARK: buttons
    
    private func tag2idx(_ tag:Int) -> Int? {
        let idx = tag - tagAction
        return actions.indices.contains(idx) ? idx : nil
    }
    private func idx2tag(_ idx:Int) -> Int {
        return idx + tagAction
    }

    internal func control(for action:UIAlertAction?) -> UIControl? {
        if let action = action, let idx = actions.firstIndex(of:action) {
            if let ctl = stack1.viewWithTag(idx2tag(idx)) as? UIControl {
                return ctl
            }
        }
        return nil
    }

    private func action(for control:UIView?) -> UIAlertAction? {
        if let control = control, let idx = tag2idx(control.tag) {
            return actions[idx]
        }
        return nil
    }

    @objc func buttonPress(_ sender:UIControl?) {
        guard let action = action(for: sender) else {return}
        if self.presentingViewController != nil {
            dismiss(with:action, completion: nil)
        }
        else {
            action.callActionHandler()
        }
    }

    private func makeButton(title:String? = nil, image:UIImage? = nil, style:UIAlertAction.Style = .default) -> UIButton {
        let btn = TVButton()
        btn.titleLabel?.font = self.font
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)

        let spacing = self.spacing
        btn.contentEdgeInsets = UIEdgeInsets(top:spacing, left:spacing*2, bottom:spacing, right:spacing*2)

        if let image = image {
            btn.tintColor = .white
            btn.setImage(image, for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top:spacing, left:spacing*2, bottom:spacing, right:spacing*3)
            btn.contentHorizontalAlignment = .left
            //btn.contentHorizontalAlignment = .center
            //btn.titleEdgeInsets = UIEdgeInsets(top:0, left:spacing, bottom:0, right:-spacing)
            if title == nil || title?.isEmpty == true {
                btn.contentEdgeInsets = UIEdgeInsets(top:spacing, left:spacing, bottom:spacing, right:spacing)
            }
        }
        else if title == nil || title?.isEmpty == true {
            btn.alpha = 0
        }
        
        btn.setGrowDelta(min(inset.left,inset.right) * 0.25, for: .focused)

        let h = font.lineHeight * 1.5
        btn.addConstraint(NSLayoutConstraint(item:btn, attribute:.height, relatedBy:.equal, toItem:nil, attribute:.notAnAttribute, multiplier:1.0, constant:h))
        btn.layer.cornerRadius = h/4

        if style == .destructive {
            btn.backgroundColor = _destructiveButtonColor
            btn.setBackgroundColor(_destructiveButtonColor.withAlphaComponent(1), for:.selected)
        }
        else if style == .cancel {
            btn.backgroundColor = _cancelButtonColor
            btn.setBackgroundColor(_cancelButtonColor.withAlphaComponent(1), for:.selected)
        }
        else {
            btn.backgroundColor = _defaultButtonColor
        }
        
        return btn
    }
    private func makeButton(_ action:UIAlertAction) -> UIButton {
        return makeButton(title:action.title, image:action.getImage(), style:action.style)
    }
    
    private func makeSeparator(height:CGFloat, color:UIColor?) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height))
        return view
    }
    
    private func makeText(_ text:String, align:NSTextAlignment = .left, isTitle:Bool = false, tag:Int = 0) -> UIView {
        let label = TVLabel()
        label.tag = tag
        label.font = isTitle ? .boldSystemFont(ofSize: font.pointSize * CGFloat(_fontTitleF)) : font
        label.numberOfLines = Int(self.windowSize.height * 0.5 / font.pointSize)
        label.textAlignment = align
        label.preferredMaxLayoutWidth = maxWidth
        label.text = text
        return label
    }
    
    // MARK: dismiss
    
    @objc func afterDismiss() {
        cancelAction?.callActionHandler()
        dismissHandler?()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.perform(#selector(afterDismiss), with:nil, afterDelay:0)
    }
    @objc func tapBackgroundToDismiss(_ sender:UITapGestureRecognizer) {
        #if os(iOS)
            let pt = sender.location(in: self.view)
            if view.subviews.last?.frame.contains(pt) == true {
                return;
            }
        #endif
        // only automaticly dismiss if there is a cancel button
        if cancelAction != nil && presentingViewController != nil {
            presentingViewController?.dismiss(animated:true, completion:nil)
        }
    }

    // MARK: focus
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        
        // if we have a preferredAction make that the first to get focus, but we gotta find it.
        if let control = control(for: preferredAction) {
            return [control]
        }
        
        return super.preferredFocusEnvironments
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in:context, with:coordinator)
        guard let content = view.subviews.last, modalPresentationStyle == .none else {return}
        
        if context.nextFocusedView?.isDescendant(of: self.view) == true {
            content.layer.borderWidth = CGFloat(_borderWidth)
            content.layer.borderColor = view.tintColor.cgColor
        }
        else {
            content.layer.borderWidth = 0.0
        }
    }
    
    #if os(iOS)
    // if we dont have a FocusSystem then select the preferredAction
    // TODO: detect focus sytem on iPad iOS 15+ ???
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let button = preferredFocusEnvironments.first as? UIControl {
            button.isSelected = true
            // scroll preferredAction into view, centered
            var rect = button.convert(button.bounds, to:scroll)
            rect = rect.insetBy(dx: 0, dy: -(scroll.bounds.height - rect.height) / 2)
            scroll.scrollRectToVisible(rect, animated: true)
        }
    }
    #endif
    
    // MARK: zoom in and zoom out
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // get the content view, dont animate if we are in a popover
        if let content = view.subviews.last, isFullscreen {
            let size = preferredContentSize
            let wind = self.windowSize
            let scale = min(1.0, min(wind.width * 0.95 / size.width, wind.height * 0.95 / size.height))
            
            content.transform = CGAffineTransform(scaleX:0.001, y:0.001)
            UIView.animate(withDuration: _animateDuration) {
                content.transform = CGAffineTransform(scaleX:scale, y:scale)
            }
        }
    }
    
    #if os(iOS)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let content = view.subviews.last, isFullscreen {
            UIView.animate(withDuration: _animateDuration) {
                content.transform = CGAffineTransform(scaleX:0.001, y:0.001)
            }
        }
    }
    #endif
}

// MARK: pan and pinch, drag and zoom

#if os(iOS)
extension TVAlertController:  UIGestureRecognizerDelegate {
    @objc func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer, shouldReceive touch:UITouch) -> Bool {
        if gestureRecognizer.view == view, let slider = touch.view as? UISlider {
            let rect = slider.thumbRect(forBounds:slider.bounds, trackRect: slider.trackRect(forBounds:slider.bounds), value:slider.value)
            if rect.insetBy(dx:-8, dy:-8).contains(touch.location(in:slider)) {
                return false
            }
        }
        return true
    }
    @objc func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer:UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view == otherGestureRecognizer.view
    }
    @objc func handlePan(_ pan:UIPanGestureRecognizer) {
        guard moveable else {return}
        let translation = pan.translation(in: view.superview)
        pan.setTranslation(.zero, in: view.superview)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
    }
    @objc func handlePinch(_ pinch:UIPinchGestureRecognizer) {
        guard sizeable else {return}
        view.transform = view.transform.scaledBy(x:pinch.scale, y:pinch.scale)
        pinch.scale = 1.0
    }
}
#endif

// MARK: UIPopoverPresentationControllerDelegate

#if os(iOS)
extension TVAlertController: UIPopoverPresentationControllerDelegate {
    
    // Returning UIModalPresentationNone will indicate that an adaptation should not happen, so we can use popover on iPhone
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // if the device rotates when popover is up, just center
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rectPtr: UnsafeMutablePointer<CGRect>, in viewPtr: AutoreleasingUnsafeMutablePointer<UIView>) {
        guard !self.isBeingPresented, let view = self.presentingViewController?.view else { return }
        popoverPresentationController.permittedArrowDirections = []
        viewPtr.pointee = view
        rectPtr.pointee = CGRect(x:view.bounds.width/2, y:view.bounds.height/2, width:0, height:0)
    }
}
#endif

// MARK: addText

extension TVAlertController {
    @objc func addText(_ text:String) {
        if text == " " {
            return addSeparator(height: font.lineHeight / 2)
        }
        addView(makeText(text))
    }
    
    @objc func addTitle(_ text:String) {
        addView(makeText(text, align:.center, isTitle:true))
    }

    @objc func addAttributedText(_ text:NSAttributedString) {
        let label = UILabel()
        label.attributedText = text
        label.numberOfLines = 0
        addView(label)
    }
    
    @objc(addText:forKey:)
    func addText(_ text:String, for key:String) {
        addView(makeText(text, tag:key.hashValue))
    }

    @objc(setText:forKey:)
    func setText(_ text:String, for key:String) {
        setText(stack1, key.hashValue, text)
    }
    
    @objc func addSeparator(height:CGFloat, color:UIColor? = nil) {
        addView(makeSeparator(height:height, color:color))
    }
}

// MARK: addButton(s) and addToolbar

// item is a string of the form :symbol:title, or just title, or just :symbol:
private extension String {
    var title:String {
        return self.components(separatedBy: ":").last!
    }
    var symbol:String? {
        return self.contains(":") ? self.components(separatedBy: ":")[1] : nil
    }
}

extension TVAlertController {

    // addButton - item is a string of the form :symbol:title
    func addButton(_ item:String, style:UIAlertAction.Style = .default, color:UIColor? = nil, handler: @escaping ()->Void) {
        var image:UIImage? = nil
        // make sure we use a custom font (self.font) not the default one (_font)
        if let symbol = item.symbol {
            image = UIImage(systemName:symbol, withConfiguration:UIImage.SymbolConfiguration(font:self.font))
        }
        let action = UIAlertAction(title:item.title, image:image, style:style) { _ in
            handler()
        }
        addAction(action)
        if let color = color, let btn = control(for: action) as? TVButton {
            btn.setBackgroundColor(color, for:.normal)
            if color != .clear && color.withAlphaComponent(1) != color {
                btn.setBackgroundColor(color.withAlphaComponent(1), for:.selected)
                btn.setBackgroundColor(color.withAlphaComponent(1), for:.focused)
            }
        }
    }
    @objc func addButton(_ item:String, handler: @escaping ()->Void) {
        addButton(item, style:.default, handler:handler)
    }
    @objc func addButton(_ item:String, color:UIColor, handler: @escaping ()->Void) {
        addButton(item, style:.default, color:color, handler:handler)
    }
    @objc func addButton(_ item:String, style:UIAlertAction.Style, handler: @escaping ()->Void) {
        addButton(item, style:style, color:nil, handler:handler)
    }

    // addButtons
    func addButtons(_ items:[String], style:UIAlertAction.Style = .default, color:UIColor? = nil, handler: @escaping (_ button:UInt)->Void) {
        let stack = UIStackView(axis:.horizontal, distribution:.fillEqually, spacing:self.spacing)
        for i in items.indices {
            addButton(items[i], style:style, color:color) {
                handler(UInt(i))
            }
            if let btn = stack1.arrangedSubviews.last as? TVButton {
                btn.removeFromSuperview()
                stack.addArrangedSubview(btn)
            }
        }
        stack1.addArrangedSubview(stack)
    }
    @objc func addButtons(_ items:[String], color:UIColor?, handler: @escaping (_ button:UInt)->Void) {
        addButtons(items, style:.default, color:color, handler: handler)
    }
    @objc func addButtons(_ items:[String], style:UIAlertAction.Style, handler: @escaping (_ button:UInt)->Void) {
        addButtons(items, style:style, color:nil, handler: handler)
    }
    @objc func addButtons(_ items:[String], handler: @escaping (_ button:UInt)->Void) {
        addButtons(items, style:.default, color:nil, handler: handler)
    }
    
    @objc func addToolbar(_ items:[String], handler: @escaping (_ button:UInt)->Void) {
        #if os(tvOS)
            // a UISegmentedControll is weird on tvOS, so we just use buttons.
            addButtons(items, handler:handler)
            if let stack = stack1.arrangedSubviews.last as? UIStackView {
                stack.distribution = .fillProportionally
            }
        #else
            let seg = TVToolbar(items:items, font:self.font)
            addControl(seg) {
                if seg.selectedSegmentIndex != UISegmentedControl.noSegment {
                    handler(UInt(seg.selectedSegmentIndex))
                }
            }
        #endif
    }

    // call this handler no mater what when we get dismissed
    @objc func onDismiss(_ handler: @escaping ()->Void) {
        dismissHandler = handler
    }
}

// MARK: addValue

extension TVAlertController {
    @objc func addValue(_ value:Float, title:String, min:Float, max:Float, step:Float, handler: @escaping (Float) -> Void) {
        
        let slider = TVSlider(value:value, title:title, min:min, max:max, step:step)
        slider.font = font
        slider.addTarget(self, action: #selector(valueChange(_:)), for: .valueChanged)

        addControl(slider) {
            handler(slider.value)
        }
    }
    @objc func valueChange(_ sender:UIControl?) {
        action(for:sender)?.callActionHandler()
    }
}

// MARK: UIAlertAction

extension UIAlertAction {
    
    @objc class func action(title:String, symbol:String?, style:UIAlertAction.Style, handler: @escaping ((UIAlertAction) -> Void)) -> UIAlertAction {
        return UIAlertAction(title:title, symbol:symbol, style:style, handler:handler)
    }
    
    convenience init(handler: @escaping ((UIAlertAction) -> Void)) {
        self.init(title: "", style: .default, handler: handler)
    }
    
    convenience init(title: String, symbol:String?, style: UIAlertAction.Style, handler: @escaping ((UIAlertAction) -> Void)) {
        if let symbol = symbol, !symbol.isEmpty, let image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(font:_font)) {
            self.init(title:title, image:image, style:style, handler:handler)
        }
        else {
            self.init(title: title, style: style, handler: handler)
        }
    }

    convenience init(title: String, image:UIImage?, style: UIAlertAction.Style, handler: @escaping ((UIAlertAction) -> Void)) {
        self.init(title: title, style: style, handler: handler)
        if #available(iOS 13.0, tvOS 13.0, *) {
            if self.responds(to: NSSelectorFromString("image")), let image = image {
                self.setValue(image, forKey: "image")
            }
        }
    }

    fileprivate func getImage() -> UIImage? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            if self.responds(to: NSSelectorFromString("image")) {
                return self.value(forKey: "image") as? UIImage
            }
        }
        return nil
    }

    fileprivate func callActionHandler() {
        if self.responds(to: NSSelectorFromString("handler")) {
            if let handler = self.value(forKey:"handler") as? NSObject {
                unsafeBitCast(handler, to:(@convention(block) (UIAlertAction)->Void).self)(self)
            }
        }
    }
}

// MARK: MENU

#if os(iOS)
extension TVAlertController {
    
    // convert a UIAlertController to a UIMenu so it can be used as a context menu
    @available(iOS 13.0, *)
    @objc func convertToMenu() -> UIMenu {

        // convert UIAlertActions to UIActions via compactMap
        let menu_actions = self.actions.compactMap { (alert_action) -> UIAction? in
            
            // filter out .cancel actions for action sheets, keep them for alerts
            if self.preferredStyle == .actionSheet && alert_action.style == .cancel {
                return nil
            }

            let title = alert_action.title ?? ""
            let attributes = (alert_action.style == .destructive) ? UIMenuElement.Attributes.destructive : []
            return UIAction(title: title, image:alert_action.getImage(), attributes: attributes) { _ in
                alert_action.callActionHandler()
            }
        }
        
        return UIMenu(title: (self.title ?? ""), children: menu_actions)
    }
}
// just declare as a selector
extension UIAlertController {
    @available(iOS 13.0, *)
    @objc func convertToMenu() -> UIMenu { fatalError() }
}
#endif

// MARK: Button

extension UIControl.State : Hashable {}

private class TVButton : UIButton {
    
    convenience init() {
        self.init(type:.custom)
    }

    override func didMoveToWindow() {
        
        // these are the defaults if not set
        _color[.normal]       = _color[.normal] ?? backgroundColor ?? .gray
        _color[.focused]      = _color[.focused] ?? _color[.selected] ?? superview?.tintColor
        _color[.selected]     = _color[.selected] ?? _color[.focused] ?? superview?.tintColor
        _color[.highlighted]  = _color[.highlighted] ?? _color[.selected] ?? superview?.tintColor
        
        if _color[.normal] == .clear {
            setTitleColor(superview?.tintColor, for: .normal)
            setTitleColor(.white, for: .focused)
            setTitleColor(.white, for: .selected)
            setTitleColor(.white, for: .highlighted)
        }

        _grow[.focused] = _grow[.focused] ?? _grow[.selected] ?? 16.0
        _grow[.selected] = _grow[.selected] ?? _grow[.focused] ?? 16.0
        _grow[.highlighted] = _grow[.highlighted] ?? 0.0
        
        if layer.cornerRadius == 0.0 {
            layer.cornerRadius = 12.0
        }
    }
    
    private var _color = [UIControl.State:UIColor]()
    func setBackgroundColor(_ color:UIColor, for state: UIControl.State) {
        _color[state]  = color
        if self.window != nil { update() }
    }
    func getBackgroundColor(for state: UIControl.State) -> UIColor? {
        return  _color[state] ?? _color[state.subtracting([.focused, .selected])] ?? _color[state.subtracting(.highlighted)] ?? _color[.normal] ?? self.backgroundColor
    }

    private var _grow = [UIControl.State:CGFloat]()
    func setGrowDelta(_ scale:CGFloat, for state: UIControl.State) {
        _grow[state] = scale
        if self.window != nil { update() }
    }
    func getGrowDelta(for state: UIControl.State) -> CGFloat {
        return _grow[state] ?? _grow[state.subtracting([.focused, .selected])] ?? _grow[state.subtracting(.highlighted)] ?? _grow[.normal] ?? 0.0
    }

    private func update() {
        self.backgroundColor = getBackgroundColor(for: self.state)
        self.imageView?.tintColor = self.titleColor(for: self.state)
        if self.bounds.width != 0 {
            let scale = min(1.04, 1.0 + getGrowDelta(for: state) / (self.bounds.width * 0.5))
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    override func imageRect(forContentRect rect: CGRect) -> CGRect {
        if let image = self.image(for:self.state) {
            let spacing = self.contentEdgeInsets.right - self.contentEdgeInsets.left
            if self.contentHorizontalAlignment == .left {
                return CGRect(x:rect.maxX + spacing - image.size.width, y:rect.minY + (rect.height - image.size.height)/2, width: image.size.width, height: image.size.height)
            }
            if self.contentHorizontalAlignment == .right {
                return CGRect(x:rect.minX, y:rect.minY + (rect.height - image.size.height)/2, width: image.size.width, height: image.size.height)
            }
        }
        return super.imageRect(forContentRect: rect)
    }
    override func titleRect(forContentRect rect: CGRect) -> CGRect {
        if let image = self.image(for:self.state) {
            let spacing = self.contentEdgeInsets.right - self.contentEdgeInsets.left
            if self.contentHorizontalAlignment == .left {
                return CGRect(x:rect.minX, y:rect.minY, width: rect.width + spacing - image.size.width, height: rect.height)
            }
            if self.contentHorizontalAlignment == .right {
                return CGRect(x:rect.minX + image.size.width + spacing, y:rect.minY, width: rect.width + spacing - image.size.width, height: rect.height)
            }
        }
        return super.titleRect(forContentRect: rect)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: _animateDuration) {
                self.update()
            }
        }
    }
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: _animateDuration) {
                self.update()
            }
        }
    }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.update()
        }, completion: nil)
    }
}

// MARK: Toolbar

private class TVToolbar : UISegmentedControl {
    var _selectedSegmentIndex = 0
    
    init(items: [Any]?, font:UIFont) {
        // map any strings of the form ":symbol:" to an UIImage, using font for scale
        let items = items?.map {(any:Any) -> Any in
            if let str = any as? String, let symbol = str.symbol, let image = UIImage(systemName:symbol, withConfiguration:UIImage.SymbolConfiguration(font:font)) {
                return image
            }
            return any
        }
        super.init(items: items)
        self.apportionsSegmentWidthsByContent = true
        self.isMomentary = true
        self.setTitleTextAttributes([.font:font, .foregroundColor:UIColor.white], for: .normal)
        
        let h = font.lineHeight * 1.5
        self.addConstraint(NSLayoutConstraint(item:self, attribute:.height, relatedBy:.equal, toItem:nil, attribute:.notAnAttribute, multiplier:1.0, constant: h))
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.selectedSegmentTintColor = self.tintColor;
    }
    #if os(iOS)
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: _animateDuration) {
                self.selectedSegmentIndex = self.isSelected ? self._selectedSegmentIndex : UISegmentedControl.noSegment
            }
        }
    }
    @objc func handleButtonPress(_ type: UIPress.PressType) {
        switch type {
        case .leftArrow:
            _selectedSegmentIndex = max(_selectedSegmentIndex - 1, 0)
            self.isSelected = (self.isSelected == true)
        case .rightArrow:
            _selectedSegmentIndex = min(_selectedSegmentIndex + 1, self.numberOfSegments-1)
            self.isSelected = (self.isSelected == true)
        default:
            break
        }
    }
    #endif
}

// MARK: Value Slider

// slider with a title (and maybe a switch)
private class TVSlider : UIControl {
    private let stack = UIStackView()
    private let label = UILabel()
    #if os(tvOS)
    private let slider = UIProgressView()
    private var pan:UIPanGestureRecognizer?
    private var pan_start_value = Float.zero
    #else
    private let slider = UISlider()
    private var toggle:UISwitch? = nil
    #endif
    
    private var minimumValue:Float = 0
    private var maximumValue:Float = 0
    private var stepValue:Float = 0
    private var formatString = ""

    private var _value:Float = 0
    var value:Float {
        set {
            var newValue =  min(maximumValue, max(minimumValue, newValue))
            if stepValue != 0.0 {
                newValue = round(newValue / stepValue) * stepValue
            }
            _value = newValue
            update()
        }
        get {
            return _value
        }
    }
    private func setValue(_ value:Float) {
        self.value = value
        self.sendActions(for: .valueChanged)
    }

    convenience init(value:Float, title:String, min:Float, max:Float, step:Float = 0.0) {
        self.init()
        self.minimumValue = min
        self.maximumValue = max
        self.stepValue = step
        self.value = value

        switch step {
        case 1.00...: formatString = title + ": %0.0f"
        case 0.10...: formatString = title + ": %0.1f"
        case 0.01...: formatString = title + ": %0.2f"
        default:      formatString = title + ": %0.3f"
        }
        
        stack.axis = .vertical
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(slider)
        self.addSubview(stack)
        self.isUserInteractionEnabled = true

        label.text = title
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true

        #if os(iOS)
            slider.minimumValue = min
            slider.maximumValue = max
            slider.addTarget(self, action: #selector(valueChanged(slider:)), for: .valueChanged)
        #endif
        
        #if os(iOS)
            // use a UISwitch if the value is binary
            if min == 0.0 && max == 1.0 && step == 1.0 {
                slider.removeFromSuperview()
                toggle = UISwitch()
                toggle!.addTarget(self, action: #selector(valueChanged(toggle:)), for: .valueChanged)
                stack.axis = .horizontal
                stack.addArrangedSubview(toggle!)
            }
        #endif

        setup()
        update()
    }
    
    #if os(iOS)
    @objc func valueChanged(slider:UISlider) {
        setValue(slider.value)
    }
    @objc func valueChanged(toggle:UISwitch) {
        setValue(toggle.isOn ? 1.0 : 0.0)
    }
    #endif
    
    private func update() {
        label.text = String(format:formatString, value)
        #if os(iOS)
            if !slider.isTracking {
                slider.value = value
            }
            toggle?.isOn = value != 0.0
        #else
            slider.progress = (value - minimumValue) / (maximumValue - minimumValue)
        #endif
    }
    private func setup() {
        let selected = self.isSelected || self.isFocused
        stack.spacing = font.lineHeight / 16
        label.font = font
        #if os(iOS)
            slider.minimumTrackTintColor = selected ? tintColor : tintColor.withAlphaComponent(0.5)
            slider.maximumTrackTintColor = selected ? tintColor.withAlphaComponent(0.2) : nil
            let thumbSize = CGSize(width:font.lineHeight/2, height:font.lineHeight/2)
            slider.setThumbImage(UIImage.dot(size:thumbSize, color:selected ? tintColor : .white), for:.normal)
            slider.constraints.forEach {slider.removeConstraint($0)}
            slider.addConstraint(NSLayoutConstraint(item:slider, attribute:.height, relatedBy:.equal, toItem:nil, attribute:.notAnAttribute, multiplier:1.0, constant:thumbSize.height * 2))
            if let toggle = toggle {
                let scale =  font.lineHeight / toggle.sizeThatFits(.zero).height
                toggle.transform = CGAffineTransform(scaleX: scale, y: scale);
                toggle.onTintColor = selected ? tintColor : tintColor.withAlphaComponent(0.5)
            }
        #else
            slider.progressTintColor = selected ? tintColor : .white
            slider.trackTintColor = selected ? tintColor.withAlphaComponent(0.2) : nil
        
            if selected && pan == nil {
                pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
                addGestureRecognizer(pan!)
            }
            if !selected && pan != nil {
                removeGestureRecognizer(pan!)
                pan = nil
            }
        #endif
    }
    override func didMoveToWindow() {
        setup()
    }
    
    var font:UIFont = _font {
        didSet {
            setup()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return stack.systemLayoutSizeFitting(.zero)
    }
    override func layoutSubviews() {
        stack.frame = self.bounds
    }

    // MARK: focus and select

    @objc func handleButtonPress(_ type: UIPress.PressType) {
        let step = (stepValue == 0.0) ? (maximumValue - minimumValue) / 100 : stepValue
        switch type {
        case .leftArrow:
            setValue(self.value - step)
        case .rightArrow:
            setValue(self.value + step)
        default:
            break
        }
    }

    #if os(iOS)
    override var tag: Int {
        didSet {
            // HACK copy our tags to our children so TVAlertController.action(for:) can work
            label.tag = tag
            slider.tag = tag
            toggle?.tag = tag
        }
    }
    override var isSelected: Bool {
        didSet {
            setup()
        }
    }
    #else
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self || context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.setup()
            }, completion: nil)
        }
    }
    override var canBecomeFocused: Bool {
        return true
    }
    // TODO: this only works with the Siri Remote, maybe do a hack for a game controller (iff we care)
    @objc func pan(_ pan:UIPanGestureRecognizer) {
        if (pan.state == .began) {
            pan_start_value = slider.progress // 0..1
        }
        else if pan.state == .changed {
            // map delta to [-1, +1]
            let dx = pan.translation(in:self).x / self.bounds.width * 2.0
            var value = Float.zero
            
            // value = g_start_value + delta.x;
            if (dx > 0) {
                value = pan_start_value + Float(dx) * (1.0 - pan_start_value)
            }
            else {
                value = pan_start_value + Float(dx) * pan_start_value
            }

            value = max(0.0, min(1.0, value));
            value = minimumValue + value * (maximumValue - minimumValue)
            setValue(value)
        }
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        if let type = presses.first?.type {
            handleButtonPress(type)
        }
    }
    #endif
}

// MARK: TVAlertController - dismiss

extension TVAlertController {
    @objc func dismissWithDefault() {
        dismiss(with: preferredAction)
    }
    @objc func dismissWithCancel() {
        dismiss(with: cancelAction)
    }
    @objc(dismissWithAction:completion:)
    func dismiss(with action:UIAlertAction?, completion: (() -> Void)? = nil) {
        // only dismiss if valid action
        guard let action = action else {return}
        cancelAction = nil  // make sure cancelAction does not get called twice
        presentingViewController?.dismiss(animated:true) {
            action.callActionHandler()
            completion?()
        }
    }
}

// just declare these as selectors
extension UIAlertController {
    @objc var cancelAction:UIAlertAction? { fatalError() }
    @objc func dismissWithDefault() { fatalError() }
    @objc func dismissWithCancel() { fatalError() }
    @objc(dismissWithAction:completion:)
    func dismiss(with action:UIAlertAction?, completion: (() -> Void)? = nil) { fatalError() }
}

#if os(iOS)

// MARK: handleButtonPress

extension TVAlertController {
    @objc func handleButtonPress(_ type: UIPress.PressType) {
        // let a nested controll handle left and right
        if type == .leftArrow || type == .rightArrow {
            if let btn = control(for:preferredAction), btn.responds(to:#selector(handleButtonPress(_:))) {
                (btn as AnyObject).handleButtonPress(type)
            }
        }
        switch type {
        case .upArrow:
            moveDefaultAction(0,-1)
        case .downArrow:
            moveDefaultAction(0,+1)
        case .leftArrow:
            moveDefaultAction(-1,0)
        case .rightArrow:
            moveDefaultAction(+1,0)
        case .select:   // (aka A or ENTER)
            control(for:preferredAction)?.sendActions(for: .primaryActionTriggered)
        case .menu:     // (aka B or ESC)
            dismissWithCancel()
        default:
            break
        }
    }

    // move the default action
    private func moveDefaultAction(_ dx:Int, _ dy:Int) {
        if let action = preferredAction, let btn = control(for:action) {
            let rect = btn.convert(btn.bounds, to:stack1)
            let pt = CGPoint(x:rect.minX + spacing + CGFloat(dx) * rect.width, y:rect.midY + CGFloat(dy) * rect.height)
  
            var next = self.action(for:stack1.hitTest(pt, with:nil))
            if (next == nil && dy == +1) { next = actions.first }
            if (next == nil && dy == -1) { next = actions.last }
            
            if let next = next  {
                preferredAction = next
                control(for: action)?.isSelected = false
                control(for: preferredAction)?.isSelected = true
            }
        }
        else {
            preferredAction = actions.first(where: {$0.style == .default && $0.isEnabled})
            control(for: preferredAction)?.isSelected = true
        }
        
        // scroll preferredAction into view
        if let control = control(for: preferredAction) {
            let rect = control.convert(control.bounds, to:scroll)
            scroll.scrollRectToVisible(rect, animated: true)
        }
    }
}

#endif

// MARK: TVAlertController - Progress

extension TVAlertController {
    
    // a simple hack to have a progress bar in a Alert
    // you must call setProgress at least once before presenting Alert
    @objc func setProgress(_ value:Double, text:String?) {

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.setProgress(value, text: text)
            }
            return
        }

        let value = max(0.0, min(1.0, value))
        if let progress = stack1.viewWithTag(tagProgress) as? UIProgressView {
            progress.progress = Float(value)
        }
        else {
            let progress = UIProgressView()
            progress.tag = tagProgress
            progress.progress = Float(value)
            stack1.addArrangedSubview(progress)
        }
        
        let text = (text == "") ? " " : text
        setText(stack1, tagProgressText, text)
    }
    
    @objc func setProgress(_ value:Double) {
        setProgress(value, text: nil)
    }
}

// just declare these so objc knows about selectors, real work will be dispatched to TVAlertController
extension UIAlertController {
    @objc func setProgress(_ value:Double, text:String?) { fatalError() }
    @objc func setProgress(_ value:Double) { fatalError() }
}

// MARK: UIViewController - windowSize

private extension UIViewController {
    // get the window that this UIViewController is part of and return window size, if not on screen yet return screen size
    var windowSize : CGSize {
        #if targetEnvironment(macCatalyst)
        if let window = self.presentingViewController?.view.window {
            return window.bounds.size
        }
        #endif
        if self.isViewLoaded, let window = self.view.window {
            return window.bounds.size
        }
        // use value(forKey:) instead of property to avoid deprecation warning
        if let window = UIApplication.shared.value(forKey:"keyWindow") as? UIWindow {
            return window.bounds.size
        }
        return UIScreen.main.bounds.size
    }
}

// MARK: UIViewController - helper function to show a quick alert

extension UIViewController {
    
    // helper function to show a simple alert with buttons
    @objc func showAlert(title:String?, message:String?, buttons:[String], handler:((UInt) -> Void)?) {
        let alert = UIAlertController(title:title, message:message, preferredStyle:.alert)
        var cancelAction:UIAlertAction?
        
        for i in buttons.indices {
            var style = UIAlertAction.Style.default
            
            if buttons[i].lowercased() == "cancel" {
                style = .cancel
            }
            
            alert.addAction(UIAlertAction(title:buttons[i], style:style, handler: { _ in
                handler?(UInt(i));
            }))

            if style == .cancel {
                cancelAction = alert.actions.last
            }
        }
        if cancelAction != nil && buttons.count == 2 {
            if cancelAction == alert.actions.first {
                alert.preferredAction = alert.actions.last
            }
            else {
                alert.preferredAction = alert.actions.first
            }
        }
        if cancelAction == nil && buttons.count == 1 {
            alert.preferredAction = alert.actions.first
        }
            
        self.topViewController.present(alert, animated:true, completion:nil)
    }
    
    // get the top most presented ViewController, or self, used to present a vc over everyone
    @objc var topViewController: UIViewController {
        var vc = self
        while let next = vc.presentedViewController {
            vc = next
        }
        return vc;
    }
}

// MARK: UIStackView - init

private extension UIStackView {
    convenience init(axis:NSLayoutConstraint.Axis = .horizontal, distribution:Distribution = .fill, alignment:Alignment = .fill, spacing:CGFloat = 0.0, views:UIView...) {
        self.init(arrangedSubviews:views)
        self.axis = axis
        self.distribution = distribution
        self.alignment = alignment
        self.spacing = spacing
    }
}

// MARK: UIImage - dot

private extension UIImage {
    static func dot(size:CGSize, color:UIColor) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin:.zero, size:size))
        }
    }
}

// MARK: TVLabel - a subclass of UILabel that insets the text by layoutMargins

class TVLabel: UILabel {
    
    override func drawText(in rect:CGRect) {
        let rect = rect.inset(by:layoutMargins)
        // verticaly align to top, normal UILabel default is to verticaly center
        // rect.size.height = textRect(forBounds:rect, limitedToNumberOfLines:numberOfLines).height
        super.drawText(in:rect)
    }
    override var preferredMaxLayoutWidth:CGFloat {
        get {return super.preferredMaxLayoutWidth + (layoutMargins.left + layoutMargins.right)}
        set {super.preferredMaxLayoutWidth = newValue - (layoutMargins.left + layoutMargins.right)}
    }
    override var intrinsicContentSize:CGSize  {
        var size = super.intrinsicContentSize
        if (size.width != 0 && size.height != 0) {
            size.width += layoutMargins.left + layoutMargins.right
            size.height += layoutMargins.top + layoutMargins.bottom
        }
        return size
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        if (size.width != 0 && size.height != 0) {
            size.width += layoutMargins.left + layoutMargins.right
            size.height += layoutMargins.top + layoutMargins.bottom
        }
        return size
    }
}




