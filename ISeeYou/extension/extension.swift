//
//  extension.swift
//  ISeeYou
//
//  Created by 李嘉晟 on 2018/6/12.
//  Copyright © 2018 李嘉晟. All rights reserved.
//

import UIKit

extension UIColor {
    static var blueZero: UIColor { return UIColor.init(rgb: 0x64E4FF)}
    static var blueOne: UIColor { return UIColor.init(rgb: 0x3A7BD5)}
    static var grayZero: UIColor {return UIColor.init(rgb: 0x9B9B9B)}
    static var grayOne: UIColor {return UIColor.init(rgb: 0x424242)}
    static var greenZero: UIColor { return UIColor.init(rgb: 0x226262)}
    
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: alpha)
    }
    
    convenience init(rgb: Int) {
        self.init(red: (rgb >> 16) & 0xFF,
                  green: (rgb >> 8) & 0xFF,
                  blue: rgb & 0xFF)
    }
}
