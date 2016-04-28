//
//  ZIndefiniteAnimatedView.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

class ZAnimationIndicatorView: UIView {
    
    private lazy var activityIndicatorLayer: CAShapeLayer = {
        
        let activityIndicatorLayer = CAShapeLayer()
        activityIndicatorLayer.fillColor = nil
        activityIndicatorLayer.strokeColor = self.strokeColor.CGColor
        activityIndicatorLayer.contentsScale = UIScreen.mainScreen().scale
        activityIndicatorLayer.lineCap = kCALineCapRound
        activityIndicatorLayer.lineJoin = kCALineJoinBevel
        activityIndicatorLayer.lineWidth = self.lineWidth
        activityIndicatorLayer.mask = self.maskLayer
        return activityIndicatorLayer
    }()
    
    private lazy var maskLayer: CALayer = {

        let maskLayer = CALayer()
        let contentImage = UIImage.resourceNamed("angle-mask")
        maskLayer.contents = contentImage?.CGImage
        return maskLayer
    }()
    
    var lineWidth: CGFloat = 3.0 {
        didSet {
            self.activityIndicatorLayer.lineWidth = self.lineWidth
            self.prepare()
        }
    }
    
    var strokeColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.activityIndicatorLayer.strokeColor = self.strokeColor.CGColor
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.layoutSubviews()
        }
    }
    
    private var isAnimating: Bool = false
    var autoAnimating: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.resetAnimating), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(UIApplicationDidBecomeActiveNotification)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if newSuperview == nil {
            self.stopAnimating()
            self.activityIndicatorLayer.removeFromSuperlayer()
        } else {
            self.layer.addSublayer(self.activityIndicatorLayer)
            self.prepare()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.activityIndicatorLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
        self.maskLayer.frame = self.activityIndicatorLayer.frame
    }
    
    private func prepare() {
        
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let radius = min(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2) -
            self.activityIndicatorLayer.lineWidth / 2
        let startAngle = CGFloat(M_PI * 3 / 2)
        let endAngle = CGFloat(M_PI / 2 + M_PI * 5)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.activityIndicatorLayer.path = path.CGPath
        if self.autoAnimating {
            self.startAnimating()
        }
    }
    
    func startAnimating() {
        
        if self.isAnimating {
            return
        }
        
        self.hidden = false
        
        let animationDuration: NSTimeInterval = 1.0
        let timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = M_PI * 2
        animation.duration = animationDuration
        animation.timingFunction = timingFunction
        animation.removedOnCompletion = false
        animation.repeatCount = Float.infinity
        animation.fillMode = kCAFillModeForwards
        animation.autoreverses = false
        self.maskLayer.addAnimation(animation, forKey: "com.zevwings.animation.rotate")
        
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.015
        strokeStartAnimation.toValue = 0.515
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.485
        strokeEndAnimation.toValue = 0.985
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = animationDuration
        animationGroup.repeatCount = Float.infinity
        animationGroup.removedOnCompletion = false
        animationGroup.timingFunction = timingFunction
        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        self.activityIndicatorLayer.addAnimation(animationGroup, forKey: "com.zevwings.animation.progress")
        
        self.isAnimating = true
    }
    
    private func stopAnimating() {
        if !self.isAnimating {
            return
        }
        self.maskLayer.removeAllAnimations()
        self.activityIndicatorLayer.removeAllAnimations()
        self.hidden = true
        self.isAnimating = false
    }
    
    func resetAnimating() {
        if self.isAnimating {
            self.stopAnimating()
            self.startAnimating()
        }
    }
}
