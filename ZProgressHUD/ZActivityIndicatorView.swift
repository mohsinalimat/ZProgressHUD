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
    var duration: TimeInterval = 1.5
    var timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    
    private lazy var activityIndicatorLayer: CAShapeLayer = {
        let activityIndicatorLayer = CAShapeLayer()
        activityIndicatorLayer.fillColor = nil
        activityIndicatorLayer.strokeColor = self.strokeColor.cgColor
        return activityIndicatorLayer
    }()
    
    var lineWidth: CGFloat = 3.0 {
        didSet {
            self.activityIndicatorLayer.lineWidth = self.lineWidth
            self.prepare()
        }
    }
    
    var strokeColor: UIColor = UIColor.white() {
        didSet {
            self.activityIndicatorLayer.strokeColor = self.strokeColor.cgColor
        }
    }
    
    var hidesWhenStopped: Bool = false {
        didSet {
            self.isHidden = !self.isAnimating && self.hidesWhenStopped
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default().addObserver(self, selector: #selector(ZActivityIndicatorView.resetAnimating), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(NSNotification.Name.UIApplicationDidBecomeActive)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
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
        self.activityIndicatorLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.prepare()
    }
    
    func prepare() {
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = min(self.bounds.width / 2, self.bounds.height / 2) -
            self.activityIndicatorLayer.lineWidth / 2
        let startAngle: CGFloat = 0.0
        let endAngle = CGFloat(2 * M_PI)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.activityIndicatorLayer.path = path.cgPath
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
        animation.isRemovedOnCompletion = false
        self.activityIndicatorLayer.add(animation, forKey: "com.zevwings.animation.rotate")
        
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
        animations.isRemovedOnCompletion = false
        self.activityIndicatorLayer.add(animations, forKey: "com.zevwings.animation.stroke")
        
        self.isAnimating = true
 
        if self.hidesWhenStopped {
            self.isHidden = false
        }
    }
    
    func stopAnimating() {
        if !self.isAnimating { return }
        
        self.activityIndicatorLayer.removeAnimation(forKey: "com.zevwings.animation.rotate")
        self.activityIndicatorLayer.removeAnimation(forKey: "com.zevwings.animation.stroke")
        self.isAnimating = false;
        
        if self.hidesWhenStopped {
            self.isHidden = true
        }
    }
    
    func resetAnimating() {
        if self.isAnimating {
            self.stopAnimating()
            self.startAnimating()
        }
    }
}
