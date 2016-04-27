//
//  ZActivityIndicatorView.swift
//  ZActivityIndicatorView
//
//  Created by ZhangZZZZ on 16/4/25.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

class ZActivityIndicatorView: UIView {
    
    private var isAnimating: Bool = false
    var autoAnimating: Bool = false
    var duration: NSTimeInterval = 1.5
    var timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    
    private lazy var activityIndicatorLayer: CAShapeLayer = {
        let activityIndicatorLayer = CAShapeLayer()
        activityIndicatorLayer.fillColor = nil
        activityIndicatorLayer.strokeColor = self.strokeColor.CGColor
        return activityIndicatorLayer
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
    
    var hidesWhenStopped: Bool = false {
        didSet {
            self.hidden = !self.isAnimating && self.hidesWhenStopped
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ZActivityIndicatorView.resetAnimating), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(UIApplicationDidBecomeActiveNotification)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        self.prepare()
    }
    
    func prepare() {
        
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let radius = min(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2) -
            self.activityIndicatorLayer.lineWidth / 2
        let startAngle: CGFloat = 0.0
        let endAngle = CGFloat(2 * M_PI)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.activityIndicatorLayer.path = path.CGPath
        self.activityIndicatorLayer.strokeStart = 0.0
        self.activityIndicatorLayer.strokeEnd = 0.0
        
        if self.autoAnimating {
            self.startAnimating()
        }
    }
    
    func startAnimating() {
        
        if self.isAnimating { return }
        
        let animation = CABasicAnimation()
        animation.keyPath = "transform.rotation"
        animation.duration = self.duration / 0.375
        animation.fromValue = 0
        animation.toValue = CGFloat(2 * M_PI)
        animation.repeatCount = Float.infinity
        animation.removedOnCompletion = false
        self.activityIndicatorLayer.addAnimation(animation, forKey: "com.zevwings.animation.rotate")
        
        let headAnimation = CABasicAnimation()
        headAnimation.keyPath = "strokeStart"
        headAnimation.duration = self.duration / 1.5
        headAnimation.fromValue = 0
        headAnimation.toValue = 0.25
        headAnimation.timingFunction = self.timingFunction;

        let tailAnimation = CABasicAnimation()
        tailAnimation.keyPath = "strokeEnd"
        tailAnimation.duration = self.duration / 1.5
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1
        tailAnimation.timingFunction = self.timingFunction;

        
        let endHeadAnimation = CABasicAnimation()
        endHeadAnimation.keyPath = "strokeStart";
        endHeadAnimation.beginTime = self.duration / 1.5
        endHeadAnimation.duration = self.duration / 3.0
        endHeadAnimation.fromValue = 0.25
        endHeadAnimation.toValue = 1.0
        endHeadAnimation.timingFunction = self.timingFunction;

        let endTailAnimation = CABasicAnimation()
        endTailAnimation.keyPath = "strokeEnd"
        endTailAnimation.beginTime = self.duration / 1.5
        endTailAnimation.duration = self.duration / 3.0
        endTailAnimation.fromValue = 1.0
        endTailAnimation.toValue = 1.0
        endTailAnimation.timingFunction = self.timingFunction;

        let animations = CAAnimationGroup()
        animations.duration = self.duration
        animations.animations = [headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]
        animations.repeatCount = Float.infinity
        animations.removedOnCompletion = false
        self.activityIndicatorLayer.addAnimation(animations, forKey: "com.zevwings.animation.stroke")
        
        self.isAnimating = true
 
        if self.hidesWhenStopped {
            self.hidden = false
        }
    }
    
    func stopAnimating() {
        if !self.isAnimating { return }
        
        self.activityIndicatorLayer.removeAnimationForKey("com.zevwings.animation.rotate")
        self.activityIndicatorLayer.removeAnimationForKey("com.zevwings.animation.stroke")
        self.isAnimating = false;
        
        if self.hidesWhenStopped {
            self.hidden = true
        }
    }
    
    func resetAnimating() {
        if self.isAnimating {
            self.stopAnimating()
            self.startAnimating()
        }
    }
}
