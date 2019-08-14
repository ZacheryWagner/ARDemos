//
//  UIColor.swift
//  SwiftTacToe
//
//  Created by Zachery Wagner on 7/6/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    /// The main screen color
    static var violet = UIColor(hex: "#c09da7")

    /// Color used to indicate easy difficulty
    static var easyGreen = UIColor(hex: "#9dc0b6")

    /// Color used to indicate medium difficulty
    static var mediumYellow = UIColor(hex: "#efed6e")

    /// Color used to indicate hard difficulty
    static var hardRed = UIColor(hex: "#ef846e")

    /**
     * Allows the construction of a UIColor from a hex value
     * - Parameter hex: a `String` of the format "#000000" to be a color
     */
    public convenience init?(hex: String) {
        let nHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: nHex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch nHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        default:
            self.init(ciColor: .clear)
        }
    }
}
