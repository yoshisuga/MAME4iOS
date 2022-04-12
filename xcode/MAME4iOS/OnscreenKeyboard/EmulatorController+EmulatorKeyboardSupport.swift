//
 //  EmulatorController+EmulatorKeyboardSupport.swift
 //  MAME4iOS
 //
 //  Created by Yoshi Sugawara on 11/24/21.
 //  Copyright © 2021 MAME4iOS Team. All rights reserved.
 //

extension EmulatorController {
    
     var leftKeyboardModel: EmulatorKeyboardViewModel {
        return EmulatorKeyboardViewModel(keys: [
           [
             EmulatorKeyboardKey(label: "1", code: Int(MYOSD_KEY_1.rawValue)),
             EmulatorKeyboardKey(label: "2", code: Int(MYOSD_KEY_2.rawValue)),
             EmulatorKeyboardKey(label: "3", code: Int(MYOSD_KEY_3.rawValue)),
             EmulatorKeyboardKey(label: "4", code: Int(MYOSD_KEY_4.rawValue)),
             EmulatorKeyboardKey(label: "5", code: Int(MYOSD_KEY_5.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "q", code: Int(MYOSD_KEY_Q.rawValue)),
             EmulatorKeyboardKey(label: "w", code: Int(MYOSD_KEY_W.rawValue)),
             EmulatorKeyboardKey(label: "e", code: Int(MYOSD_KEY_E.rawValue)),
             EmulatorKeyboardKey(label: "r", code: Int(MYOSD_KEY_R.rawValue)),
             EmulatorKeyboardKey(label: "t", code: Int(MYOSD_KEY_T.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "a", code: Int(MYOSD_KEY_A.rawValue)),
             EmulatorKeyboardKey(label: "s", code: Int(MYOSD_KEY_S.rawValue)),
             EmulatorKeyboardKey(label: "d", code: Int(MYOSD_KEY_D.rawValue)),
             EmulatorKeyboardKey(label: "f", code: Int(MYOSD_KEY_F.rawValue)),
             EmulatorKeyboardKey(label: "g", code: Int(MYOSD_KEY_G.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "z", code: Int(MYOSD_KEY_Z.rawValue)),
             EmulatorKeyboardKey(label: "x", code: Int(MYOSD_KEY_X.rawValue)),
             EmulatorKeyboardKey(label: "c", code: Int(MYOSD_KEY_C.rawValue)),
             EmulatorKeyboardKey(label: "v", code: Int(MYOSD_KEY_V.rawValue)),
             EmulatorKeyboardKey(label: "b", code: Int(MYOSD_KEY_B.rawValue)),
           ],
             [
                 EmulatorKeyboardKey(label: "SHIFT", code: Int(MYOSD_KEY_LSHIFT.rawValue), keySize: .standard, isModifier: true, imageName: "shift", imageNameHighlighted: "shift.fill"),
                 EmulatorKeyboardKey(label: "Fn", code: 9000, keySize: .standard, imageName: "fn"),
                 EmulatorKeyboardKey(label: "CTRL", code: Int(MYOSD_KEY_LCONTROL.rawValue), isModifier: true, imageName: "control"),
                 EmulatorKeyboardKey(label: "Space", code: Int(MYOSD_KEY_SPACE.rawValue), keySize: .wide)
           ]
        ],
        alternateKeys: [
           [
             EmulatorKeyboardKey(label: "ESC", code: Int(MYOSD_KEY_ESC.rawValue), imageName: "escape"),
              SliderKey(keySize: .standard)
           ],
           [
             EmulatorKeyboardKey(label: "F1", code: Int(MYOSD_KEY_F1.rawValue)),
             EmulatorKeyboardKey(label: "F2", code: Int(MYOSD_KEY_F2.rawValue)),
             EmulatorKeyboardKey(label: "F3", code: Int(MYOSD_KEY_F3.rawValue)),
             EmulatorKeyboardKey(label: "F4", code: Int(MYOSD_KEY_F4.rawValue)),
             EmulatorKeyboardKey(label: "F5", code: Int(MYOSD_KEY_F5.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "tab", code: Int(MYOSD_KEY_TAB.rawValue), imageName: "arrow.right.to.line"),
             EmulatorKeyboardKey(label: "=", code: Int(MYOSD_KEY_EQUALS.rawValue)),
             EmulatorKeyboardKey(label: "/", code: Int(MYOSD_KEY_SLASH.rawValue)),
             EmulatorKeyboardKey(label: "[", code: Int(MYOSD_KEY_OPENBRACE.rawValue)),
             EmulatorKeyboardKey(label: "]", code: Int(MYOSD_KEY_CLOSEBRACE.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "-", code: Int(MYOSD_KEY_MINUS.rawValue)),
             EmulatorKeyboardKey(label: ";", code: Int(MYOSD_KEY_COLON.rawValue)),
             EmulatorKeyboardKey(label: "~", code: Int(MYOSD_KEY_TILDE.rawValue)),
             EmulatorKeyboardKey(label: "'", code: Int(MYOSD_KEY_QUOTE.rawValue))
           ],
           [
             EmulatorKeyboardKey(label: "SHIFT", code: Int(MYOSD_KEY_LSHIFT.rawValue), keySize: .standard, isModifier: true, imageName: "shift", imageNameHighlighted: "shift.fill"),
             EmulatorKeyboardKey(label: "Fn", code: 9000, keySize: .standard, imageName: "fn"),
             EmulatorKeyboardKey(label: "CTRL", code: Int(MYOSD_KEY_LCONTROL.rawValue), isModifier: true, imageName: "control"),
             EmulatorKeyboardKey(label: "Space", code: Int(MYOSD_KEY_SPACE.rawValue), keySize: .wide)
           ]
        ])
     }

     @objc var rightKeyboardModel: EmulatorKeyboardViewModel {
        EmulatorKeyboardViewModel(keys: [
           [
             EmulatorKeyboardKey(label: "6", code: Int(MYOSD_KEY_6.rawValue)),
             EmulatorKeyboardKey(label: "7", code: Int(MYOSD_KEY_7.rawValue)),
             EmulatorKeyboardKey(label: "8", code: Int(MYOSD_KEY_8.rawValue)),
             EmulatorKeyboardKey(label: "9", code: Int(MYOSD_KEY_9.rawValue)),
             EmulatorKeyboardKey(label: "0", code: Int(MYOSD_KEY_0.rawValue))
           ],
           [
             EmulatorKeyboardKey(label: "y", code: Int(MYOSD_KEY_Y.rawValue)),
             EmulatorKeyboardKey(label: "u", code: Int(MYOSD_KEY_U.rawValue)),
             EmulatorKeyboardKey(label: "i", code: Int(MYOSD_KEY_I.rawValue)),
             EmulatorKeyboardKey(label: "o", code: Int(MYOSD_KEY_O.rawValue)),
             EmulatorKeyboardKey(label: "p", code: Int(MYOSD_KEY_P.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "h", code: Int(MYOSD_KEY_H.rawValue)),
             EmulatorKeyboardKey(label: "j", code: Int(MYOSD_KEY_J.rawValue)),
             EmulatorKeyboardKey(label: "k", code: Int(MYOSD_KEY_K.rawValue)),
             EmulatorKeyboardKey(label: "l", code: Int(MYOSD_KEY_L.rawValue)),
             EmulatorKeyboardKey(label: "'", code: Int(MYOSD_KEY_QUOTE.rawValue))
           ],
           [
             EmulatorKeyboardKey(label: "n", code: Int(MYOSD_KEY_N.rawValue)),
             EmulatorKeyboardKey(label: "m", code: Int(MYOSD_KEY_M.rawValue)),
             EmulatorKeyboardKey(label: ",", code: Int(MYOSD_KEY_COMMA.rawValue)),
             EmulatorKeyboardKey(label: ".", code: Int(MYOSD_KEY_STOP.rawValue)),
             EmulatorKeyboardKey(label: "BKSPC", code: Int(MYOSD_KEY_BACKSPACE.rawValue), imageName: "delete.left", imageNameHighlighted: "delete.left.fill")
           ],
           [
             EmulatorKeyboardKey(label: "Alt", code: Int(MYOSD_KEY_LALT.rawValue), isModifier: true, imageName: "alt"),
             EmulatorKeyboardKey(label: "RAlt", code: Int(MYOSD_KEY_RALT.rawValue), isModifier: true, imageName: "option"),
             EmulatorKeyboardKey(label: "tab", code: Int(MYOSD_KEY_TAB.rawValue), imageName: "arrow.right.to.line"),
             EmulatorKeyboardKey(label: "RETURN", code: Int(MYOSD_KEY_ENTER.rawValue), keySize: .wide)
           ],
        ],
        alternateKeys: [
           [
             EmulatorKeyboardKey(label: "F6", code: Int(MYOSD_KEY_F6.rawValue)),
             EmulatorKeyboardKey(label: "F7", code: Int(MYOSD_KEY_F7.rawValue)),
             EmulatorKeyboardKey(label: "F8", code: Int(MYOSD_KEY_F8.rawValue)),
             EmulatorKeyboardKey(label: "F9", code: Int(MYOSD_KEY_F9.rawValue)),
             EmulatorKeyboardKey(label: "F10", code: Int(MYOSD_KEY_F10.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "PAGEUP", code: Int(MYOSD_KEY_PGUP.rawValue), imageName: "arrow.up.doc"),
             EmulatorKeyboardKey(label: "HOME", code: Int(MYOSD_KEY_HOME.rawValue), imageName: "house"),
             EmulatorKeyboardKey(label: "INS", code: Int(MYOSD_KEY_INSERT.rawValue), imageName: "text.insert"),
             EmulatorKeyboardKey(label: "END", code: Int(MYOSD_KEY_END.rawValue)),
             EmulatorKeyboardKey(label: "PAGEDWN", code: Int(MYOSD_KEY_PGDN.rawValue), imageName: "arrow.down.doc"),
           ],
           [
             EmulatorKeyboardKey(label: "F11", code: Int(MYOSD_KEY_F11.rawValue)),
             EmulatorKeyboardKey(label: "⬆️", code: Int(MYOSD_KEY_UP.rawValue), imageName: "arrow.up"),
              SpacerKey(),
              SpacerKey(),
             EmulatorKeyboardKey(label: "F12", code: Int(MYOSD_KEY_F12.rawValue)),
           ],
           [
             EmulatorKeyboardKey(label: "⬅️", code: Int(MYOSD_KEY_LEFT.rawValue), imageName: "arrow.left"),
             EmulatorKeyboardKey(label: "⬇️", code: Int(MYOSD_KEY_DOWN.rawValue), imageName: "arrow.down"),
             EmulatorKeyboardKey(label: "➡️", code: Int(MYOSD_KEY_RIGHT.rawValue), imageName: "arrow.right"),
              SpacerKey(),
             EmulatorKeyboardKey(label: "DEL", code: Int(MYOSD_KEY_DEL.rawValue), imageName: "clear", imageNameHighlighted: "clear.fill"),
           ],
           [
             EmulatorKeyboardKey(label: "RETURN", code: Int(MYOSD_KEY_ENTER.rawValue), keySize: .wide)
           ]
        ])
     }
     
     func getEmulatorKeyboard() -> EmulatorKeyboardController? {
         return children.first(where: {$0 is EmulatorKeyboardController}) as! EmulatorKeyboardController?
     }
     
     @objc func getEmulatorKeyboardView() -> UIView? {
         return getEmulatorKeyboard()?.view
     }

     @objc func setupEmulatorKeyboard() {
         // if keyboard is already setup, we are done
         if let _ = getEmulatorKeyboard() {
             return
         }
         let keyboard = EmulatorKeyboardController(
             leftKeyboardModel: leftKeyboardModel,
             rightKeyboardModel: rightKeyboardModel
         )
         keyboard.rightKeyboardModel.delegate = self as? EmulatorKeyboardKeyPressedDelegate
         keyboard.leftKeyboardModel.delegate = self as? EmulatorKeyboardKeyPressedDelegate
         
         keyboard.rightKeyboardModel.modifierDelegate = self as? EmulatorKeyboardModifierPressedDelegate
         keyboard.leftKeyboardModel.modifierDelegate = self as? EmulatorKeyboardModifierPressedDelegate

         guard let keyboardView = keyboard.view else { return }
         addChild(keyboard)
         keyboard.didMove(toParent: self)
         view.addSubview(keyboardView)
         keyboardView.translatesAutoresizingMaskIntoConstraints = false
         keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
         keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
         keyboardView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
         keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
         //view.bringSubviewToFront(keyboardView)
     }
     
     @objc func killEmulatorKeyboard() {
         if let keyboard = getEmulatorKeyboard() {
             keyboard.view.removeFromSuperview()
             keyboard.willMove(toParent: nil)
             keyboard.removeFromParent()
             keyboard.didMove(toParent: nil)
         }
     }

 }
