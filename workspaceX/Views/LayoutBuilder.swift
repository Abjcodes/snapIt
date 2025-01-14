//
//  LayoutBuilder.swift
//  workspaceX
//
//  Created by P10 on 06/01/25.
//

import Foundation

import Foundation
import AppKit

enum WindowLayout: String, Codable, CaseIterable {
    case `default` = "Default"
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case leftOneThird = "Left One Third"
    case rightOneThird = "Right One Third"
    case middleOneThird = "Middle One Third"
    case leftTwoThirds = "Left Two Thirds"
    case rightTwoThirds = "Right Two Thirds"
    case topLeftQuarter = "Top Left Quarter"
    case bottomLeftQuarter = "Bottom Left Quarter"
    case topRightQuarter = "Top Right Quarter"
    case bottomRightQuarter = "Bottom Right Quarter"
    case topLeftSixth = "Top Left Sixth"
    case topMiddleSixth = "Top Middle Sixth"
    case topRightSixth = "Top Right Sixth"
    case bottomLeftSixth = "Bottom Left Sixth"
    case bottomMiddleSixth = "Bottom Middle Sixth"
    case bottomRightSixth = "Bottom Right Sixth"
    
    var frame: CGRect {
        guard let screen = NSScreen.main?.visibleFrame else { return .zero }
        
        switch self {
        case .default:
            return screen
        case .leftHalf:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width/2, height: screen.height)
        case .rightHalf:
            return CGRect(x: screen.midX, y: screen.minY, width: screen.width/2, height: screen.height)
        case .topHalf:
            return CGRect(x: screen.minX, y: screen.midY, width: screen.width, height: screen.height/2)
        case .bottomHalf:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: screen.height/2)
        case .leftOneThird:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width/3, height: screen.height)
        case .rightOneThird:
            return CGRect(x: screen.maxX - screen.width/3, y: screen.minY, width: screen.width/3, height: screen.height)
        case .middleOneThird:
            return CGRect(x: screen.minX + screen.width/3, y: screen.minY, width: screen.width/3, height: screen.height)
        case .leftTwoThirds:
            return CGRect(x: screen.minX, y: screen.minY, width: 2*screen.width/3, height: screen.height)
        case .rightTwoThirds:
            return CGRect(x: screen.maxX - 2*screen.width/3, y: screen.minY, width: 2*screen.width/3, height: screen.height)
        case .topLeftQuarter:
            return CGRect(x: screen.minX, y: screen.midY, width: screen.width/2, height: screen.height/2)
        case .bottomLeftQuarter:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width/2, height: screen.height/2)
        case .topRightQuarter:
            return CGRect(x: screen.midX, y: screen.midY, width: screen.width/2, height: screen.height/2)
        case .bottomRightQuarter:
            return CGRect(x: screen.midX, y: screen.minY, width: screen.width/2, height: screen.height/2)
        case .topLeftSixth:
            return CGRect(x: screen.minX, y: screen.midY, width: screen.width/3, height: screen.height/2)
        case .topMiddleSixth:
            return CGRect(x: screen.minX + screen.width/3, y: screen.midY, width: screen.width/3, height: screen.height/2)
        case .topRightSixth:
            return CGRect(x: screen.maxX - screen.width/3, y: screen.midY, width: screen.width/3, height: screen.height/2)
        case .bottomLeftSixth:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width/3, height: screen.height/2)
        case .bottomMiddleSixth:
            return CGRect(x: screen.minX + screen.width/3, y: screen.minY, width: screen.width/3, height: screen.height/2)
        case .bottomRightSixth:
            return CGRect(x: screen.maxX - screen.width/3, y: screen.minY, width: screen.width/3, height: screen.height/2)
        }
    }
}
