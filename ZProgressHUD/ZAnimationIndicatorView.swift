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
        activityIndicatorLayer.strokeColor = self.strokeColor.cgColor
        activityIndicatorLayer.contentsScale = UIScreen.main().scale
        activityIndicatorLayer.lineCap = kCALineCapRound
        activityIndicatorLayer.lineJoin = kCALineJoinBevel
        activityIndicatorLayer.lineWidth = self.lineWidth
        activityIndicatorLayer.mask = self.maskLayer
        return activityIndicatorLayer
    }()
    
    private lazy var maskLayer: CALayer = {

        let maskLayer = CALayer()
        let contentImage = UIImage.resource(named: "angle-mask")
        maskLayer.contents = contentImage?.cgImage
        return maskLayer
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
    
    override var frame: CGRect {
        didSet {
            self.layoutSubviews()
        }
    }
    
    private var isAnimating: Bool = false
    var autoAnimating: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default().addObserver(self, selector: #selector(self.resetAnimating), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(NSNotification.Name.UIApplicationDidBecomeActive)
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
        self.maskLayer.frame = self.activityIndicatorLayer.frame
    }
    
    private func prepare() {
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = min(self.bounds.width / 2, self.bounds.height / 2) -
            self.activityIndicatorLayer.lineWidth / 2
        let startAngle = CGFloat(M_PI * 3 / 2)
        let endAngle = CGFloat(M_PI / 2 + M_PI * 5)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.activityIndicatorLayer.path = path.cgPath
        if self.autoAnimating {
            self.startAnimating()
        }
    }
    
    func startAnimating() {
        
        if self.isAnimating {
            return
        }
        
        self.isHidden = false
        
        let animationDuration: TimeInterval = 1.0
        let timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = M_PI * 2
        animation.duration = animationDuration
        animation.timingFunction = timingFunction
        animation.isRemovedOnCompletion = false
        animation.repeatCount = Float.infinity
        animation.fillMode = kCAFillModeForwards
        animation.autoreverses = false
        self.maskLayer.add(animation, forKey: "com.zevwings.animation.rotate")
        
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.015
        strokeStartAnimation.toValue = 0.515
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.485
        strokeEndAnimation.toValue = 0.985
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = animationDuration
        animationGroup.repeatCount = Float.infinity
        animationGroup.isRemovedOnCompletion = false
        animationGroup.timingFunction = timingFunction
        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        self.activityIndicatorLayer.add(animationGroup, forKey: "com.zevwings.animation.progress")
        
        self.isAnimating = true
    }
    
    private func stopAnimating() {
        if !self.isAnimating {
            return
        }
        self.maskLayer.removeAllAnimations()
        self.activityIndicatorLayer.removeAllAnimations()
        self.isHidden = true
        self.isAnimating = false
    }
    
    func resetAnimating() {
        if self.isAnimating {
            self.stopAnimating()
            self.startAnimating()
        }
    }
}
