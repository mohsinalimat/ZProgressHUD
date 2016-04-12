//
//  ZGradientLayer.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

class ZGradientLayer: CAGradientLayer {

    var gradientCenter: CGPoint = CGPointZero
    
    override func drawInContext(ctx: CGContext) {
        
        let locationsCount = 2
        let locations:[CGFloat] = [0.0, 1.0]
        let colors:[CGFloat] = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.75]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount)
        let radius = min(self.bounds.size.width , self.bounds.size.height)
        
        CGContextDrawRadialGradient (ctx, gradient, self.gradientCenter, 0, self.gradientCenter, radius, .DrawsAfterEndLocation)
    }
}
