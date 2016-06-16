//
//  ZGradientLayer.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

class ZGradientLayer: CAGradientLayer {

    var gradientCenter: CGPoint = CGPoint.zero
    
    override func draw(in ctx: CGContext) {
        
        let locationsCount = 2
        let locations:[CGFloat] = [0.0, 1.0]
        let colors:[CGFloat] = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.75]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let gradient = CGGradient(colorComponentsSpace: colorSpace,
                                  components: colors,
                                  locations: locations,
                                  count: locationsCount)
        
        let radius = min(self.bounds.size.width , self.bounds.size.height)
        
        ctx.drawRadialGradient (gradient!,
                                startCenter: self.gradientCenter,
                                startRadius: 0,
                                endCenter: self.gradientCenter,
                                endRadius: radius,
                                options: .drawsAfterEndLocation)
    }
}
