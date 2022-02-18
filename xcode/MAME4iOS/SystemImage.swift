//
//  SystemImage.swift
//  MAME4iOS
//
//  helper code for SystemImages
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
import UIKit

extension UIImage {
    @objc static func systemImageNamed(_ name: String, withFont font: UIFont?) -> UIImage? {
        guard let font = font else {
            return UIImage(systemName: name)
        }
        return UIImage(systemName: name, withConfiguration: SymbolConfiguration(font: font))
    }
    @objc static func systemImageNamed(_ name: String, withPointSize pointSize: CGFloat) -> UIImage? {
        return UIImage(systemName: name, withConfiguration: SymbolConfiguration(pointSize: pointSize))
    }
}

// convert text to a UIImage, replacing any strings of the form ":symbol:" with a systemImage
//      :symbol-name:                - return a UIImage created from [UIImage systemImageNamed] or [UIImage imageNamed]
//      :symbol-name:fallback:       - return symbol as UIImage or fallback text if image not found
//      :symbol-name:text            - return symbol + text
//      :symbol-name:fallback:text   - return (symbol or fallback) + text
//      text:symbol-name:text        - return text + symbol + text
extension UIImage {
    @objc static func imageWithString(_ text:String, withFont font:UIFont?) -> UIImage {
        var image:UIImage?
        var lhs = ""
        var rhs = text
        
        let arr = text.components(separatedBy: ":")
        if arr.count > 2 {
            lhs = arr.first!
            rhs = arr.last!
            image = UIImage.systemImageNamed(arr[1], withFont:font) ?? UIImage(named: arr[1]) ??
                    UIImage.systemImageNamed(arr[2], withFont:font) ?? UIImage(named: arr[2])

            // use fallback text if image not found.
            if (image == nil && arr.count == 4) {
                rhs = arr[2] + rhs
            }
        }
        
        // if we have both text and an image, combine image + text
        if (image == nil || !lhs.isEmpty || !rhs.isEmpty) {
            image = UIImage.imageWithText(lhs, image:image, text:rhs, font:font)
        }

        return image ?? UIImage()
    }
    @objc static func imageWithString(_ text:String) -> UIImage {
        return imageWithString(text, withFont: nil)
    }
    
    // smash together some text + image + text
    @objc static func imageWithText(_ textLeft:String?, image:UIImage?, text textRight:String?, font:UIFont?) -> UIImage {
        var image = image
        let textLeft = textLeft ?? ""
        let textRight = textRight ?? ""

        // if we have both text and an image, combine image + text
        if (image == nil || !textLeft.isEmpty || !textRight.isEmpty) {
            let font = font ?? UIFont.preferredFont(forTextStyle: .body)
            
            let spacing = CGFloat(4.0)
            let attributes = [NSAttributedString.Key.font:font]
            
            let textSize = textRight.boundingRect(with:.zero, options:.usesLineFragmentOrigin, attributes:attributes, context:nil)
            var size = CGSize(width:ceil(textSize.width), height:ceil(textSize.height))

            if (!textLeft.isEmpty) {
                let textSize = textLeft.boundingRect(with:.zero, options:.usesLineFragmentOrigin, attributes:attributes, context:nil)
                size.width = size.width + spacing + ceil(textSize.width)
                size.height = ceil(textSize.height)
            }

            if let image = image {
                size.width += image.size.width + spacing
                size.height = max(size.height, image.size.height)
            }
            
            image = UIGraphicsImageRenderer(size:size).image(actions: { _ in
                var point = CGPoint.zero
                
                if (!textLeft.isEmpty) {
                    textLeft.draw(at: CGPoint(x:point.x, y:(size.height - textSize.height)/2), withAttributes:attributes)
                    point.x += textLeft.boundingRect(with:.zero, options:.usesLineFragmentOrigin, attributes:attributes, context: nil).width + spacing
                }
                
                if let image = image {
                    // TODO: align to baseline?
                    image.draw(at: CGPoint(x: point.x, y: (size.height - image.size.height)/2))
                    point.x += image.size.width + spacing
                }

                textRight.draw(at: CGPoint(x:point.x, y:(size.height - textSize.height)/2), withAttributes:attributes)
            })
        }
        
        return image?.withRenderingMode(.alwaysTemplate) ?? UIImage()
    }
}
