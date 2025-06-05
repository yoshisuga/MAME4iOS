//
 //  EmulatorKeyboard.swift
 //
 //  Created by Yoshi Sugawara on 7/30/20.
 //

 // TODO: shift key should change the label of the keys to uppercase (need callback mechanism?)
 // pan gesture to outer edges of keyboard view for better dragging

 import Foundation
 import UIKit

 class KeyboardButton: UIButton {
     let key: KeyCoded

     // MARK: - Functions
     override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
         let newArea = CGRect(
             x: self.bounds.origin.x - 10.0,
             y: self.bounds.origin.y - 10.0,
             width: self.bounds.size.width + 30.0,
             height: self.bounds.size.height + 30.0
         )
         return newArea.contains(point)
     }
     
     private func updateColors() {
         backgroundColor = isHighlighted ? EmulatorKeyboardView.keyPressedBackgroundColor : isSelected ? EmulatorKeyboardView.keySelectedBackgroundColor : EmulatorKeyboardView.keyNormalBackgroundColor
         layer.borderColor = (isHighlighted ? EmulatorKeyboardView.keyPressedBorderColor : isSelected ? EmulatorKeyboardView.keySelectedBorderColor : EmulatorKeyboardView.keyNormalBorderColor).cgColor
         titleLabel?.textColor = isHighlighted ? EmulatorKeyboardView.keyPressedTextColor : isSelected ? EmulatorKeyboardView.keySelectedTextColor : EmulatorKeyboardView.keyNormalTextColor
         titleLabel?.tintColor = titleLabel?.textColor
     }

     override open var isHighlighted: Bool {
         didSet {
             updateColors()
         }
     }

     override open var isSelected: Bool {
         didSet {
             updateColors()
         }
     }

     required init(key: KeyCoded) {
         self.key = key
         super.init(frame: .zero)
         updateColors()
     }
     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
 }

 @objc protocol EmulatorKeyboardKeyPressedDelegate: AnyObject {
     func keyPressed(isKeyDown: Bool, key: KeyCoded)
 }

 @objc protocol EmulatorKeyboardModifierPressedDelegate: AnyObject {
     func modifierPressedWithKey(_ key: KeyCoded, enable: Bool)
     func isModifierEnabled(key: KeyCoded) -> Bool
 }

 protocol EmulatorKeyboardViewDelegate: AnyObject {
     func toggleAlternateKeys()
     func refreshModifierStates()
     func updateTransparency(toAlpha alpha: Float)
 }

 class EmulatorKeyboardView: UIView {

     static var keyboardBackgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
     static var keyboardCornerRadius = 6.0
     static var keyboardDragColor = UIColor.systemGray

     static var keyCornerRadius = 6.0
     static var keyBorderWidth = 1.0
     
     static var rowSpacing = 6.0
     static var keySpacing = 10.0

     static var keyNormalFont = UIFont.systemFont(ofSize: 16)
     static var keyPressedFont = UIFont.boldSystemFont(ofSize: 26)
   
     // Portrait mode sizes
     static var portraitKeyNormalFont = UIFont.systemFont(ofSize: 14)
     static var portraitKeyPressedFont = UIFont.boldSystemFont(ofSize: 22)
     static var portraitRowSpacing = 4.0
     static var portraitKeySpacing = 6.0

     static var keyNormalBackgroundColor = UIColor.systemGray4.withAlphaComponent(0.5)
     static var keyNormalBorderColor = keyNormalBackgroundColor
     static var keyNormalTextColor = UIColor.label

     static var keyPressedBackgroundColor = UIColor.systemGray2
     static var keyPressedBorderColor = keyPressedBackgroundColor
     static var keyPressedTextColor = UIColor.label

     static var keySelectedBackgroundColor = UIColor.systemGray2.withAlphaComponent(0.8)
     static var keySelectedBorderColor = keySelectedBackgroundColor
     static var keySelectedTextColor = UIColor.label
     
     var viewModel = EmulatorKeyboardViewModel(keys: [[KeyCoded]]()) {
         didSet {
             setupWithModel(viewModel)
         }
     }
     var modifierButtons = Set<KeyboardButton>()
   
     var isPortraitMode: Bool = false {
       didSet {
         if oldValue != isPortraitMode {
           updateLayoutForOrientation()
         }
       }
     }

     weak var delegate: EmulatorKeyboardViewDelegate?

     private lazy var keyRowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = CGFloat(EmulatorKeyboardView.rowSpacing)
        return stackView
     }()

     private lazy var alternateKeyRowsStackView: UIStackView = {
         let stackView = UIStackView()
         stackView.translatesAutoresizingMaskIntoConstraints = false
         stackView.axis = .vertical
         stackView.distribution = .equalCentering
         stackView.spacing = CGFloat(EmulatorKeyboardView.rowSpacing)
         stackView.isHidden = true
         return stackView
     }()

     let dragMeView: UIView = {
       let view = UIView(frame: .zero)
       view.backgroundColor = EmulatorKeyboardView.keyboardDragColor
       view.translatesAutoresizingMaskIntoConstraints = false
       view.widthAnchor.constraint(equalToConstant: 80).isActive = true
       view.heightAnchor.constraint(equalToConstant: 2).isActive = true
       let outerView = UIView(frame: .zero)
       outerView.backgroundColor = .clear
       outerView.translatesAutoresizingMaskIntoConstraints = false
       outerView.addSubview(view)
       view.centerXAnchor.constraint(equalTo: outerView.centerXAnchor).isActive = true
       view.centerYAnchor.constraint(equalTo: outerView.centerYAnchor).isActive = true
       outerView.heightAnchor.constraint(equalToConstant: 20).isActive = true
       outerView.widthAnchor.constraint(equalToConstant: 100).isActive = true
       return outerView
     }()

     private var pressedKeyViews = [UIControl: UIView]()

     convenience init() {
         self.init(frame: CGRect.zero)
     }

     override init(frame: CGRect) {
         super.init(frame: frame)
         commonInit()
     }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         commonInit()
     }

     private func commonInit() {
         backgroundColor = EmulatorKeyboardView.keyboardBackgroundColor
         layer.cornerRadius = CGFloat(EmulatorKeyboardView.keyboardCornerRadius)
         layoutMargins = UIEdgeInsets(top: 16, left: 4, bottom: 16, right: 4)
         insetsLayoutMarginsFromSafeArea = false
         addSubview(keyRowsStackView)
         keyRowsStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
         keyRowsStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 4.0).isActive = true
         keyRowsStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -4.0).isActive = true
         addSubview(alternateKeyRowsStackView)
         alternateKeyRowsStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
         alternateKeyRowsStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 4.0).isActive = true
         alternateKeyRowsStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -4.0).isActive = true
         addSubview(dragMeView)
         dragMeView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
         dragMeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
     }

   private func updateLayoutForOrientation() {
     // Update stack view spacing
     let spacing = isPortraitMode ? EmulatorKeyboardView.portraitRowSpacing : EmulatorKeyboardView.rowSpacing
     keyRowsStackView.spacing = CGFloat(spacing)
     alternateKeyRowsStackView.spacing = CGFloat(spacing)
     
     // Update key spacing in each row
     let keySpacing = isPortraitMode ? EmulatorKeyboardView.portraitKeySpacing : EmulatorKeyboardView.keySpacing
     for arrangedSubview in keyRowsStackView.arrangedSubviews {
       if let stackView = arrangedSubview as? UIStackView {
         stackView.spacing = CGFloat(keySpacing)
       }
     }
     for arrangedSubview in alternateKeyRowsStackView.arrangedSubviews {
       if let stackView = arrangedSubview as? UIStackView {
         stackView.spacing = CGFloat(keySpacing)
       }
     }
     
     // Update layout margins
     if isPortraitMode {
       layoutMargins = UIEdgeInsets(top: 12, left: 2, bottom: 12, right: 2)
     } else {
       layoutMargins = UIEdgeInsets(top: 16, left: 4, bottom: 16, right: 4)
     }
     
     // Update all key buttons
     updateAllKeyButtons()
     
     // Force layout update
     setNeedsLayout()
     layoutIfNeeded()
   }
   
   private func updateAllKeyButtons() {
     let font = isPortraitMode ? EmulatorKeyboardView.portraitKeyNormalFont : EmulatorKeyboardView.keyNormalFont
     
     // Update buttons in main stack view
     updateKeyButtonsInStackView(keyRowsStackView, font: font)
     // Update buttons in alternate stack view
     updateKeyButtonsInStackView(alternateKeyRowsStackView, font: font)
   }
   
   private func updateKeyButtonsInStackView(_ stackView: UIStackView, font: UIFont) {
     for arrangedSubview in stackView.arrangedSubviews {
       if let rowStackView = arrangedSubview as? UIStackView {
         for view in rowStackView.arrangedSubviews {
           if let button = view as? KeyboardButton {
             button.titleLabel?.font = font
             
             // Update button size constraints
             let widthMultiplier: CGFloat = isPortraitMode ? 0.8 : 1.0
             let heightConstant: CGFloat = isPortraitMode ? 36 : 45
             
             for constraint in button.constraints {
               if constraint.firstAttribute == .width {
                 constraint.constant = (40 * CGFloat(button.key.keySize.rawValue)) * widthMultiplier
               } else if constraint.firstAttribute == .height {
                 constraint.constant = heightConstant
               }
             }
           }
         }
       }
     }
   }

     @objc private func keyPressed(_ sender: KeyboardButton) {
         if sender.key.keyCode == 9000 { // hack for now
             return
         }
         if !sender.key.isModifier {
             // make a "stand-in" for our key, and scale up key
             let view = UIView()
             view.backgroundColor = EmulatorKeyboardView.keyPressedBackgroundColor
             view.layer.cornerRadius = CGFloat(EmulatorKeyboardView.keyCornerRadius)
             view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
             view.frame = sender.convert(sender.bounds, to: self)
             addSubview(view)
             
             var tx = CGFloat.zero
             let ty = sender.bounds.height * -1.20
             
             if let window = self.window {
                 let rect = sender.convert(sender.bounds, to:window)
                 
                 if rect.maxX > window.bounds.width * 0.9 {
                     tx = sender.bounds.width * -0.2
                 }
                 if rect.minX < window.bounds.width * 0.1 {
                     tx = sender.bounds.width * 0.2
                 }
             }

             sender.superview!.bringSubviewToFront(sender)
           sender.transform = CGAffineTransform(translationX:tx, y:ty).scaledBy(x:1.3, y:1.3)
             
             pressedKeyViews[sender] = view
         }
         viewModel.keyPressed(sender.key)
     }

     @objc private func keyCancelled(_ sender: KeyboardButton) {
         sender.transform = .identity
         if let view = pressedKeyViews[sender] {
             view.removeFromSuperview()
             pressedKeyViews.removeValue(forKey: sender)
         }
     }

     @objc private func keyReleased(_ sender: KeyboardButton) {
         sender.transform = .identity
         if sender.key.keyCode == 9000 {
             delegate?.toggleAlternateKeys()
             return
         }
         if let view = pressedKeyViews[sender] {
             view.removeFromSuperview()
             pressedKeyViews.removeValue(forKey: sender)
         }
         sender.isSelected = viewModel.modifierKeyToggleStateForKey(sender.key)
         viewModel.keyReleased(sender.key)
         self.delegate?.refreshModifierStates()
     }

     func setupWithModel(_ model: EmulatorKeyboardViewModel) {
         for row in model.keys {
             let keysInRow = createKeyRow(keys: row)
             keyRowsStackView.addArrangedSubview(keysInRow)
         }
         if let altKeys = model.alternateKeys {
             for row in altKeys {
                 let keysInRow = createKeyRow(keys: row)
                 alternateKeyRowsStackView.addArrangedSubview(keysInRow)
             }
         }
         if !model.isDraggable {
             dragMeView.isHidden = true
         }
     }

     func toggleKeysStackView() {
         if viewModel.alternateKeys != nil {
             keyRowsStackView.isHidden.toggle()
             alternateKeyRowsStackView.isHidden.toggle()
             refreshModifierStates()
         }
     }

     func refreshModifierStates() {
         modifierButtons.forEach{ button in
             button.isSelected = viewModel.modifierKeyToggleStateForKey(button.key)
         }
     }

     private func createKey(_ keyCoded: KeyCoded) -> UIButton {
         let key = KeyboardButton(key: keyCoded)
         if let imageName = keyCoded.keyImageName {
             key.tintColor = EmulatorKeyboardView.keyNormalTextColor
             key.setImage(UIImage(systemName: imageName), for: .normal)
             if let highlightedImageName = keyCoded.keyImageNameHighlighted {
                 key.setImage(UIImage(systemName: highlightedImageName), for: .highlighted)
                 key.setImage(UIImage(systemName: highlightedImageName), for: .selected)
             }
         } else {
             key.setTitle(keyCoded.keyLabel, for: .normal)
             key.titleLabel?.font = EmulatorKeyboardView.keyNormalFont
             key.setTitleColor(EmulatorKeyboardView.keyNormalTextColor, for: .normal)
             key.setTitleColor(EmulatorKeyboardView.keySelectedTextColor, for: .selected)
             key.setTitleColor(EmulatorKeyboardView.keyPressedTextColor, for: .highlighted)
         }

         key.translatesAutoresizingMaskIntoConstraints = false
         key.widthAnchor.constraint(equalToConstant: (40 * CGFloat(keyCoded.keySize.rawValue))).isActive = true
         key.heightAnchor.constraint(equalToConstant: 45).isActive = true
         key.backgroundColor = EmulatorKeyboardView.keyNormalBackgroundColor
         key.layer.borderWidth = CGFloat(EmulatorKeyboardView.keyBorderWidth)
         key.layer.borderColor = EmulatorKeyboardView.keyNormalBorderColor.cgColor
         key.layer.cornerRadius = CGFloat(EmulatorKeyboardView.keyCornerRadius)
         key.addTarget(self, action: #selector(keyPressed(_:)), for: .touchDown)
         key.addTarget(self, action: #selector(keyReleased(_:)), for: .touchUpInside)
         key.addTarget(self, action: #selector(keyReleased(_:)), for: .touchUpOutside)
         key.addTarget(self, action: #selector(keyCancelled(_:)), for: .touchCancel)
         if keyCoded.isModifier {
             modifierButtons.update(with: key)
         }
         return key
     }

     private func createKeyRow(keys: [KeyCoded]) -> UIStackView {
         let subviews: [UIView] = keys.enumerated().map { index, keyCoded -> UIView in
             if keyCoded is SpacerKey {
                 let spacer = UIView()
                 spacer.widthAnchor.constraint(equalToConstant: 25.0 * CGFloat(keyCoded.keySize.rawValue)).isActive = true
                 spacer.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
                 return spacer
             } else if let sliderKey = keyCoded as? SliderKey {
                 sliderKey.keyboardView = self
                 return sliderKey.createView()
             }
             return createKey(keyCoded)
         }
         let stack = UIStackView(arrangedSubviews: subviews)
         stack.axis = .horizontal
         stack.distribution = .fill
         stack.spacing = CGFloat(EmulatorKeyboardView.keySpacing)
         return stack
     }
 }

 @objc enum KeySize: Int {
     case standard = 1, wide, wider
 }

 // represents a key that has an underlying code that gets sent to the emulator
 @objc protocol KeyCoded: AnyObject {
     var keyLabel: String { get }
     var keyImageName: String? { get }
     var keyImageNameHighlighted: String? { get }
     var keyCode: Int { get }
     var keySize: KeySize { get }
     var isModifier: Bool { get }
 }

 protocol KeyRowsDataSource {
     func keyForPositionAt(_ position: KeyPosition) -> KeyCoded?
 }

 @objc class EmulatorKeyboardKey: NSObject, KeyCoded {
     let keyLabel: String
     var keyImageName: String?
     var keyImageNameHighlighted: String?
     let keyCode: Int
     let keySize: KeySize
     let isModifier: Bool

     override var description: String {
         return String(format: "\(keyLabel) (%02X)", keyCode)
     }

     init(label: String, code: Int, keySize: KeySize = .standard, isModifier: Bool = false, imageName: String? = nil, imageNameHighlighted: String? = nil)  {
         self.keyLabel = label
         self.keyCode = code
         self.keySize = keySize
         self.isModifier = isModifier
         self.keyImageName = imageName
         self.keyImageNameHighlighted = imageNameHighlighted
     }
 }

 class SpacerKey: KeyCoded {
     let keyLabel = ""
     let keyCode = 0
     let keySize: KeySize
     let isModifier = false
     let keyImageName: String? = nil
     let keyImageNameHighlighted: String? = nil
     init(keySize: KeySize = .standard) {
         self.keySize = keySize
     }
 }

 class SliderKey: KeyCoded {
     let keyLabel = ""
     let keyCode = 0
     let keySize: KeySize
     let isModifier = false
     let keyImageName: String? = nil
     let keyImageNameHighlighted: String? = nil
     weak var keyboardView: EmulatorKeyboardView?

     init(keySize: KeySize = .standard) {
         self.keySize = keySize
     }
     func createView() -> UIView {
         let slider = UISlider(frame: .zero)
         slider.minimumValue = 0.1
         slider.maximumValue = 1.0
         slider.addTarget(self, action: #selector(adjustKeyboardAlpha(_:)), for: .valueChanged)
         slider.value = 1.0
         let size = CGSize(width:EmulatorKeyboardView.keyNormalFont.pointSize, height:EmulatorKeyboardView.keyNormalFont.pointSize)
         slider.setThumbImage(UIImage.dot(size:size, color:EmulatorKeyboardView.keyNormalTextColor), for: .normal)
         return slider
     }
     @objc func adjustKeyboardAlpha(_ sender: UISlider) {
       keyboardView?.delegate?.updateTransparency(toAlpha: sender.value)
     }
 }

 struct KeyPosition {
     let row: Int
     let column: Int
 }

 @objc class EmulatorKeyboardViewModel: NSObject, KeyRowsDataSource {
     var keys = [[KeyCoded]]()
     var alternateKeys: [[KeyCoded]]?
     var modifiers: [Int16: KeyCoded]?

     var isDraggable = true

     @objc weak var delegate: EmulatorKeyboardKeyPressedDelegate?
     @objc weak var modifierDelegate: EmulatorKeyboardModifierPressedDelegate?

     init(keys: [[KeyCoded]], alternateKeys: [[KeyCoded]]? = nil) {
         self.keys = keys
         self.alternateKeys = alternateKeys
     }

     func createView() -> EmulatorKeyboardView {
         let view = EmulatorKeyboardView()
         view.viewModel = self
         return view
     }

     func keyForPositionAt(_ position: KeyPosition) -> KeyCoded? {
         guard position.row < keys.count else {
             return nil
         }
         let row = keys[position.row]
         guard position.column < row.count else {
             return nil
         }
         return row[position.column]
     }

     func modifierKeyToggleStateForKey(_ key: KeyCoded) -> Bool {
         return key.isModifier && (modifierDelegate?.isModifierEnabled(key: key) ?? false)
     }

     func keyPressed(_ key: KeyCoded) {
         if key.isModifier {
             let isPressed = modifierDelegate?.isModifierEnabled(key: key) ?? false
             modifierDelegate?.modifierPressedWithKey(key, enable: !isPressed)
             return
         }
         delegate?.keyPressed(isKeyDown: true, key: key)
     }

     func keyReleased(_ key: KeyCoded) {
         if key.isModifier {
             return
         }
         delegate?.keyPressed(isKeyDown: false, key: key)
     }

     // KeyCoded can support a shifted key label
     // view can update with shifted key labels?
     // cluster can support alternate keys and view can swap them out?
 }

 @objc class EmulatorKeyboardController: UIViewController {
    @objc let leftKeyboardModel: EmulatorKeyboardViewModel
    @objc let rightKeyboardModel: EmulatorKeyboardViewModel
     
    @objc lazy var leftKeyboardView: EmulatorKeyboardView = {
         let view = leftKeyboardModel.createView()
         view.delegate = self
         return view
     }()
     @objc lazy var rightKeyboardView: EmulatorKeyboardView = {
         let view = rightKeyboardModel.createView()
         view.delegate = self
         return view
     }()
     var keyboardConstraints = [NSLayoutConstraint]()
   
   // Size constraints for orientation changes
   private var leftKeyboardWidthConstraint: NSLayoutConstraint!
   private var leftKeyboardHeightConstraint: NSLayoutConstraint!
   private var rightKeyboardWidthConstraint: NSLayoutConstraint!
   private var rightKeyboardHeightConstraint: NSLayoutConstraint!
   
    @objc init(leftKeyboardModel: EmulatorKeyboardViewModel, rightKeyboardModel: EmulatorKeyboardViewModel) {
       self.leftKeyboardModel = leftKeyboardModel
       self.rightKeyboardModel = rightKeyboardModel
       super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }

     override func viewDidLoad() {
         super.viewDidLoad()
         setupView()

         let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
         leftKeyboardView.dragMeView.isUserInteractionEnabled = true
         leftKeyboardView.dragMeView.addGestureRecognizer(panGesture)
         let panGestureRightKeyboard = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
         rightKeyboardView.dragMeView.isUserInteractionEnabled = true
         rightKeyboardView.dragMeView.addGestureRecognizer(panGestureRightKeyboard)
       
         // Register for orientation change notifications
         NotificationCenter.default.addObserver(
             self,
             selector: #selector(orientationDidChange),
             name: UIDevice.orientationDidChangeNotification,
             object: nil
         )
         
         // Set initial orientation
         updateKeyboardsForOrientation()
     }

   deinit {
        NotificationCenter.default.removeObserver(self)
    }

   @objc private func orientationDidChange() {
       updateKeyboardsForOrientation()
   }
   
   private func updateKeyboardsForOrientation() {
     let isPortrait = UIDevice.current.orientation.isPortrait ||
     (!UIDevice.current.orientation.isLandscape && view.bounds.width < view.bounds.height)
     
     leftKeyboardView.isPortraitMode = isPortrait
     rightKeyboardView.isPortraitMode = isPortrait
     
     // Update keyboard sizes
     let (width, height) = getKeyboardDimensions(isPortrait: isPortrait)
     
     leftKeyboardWidthConstraint.constant = width
     leftKeyboardHeightConstraint.constant = height
     rightKeyboardWidthConstraint.constant = width
     rightKeyboardHeightConstraint.constant = height
     
     UIView.animate(withDuration: 0.3) {
       self.view.layoutIfNeeded()
     }
   }
   
   private func getKeyboardDimensions(isPortrait: Bool) -> (width: CGFloat, height: CGFloat) {
       if isPortrait {
           // Smaller dimensions for portrait
           return (width: 200, height: 240)
       } else {
           // Original dimensions for landscape
           return (width: 260, height: 310)
       }
   }

   func setupView() {
     NSLayoutConstraint.deactivate(keyboardConstraints)
     keyboardConstraints.removeAll()
     
     leftKeyboardView.translatesAutoresizingMaskIntoConstraints = false
     view.addSubview(leftKeyboardView)
     
     // Create size constraints
     let (width, height) = getKeyboardDimensions(isPortrait: UIDevice.current.orientation.isPortrait)
     leftKeyboardHeightConstraint = leftKeyboardView.heightAnchor.constraint(equalToConstant: height)
     leftKeyboardWidthConstraint = leftKeyboardView.widthAnchor.constraint(equalToConstant: width)
     
     leftKeyboardHeightConstraint.isActive = true
     leftKeyboardWidthConstraint.isActive = true
     
     keyboardConstraints.append(contentsOf: [
      leftKeyboardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      leftKeyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
     ])
     
     rightKeyboardView.translatesAutoresizingMaskIntoConstraints = false
     view.addSubview(rightKeyboardView)
     
     // Create size constraints for right keyboard
     rightKeyboardHeightConstraint = rightKeyboardView.heightAnchor.constraint(equalToConstant: height)
     rightKeyboardWidthConstraint = rightKeyboardView.widthAnchor.constraint(equalToConstant: width)
     
     rightKeyboardHeightConstraint.isActive = true
     rightKeyboardWidthConstraint.isActive = true
     
     keyboardConstraints.append(contentsOf: [
      rightKeyboardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      rightKeyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
     ])
     
     NSLayoutConstraint.activate(keyboardConstraints)
   }

     func setupViewFrames() {
         // initial placement on the bottom corners
         // since we don't know the frame of this view yet until layout time,
         // assume it's taking the full screen
         let screenFrame = UIScreen.main.bounds
         let keyboardHeight: CGFloat = 250.0
         let keyboardWidth: CGFloat = 180.0
         let bottomLeftFrame = CGRect(
             x: 0,
             y: screenFrame.size.height - 40 - keyboardHeight - 20,
             width: keyboardWidth, height: keyboardHeight)
         let bottomRightFrame = CGRect(
             x: screenFrame.size.width - 20 - keyboardWidth,
             y:screenFrame.size.height - 40 - keyboardHeight - 20,
             width: keyboardWidth, height: keyboardHeight
         )
         view.addSubview(leftKeyboardView)
         view.addSubview(rightKeyboardView)
         leftKeyboardView.frame = bottomLeftFrame
         rightKeyboardView.frame = bottomRightFrame
     }

     func setupKeyModels() {
         leftKeyboardView.setupWithModel(leftKeyboardModel)
         rightKeyboardView.setupWithModel(rightKeyboardModel)
     }

     @objc func draggedView(_ sender:UIPanGestureRecognizer){
         guard let keyboardView = sender.view?.superview else {
             return
         }
         let translation = sender.translation(in: self.view)
         keyboardView.center = CGPoint(x: keyboardView.center.x + translation.x, y: keyboardView.center.y + translation.y)
         sender.setTranslation(CGPoint.zero, in: self.view)
     }
 }

 extension EmulatorKeyboardController: EmulatorKeyboardViewDelegate {
     func toggleAlternateKeys() {
         for keyboard in [leftKeyboardView, rightKeyboardView] {
             keyboard.toggleKeysStackView()
         }
     }
     func refreshModifierStates() {
         for keyboard in [leftKeyboardView, rightKeyboardView] {
             keyboard.refreshModifierStates()
         }
     }
     func updateTransparency(toAlpha alpha: Float) {
         for keyboard in [leftKeyboardView, rightKeyboardView] {
             keyboard.alpha = CGFloat(alpha)
         }
     }
 }

private extension UIImage {
    static func dot(size:CGSize, color:UIColor) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin:.zero, size:size))
        }
    }
}
