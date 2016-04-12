//
//  ZIndefiniteAnimatedView.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

class ZIndefiniteAnimatedView: UIView {
    
    private var sharpLayer: CAShapeLayer?
    var radius: CGFloat = 18.0 {
        didSet {
            self.sharpLayer?.removeFromSuperlayer()
            self.sharpLayer = nil;
            if self.superview != nil {
                self.layoutAnimatedLayer()
            }
        }
    }
    
    var strokeThickness: CGFloat = 2.0 {
        didSet {
            self.sharpLayer?.lineWidth = self.strokeThickness
        }
    }
    
    var strokeColor: UIColor? {
        didSet {
            self.sharpLayer?.strokeColor = self.strokeColor?.CGColor;
        }
    }
    
    override var frame: CGRect {
        didSet {
            if CGRectEqualToRect(self.frame, super.frame) {
                super.frame = frame
                if self.superview != nil {
                    self.layoutAnimatedLayer()
                }
            }
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if newSuperview == nil {
            self.sharpLayer?.removeFromSuperlayer()
            self.sharpLayer = nil
        } else {
            self.layer.addSublayer(self.animatedLayer())
            self.frame = self.sharpLayer!.bounds
            print(self.sharpLayer?.frame)
        }
    }
    
    private func animatedLayer() -> CAShapeLayer {
        if self.sharpLayer == nil {
            let arcCenter = CGPointMake(self.radius+self.strokeThickness/2+5, self.radius+self.strokeThickness/2+5);
            let smoothedPath = UIBezierPath(arcCenter: arcCenter, radius: self.radius, startAngle: CGFloat(M_PI*3/2), endAngle: CGFloat(M_PI/2+M_PI*5), clockwise: true)
            self.sharpLayer = CAShapeLayer()
            self.sharpLayer?.contentsScale = UIScreen.mainScreen().scale
            self.sharpLayer?.frame = CGRectMake(0.0, 0.0, arcCenter.x * 2.0, arcCenter.y * 2.0)
            self.sharpLayer?.strokeColor = self.strokeColor?.CGColor
            self.sharpLayer?.fillColor = UIColor.clearColor().CGColor
            self.sharpLayer?.lineWidth = self.strokeThickness
            self.sharpLayer?.lineCap = kCALineCapRound
            self.sharpLayer?.lineJoin = kCALineJoinBevel
            self.sharpLayer?.path = smoothedPath.CGPath
            
            let maskLayer = CALayer()
            let contentImage = Config.imageFor("angle-mask")
            maskLayer.contents = contentImage?.CGImage
            maskLayer.frame = self.sharpLayer!.frame
            self.sharpLayer?.mask = maskLayer
            
            let animationDuration: NSTimeInterval = 1
            let linearCurve: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = 0
            animation.toValue = (M_PI*2)
            animation.duration = animationDuration
            animation.timingFunction = linearCurve
            animation.removedOnCompletion = false
            animation.repeatCount = Float.infinity
            animation.fillMode = kCAFillModeForwards
            animation.autoreverses = false
            self.sharpLayer?.mask?.addAnimation(animation, forKey: "rotate")
            
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = 0.015;
            strokeStartAnimation.toValue = 0.515

            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = 0.485
            strokeEndAnimation.toValue = 0.985
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = animationDuration
            animationGroup.repeatCount = Float.infinity
            animationGroup.removedOnCompletion = false
            animationGroup.timingFunction = linearCurve;
            animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
            self.sharpLayer?.addAnimation(animationGroup, forKey: "progress")
        }
        return self.sharpLayer!
    }
    
    func layoutAnimatedLayer() {
        
        let widthDiff = CGRectGetWidth(self.bounds) - CGRectGetWidth(self.sharpLayer!.bounds);
        let heightDiff = CGRectGetHeight(self.bounds) - CGRectGetHeight(self.sharpLayer!.bounds);
        self.sharpLayer?.position = CGPointMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.sharpLayer!.bounds) / 2 - widthDiff / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.sharpLayer!.bounds) / 2 - heightDiff / 2);
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSizeMake((self.radius+self.strokeThickness/2+5)*2, (self.radius+self.strokeThickness/2+5)*2)
    }
}
