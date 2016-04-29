//
//  ZProgressHUD.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/3/20.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

public enum ZProgressHUDStyle {
    case Ligtht
    case Dark
    case Custom
}

public enum ZProgressHUDMaskType {
    case None
    case Clear
    case Black
    case Gradient
    case Custom
}

public enum ZProgressHUDPositionType {
    case Bottom
    case Center
}

public enum ZProgressHUDProgressType {
    case General
    case Animated
    case Native
}

public enum ZProgressHUDStatusType {
    
    case Error
    case Success
    case Info
    case Custom
    
    case PureStatus
    
    case Indicator
    case Progress // development
}


public let ZProgressHUDDidRecieveTouchEvent: String = "com.zevwings.events.touchevent"

public class ZProgressHUD: UIView {
    
    private var lineWidth: CGFloat = 2.0
    private var fadeOutTimer: NSTimer?
    
    private var minmumSize = CGSizeMake(100, 100)
    private var pureLabelminmumSize = CGSizeMake(100, 28.0)
    private let maxmumLabelSize = CGSizeMake(CGRectGetWidth(UIScreen.mainScreen().bounds) / 2.0, 260)
    private let minmumLabelHeight: CGFloat = 20.0
    private var minimumDismissDuration: NSTimeInterval = 3.0
    private var fadeInAnimationDuration: NSTimeInterval = 0.15
    private var fadeOutAnimationDuration: NSTimeInterval = 0.25

    private var errorImage: UIImage?
    private var successImage: UIImage?
    private var infoImage: UIImage?
    private var customImage: UIImage?
    
    private var fgColor: UIColor?
    private var bgColor: UIColor?
    private var bgLayerColor: UIColor?

    private var defaultStyle: ZProgressHUDStyle = .Dark
    private var defaultMaskType: ZProgressHUDMaskType = .None
    private var defaultPorgressType: ZProgressHUDProgressType = .General
    private var defaultStatusType: ZProgressHUDStatusType = .Indicator
    private var defaultPositionType: ZProgressHUDPositionType = .Center
    
    private var centerOffset: UIOffset = UIOffsetZero
    
    private var font = UIFont.systemFontOfSize(16.0) {
        didSet {
            self.statusLabel.font = self.font
            self.placeSubviews()
        }
    }
    
    private var status: String?
    
    private var pureLabelCornerRadius: CGFloat  = 8.0 {
        didSet {
            self.hudView.layer.cornerRadius = self.pureLabelCornerRadius
        }
    }
    
    private var cornerRadius: CGFloat = 14.0 {
        didSet {
            self.hudView.layer.cornerRadius = self.cornerRadius
        }
    }
    
    // MARK: - Widget
    private lazy var overlayView: UIControl = {
        let overlayView = UIControl(frame: self.frame)
        overlayView.backgroundColor = UIColor.clearColor()
        overlayView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        overlayView.addTarget(self,
                              action: #selector(ZProgressHUD.overlayViewDidReceiveTouchEvent(_:event:)),
                              forControlEvents: .TouchDown)

        return overlayView
    }()
    
    private lazy var statusLabel: UILabel = {
        var statusLabel = UILabel(frame: CGRectZero)
        statusLabel.backgroundColor = UIColor.clearColor()
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.textAlignment = .Center
        statusLabel.font = self.font
        statusLabel.baselineAdjustment = .AlignCenters
        statusLabel.numberOfLines = 0
        return statusLabel
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRectMake(0, 0, 28.0, 28.0))
        imageView.userInteractionEnabled = false
        return imageView
    }()
    
    private lazy var hudView: UIView = {
        var hudView = UIView(frame: CGRectMake(0, 0, self.minmumSize.width, self.minmumSize.height))
        hudView.layer.masksToBounds = true
        hudView.autoresizingMask = [.FlexibleBottomMargin,
                                          .FlexibleTopMargin,
                                          .FlexibleRightMargin,
                                          .FlexibleLeftMargin ]
        return hudView
    }()
    
    private lazy var colouredLayer: CALayer = {
        let colouredLayer = CALayer()
        colouredLayer.frame = self.bounds
        let backgroundColor = self.defaultMaskType == .Custom ?
            self.bgLayerColor?.CGColor : UIColor(white: 0.0, alpha: 0.4).CGColor
        colouredLayer.backgroundColor = backgroundColor
        colouredLayer.setNeedsDisplay()
        return colouredLayer
    }()
    
    private lazy var gradientLayer: CALayer = {
        let gradientLayer = ZGradientLayer()
        gradientLayer.frame = self.bounds
        var gradientCenter = self.center
        gradientCenter.y = (self.bounds.size.height) / 2
        gradientLayer.gradientCenter = gradientCenter
        gradientLayer.setNeedsDisplay()
        return gradientLayer
    }()
    
    private var backgroundLayer: CALayer? = nil
    
    private lazy var animationIndicator: ZAnimationIndicatorView = {
        let animationIndicator = ZAnimationIndicatorView(frame: CGRectMake(0, 0, 37, 37))
        animationIndicator.lineWidth = self.lineWidth
        animationIndicator.strokeColor = self.foregroundColor() ?? UIColor.whiteColor()
        return animationIndicator
    }()
    
    private lazy var activityIndicator: ZActivityIndicatorView = {
        let activityIndicator = ZActivityIndicatorView(frame: CGRectMake(0, 0, 37, 37))
        activityIndicator.lineWidth = self.lineWidth
        activityIndicator.strokeColor = self.foregroundColor() ?? UIColor.whiteColor()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.autoAnimating = true
        return activityIndicator
    }()
    
    private lazy var nativeIndicator: UIActivityIndicatorView = {
        let nativeIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        nativeIndicator.tintColor = self.foregroundColor() ?? UIColor.whiteColor()
        nativeIndicator.hidesWhenStopped = true
        nativeIndicator.startAnimating()
        return nativeIndicator
    }()
    
    private var indicatorView: UIView?
    
    // MARK: - Singleton && initialization
    internal class func shareInstance() -> ZProgressHUD {
        struct Static {
            static var hud: ZProgressHUD! = nil
            static var onceToken: dispatch_once_t = 0
        }
        dispatch_once(&Static.onceToken) { 
            Static.hud = ZProgressHUD(frame: UIScreen.mainScreen().bounds)
        }
        return Static.hud
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                         name:UIApplicationDidChangeStatusBarOrientationNotification,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                         name: UIKeyboardWillHideNotification,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                         name: UIKeyboardWillShowNotification,
                                                         object: nil)
        self.userInteractionEnabled = false
        
        self.errorImage = UIImage.resourceNamed("error.png")
        self.successImage = UIImage.resourceNamed("success")
        self.infoImage = UIImage.resourceNamed("info")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(UIDeviceOrientationDidChangeNotification)
    }
    
    // MARK: - Events
    // recieve notification and position the subviews
    internal func positionHUD(notification: NSNotification?) {
        var visibleKeyboardHeight = self.visibleKeyboardHeight;
        if notification?.name == UIKeyboardWillHideNotification {
            visibleKeyboardHeight = 0.0
        }
        
        UIView.beginAnimations("com.zevwings.animation.positionhud", context: nil)
        UIView.setAnimationDuration(0.25)
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseInOut)
        self.frame = UIScreen.mainScreen().bounds
        self.backgroundLayer?.frame = self.frame
        self.overlayView.frame = self.frame
        self.hudView.center = CGPointMake(CGRectGetWidth(self.frame)/2.0 + self.centerOffset.horizontal, CGRectGetHeight(self.frame)/2.0 + self.centerOffset.vertical - visibleKeyboardHeight/2.0)
        UIView.commitAnimations()
    }
    
    // overlay touch event
    internal func overlayViewDidReceiveTouchEvent(sender: AnyObject?, event: UIEvent) {
        NSNotificationCenter.defaultCenter().postNotificationName(ZProgressHUDDidRecieveTouchEvent,
                                                                  object: self,
                                                                  userInfo: nil)
    }
}

// MARK: - Basic Views
extension ZProgressHUD {
    // set the views' properties
    private func prepare() {
        
        if !self.isVisible() {
            self.alpha = 0
            self.overlayView.alpha = 0
        }
        
        if self.defaultMaskType != .None {
            self.overlayView.userInteractionEnabled = true
            self.accessibilityLabel = status
            self.isAccessibilityElement = true
            
        } else {
            self.overlayView.userInteractionEnabled = false
            self.hudView.accessibilityLabel = status
            self.hudView.isAccessibilityElement = true
        }
        
        self.hudView.layer.cornerRadius = self.defaultStatusType == .PureStatus ?
            self.pureLabelCornerRadius :
            self.cornerRadius
        self.hudView.backgroundColor = self.backgroundColor()
        
        self.statusLabel.textColor = self.foregroundColor()
        self.statusLabel.text = self.status
        
        switch self.defaultStatusType {
        case .Success, .Error, .Info :
            self.imageView.image = self.statusImage?.tintColor(self.foregroundColor())
            break
        case .Custom:
            self.imageView.image = self.statusImage
            break
        case .Indicator:
            switch self.defaultPorgressType {
            case .Native:
                self.indicatorView = self.nativeIndicator
                (self.indicatorView as? UIActivityIndicatorView)?.tintColor = self.foregroundColor()
                break
            case .Animated:
                self.indicatorView = self.animationIndicator
                (self.indicatorView as? ZAnimationIndicatorView)?.strokeColor = self.foregroundColor()
                break
            default:
                self.indicatorView = self.activityIndicator
                (self.indicatorView as? ZActivityIndicatorView)?.strokeColor = self.foregroundColor()
                break
            }
            break
        default: break
        }
        
        // set up the background layer
        if self.backgroundLayer != nil {
            self.backgroundLayer?.removeFromSuperlayer()
            self.backgroundLayer = nil
        }
        
        switch self.defaultMaskType {
        case .Black, .Custom:
            self.backgroundLayer = self.colouredLayer
            break
        case .Gradient:
            self.backgroundLayer = self.gradientLayer
            break
        default: break
        }
        
        if self.backgroundLayer != nil {
            self.layer.insertSublayer(self.backgroundLayer!, atIndex: 0)
        }
    }
    
    //  add the subviews
    private func addSubviews() {
        self.removeSubviews()
        self.prepare()
        
        if self.overlayView.superview == nil {
            for window in UIApplication.sharedApplication().windows.reverse() {
                let windowOnMainScreen = window.screen == UIScreen.mainScreen()
                let windowIsVisible = !window.hidden && window.alpha > 0
                let windowLevelNormal = window.windowLevel == UIWindowLevelNormal
                
                if windowOnMainScreen && windowIsVisible && windowLevelNormal {
                    window.addSubview(self.overlayView)
                    break
                }
            }
        } else {
            self.overlayView.superview?.bringSubviewToFront(self.overlayView)
        }
        
        if self.superview == nil {
            self.overlayView.addSubview(self)
        }
        
        if self.hudView.superview == nil {
            self.addSubview(self.hudView)
        }
        
        if self.status != nil && !self.status!.isEmpty && self.statusLabel.superview == nil {
            self.hudView.addSubview(self.statusLabel)
        }
        
        switch self.defaultStatusType {
        case .Success, .Error, .Info, .Custom:
            if self.imageView.superview == nil && self.statusImage != nil {
                self.hudView.addSubview(self.imageView)
            }
            break
        case .Indicator:
            if self.indicatorView?.superview == nil {
                self.hudView.addSubview(self.indicatorView!)
            }
            break
        default: break
        }
        
        self.placeSubviews()
    }
    
    // set the view's frame
    private func placeSubviews() {
        var rect = CGRectZero
        let minSize = self.defaultStatusType == .PureStatus ? self.pureLabelminmumSize : self.minmumSize
        var labelSize = CGSizeZero
        let margin: CGFloat = 14.0

        // calculate the stautus frame.size
        if let status = self.status {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = NSLineBreakMode.ByCharWrapping
            let attributes = [NSFontAttributeName: self.font, NSParagraphStyleAttributeName: style]
            let option: NSStringDrawingOptions = [.UsesLineFragmentOrigin,
                                                  .UsesFontLeading,
                                                  .TruncatesLastVisibleLine]
            labelSize = (status as NSString).boundingRectWithSize(self.maxmumLabelSize, options: option,attributes: attributes, context: nil).size
            let sizeWidth = labelSize.width + margin * 2
            
            // the max indicator view size is 30 * 30
            // the max image view size is 28 * 28
            var sizeHeight: CGFloat = 0.0
            if self.defaultStatusType == .PureStatus {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + 12.0
            } else if self.defaultStatusType == .Indicator {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + margin * 2.75 + 37.0
            } else {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + margin * 2.75 + 28.0
            }
            rect.size.width = max(minSize.width, sizeWidth)
            rect.size.height = max(minSize.height, sizeHeight)
        } else {
            rect = CGRectMake(0, 0, minSize.width, minSize.height)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.hudView.bounds = rect
        
        if self.defaultPositionType == .Center {
            self.hudView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0 + self.centerOffset.horizontal, CGRectGetHeight(self.frame) / 2.0 + self.centerOffset.vertical - self.visibleKeyboardHeight / 2.0)
        } else {
            // tabbar view's height is 49.0
            self.hudView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0 + self.centerOffset.horizontal, CGRectGetHeight(self.frame) - CGRectGetHeight(self.hudView.frame) - 49.0 - margin + self.centerOffset.vertical - self.visibleKeyboardHeight / 2.0)
        }
        
        let labelOriginY = self.defaultStatusType == .PureStatus ?
            rect.height / 2.0 - labelSize.height / 2.0 :
            rect.height - margin - labelSize.height
        
        self.statusLabel.frame = CGRectMake(rect.width / 2.0 - labelSize.width / 2.0,
                                            labelOriginY,
                                            labelSize.width, labelSize.height)
        var centerY: CGFloat = 0.0
        if self.status == nil || self.status!.isEmpty {
            centerY = rect.height / 2.0
        } else if labelSize.height > self.minmumLabelHeight {
            centerY = (rect.height - margin * 2.75 - labelSize.height) / 2.0 + margin
        } else {
            centerY = (rect.height - margin * 2.0 - labelSize.height) / 2.0 + margin
        }
        let center = CGPointMake(rect.width / 2.0, centerY)
        self.indicatorView?.center = center
        self.imageView.center = center
        
        CATransaction.commit()
    }
    
    private func removeSubviews() {
        
        self.imageView.removeFromSuperview()
        self.statusLabel.removeFromSuperview()
        self.indicatorView?.removeFromSuperview()
        self.hudView.removeFromSuperview()
        self.removeFromSuperview()
        self.overlayView.removeFromSuperview()
    }
}

// MARK: - internal show methods
internal extension ZProgressHUD {

    private func show(status: String? = nil) {
        self.setHUDStatus(status, false)
        self.defaultStatusType = .Indicator
        dispatch_async(dispatch_get_main_queue()) {
            self.addSubviews()
            UIView.animateWithDuration(self.fadeInAnimationDuration, animations: {
                self.alpha = 1.0
                self.overlayView.alpha = 1.0
            })
        }
    }
    
    private func showStatus(image: UIImage? = nil, status: String? = nil, statusType: ZProgressHUDStatusType = .Custom) {
        self.setHUDStatus(status, false)
        self.defaultStatusType = statusType
        self.customImage = image
        dispatch_async(dispatch_get_main_queue()) {
            self.addSubviews()
            UIView.animateWithDuration(self.fadeInAnimationDuration, animations: {
                self.alpha = 1.0
                self.overlayView.alpha = 1.0
                }, completion: { (flag) in
                    self.setFadeOutTimter(self.minimumDismissDuration)
            })
        }
    }
    
    private func dismiss(delay: NSTimeInterval = 0.0) {
        if delay > 0 {
            self.setFadeOutTimter(delay)
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(self.fadeOutAnimationDuration, animations: {
                self.alpha = 0.0
                self.overlayView.alpha = 0.0
                }, completion: { (flag) in
                    self.fadeOutTimer?.invalidate()
                    self.fadeOutTimer = nil
                    self.removeSubviews()
            })
        }
    }

    private func isVisible() -> Bool {
        return self.alpha > 0
    }

    private func setFadeOutTimter (timeInterval: NSTimeInterval) {
        if self.fadeOutTimer != nil {
            self.fadeOutTimer?.invalidate()
            self.fadeOutTimer = nil
        }
        
        self.fadeOutTimer = NSTimer(timeInterval: timeInterval,
                                    target: self,
                                    selector: #selector(self.fadeOut(_:)),
                                    userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.fadeOutTimer!, forMode:NSRunLoopCommonModes)
    }
    
    func fadeOut(timer: NSTimer) {
        self.dismiss()
    }
}

// MARK:- private utils
private extension ZProgressHUD {
    
    private func backgroundColor() -> UIColor {
        var backgroundColor: UIColor = UIColor.blackColor()
        switch self.defaultStyle {
        case .Ligtht:
            backgroundColor = UIColor(white: 1.0, alpha: 1.0)
            break
        case .Dark:
            backgroundColor = UIColor(white: 0.0, alpha: 0.8)
            break
        case .Custom:
            backgroundColor = self.bgColor ?? UIColor.blackColor()
            break
        }
        return backgroundColor
    }
    
    private func foregroundColor() -> UIColor {
        var foregroundColor: UIColor = UIColor.whiteColor()
        switch self.defaultStyle {
        case .Ligtht:
            foregroundColor = UIColor.blackColor()
            break
        case .Dark:
            foregroundColor = UIColor.whiteColor()
            break
        case .Custom:
            foregroundColor = self.fgColor ?? UIColor.whiteColor()
            break
        }
        return foregroundColor
    }
    
    var statusImage: UIImage? {
        var statusImage: UIImage? = nil
        switch self.defaultStatusType {
        case .Success:
            statusImage = self.successImage
            break
        case .Error:
            statusImage = self.errorImage
            break
        case .Info:
            statusImage = self.infoImage
            break
        case .Custom:
            statusImage = self.customImage
            break
        default:
            break
        }
        return statusImage
    }
    
    func setHUDStatus(status: String?, _ placeSubviews: Bool) {
        self.status = status
        if placeSubviews {
            self.placeSubviews()
        }
    }
    
    var visibleKeyboardHeight: CGFloat {
        var keyboardWindow: UIWindow? = nil
        
        if let targetClass = NSClassFromString("UITextEffectsWindow") {
            for window in UIApplication.sharedApplication().windows {
                
                if window.isKindOfClass(targetClass) {
                    keyboardWindow = window
                    break
                }
            }
        }
        
        var inputSetHostView: UIView? = nil
        if let window = keyboardWindow {
            for possibleKeyboard in window.subviews {
                if possibleKeyboard.isKindOfClass(NSClassFromString("UIInputSetHostView")!) {
                    inputSetHostView = possibleKeyboard
                }
            }
        }
        
        if let inputSetHostView = inputSetHostView {
            for possibleKeyboard in inputSetHostView.subviews {
                if possibleKeyboard.isKindOfClass(NSClassFromString("UIInputSetHostView")!) {
                    return CGRectGetHeight(possibleKeyboard.frame)
                }
            }
        }
        
        return 0
    }
}

// MARK:- public Setters
public extension ZProgressHUD {

    public class func setLineWidth(width: CGFloat) {
        self.shareInstance().lineWidth = width
    }
    
    public class func setMinmumSize(size: CGSize) {
        self.shareInstance().minmumSize = size
    }
    
    public class func setCornerRadius(radius: CGFloat) {
        self.shareInstance().cornerRadius = radius
    }
    
    public class func setFont(font: UIFont) {
        self.shareInstance().font = font
    }
    
    public class func setErrorImage(image: UIImage?) {
        self.shareInstance().errorImage = image
    }
    
    public class func setSuccessImage(image: UIImage?) {
        self.shareInstance().successImage = image
    }
    
    public class func setInfoImage(image: UIImage?) {
        self.shareInstance().infoImage = image
    }
    
    public class func setForegroundColor(color: UIColor?) {
        self.shareInstance().fgColor = color
    }
    
    public class func setBackgroundColor(color: UIColor?) {
        self.shareInstance().bgColor = color
    }
    
    public class func setBackgroundLayerColor(color: UIColor?) {
        self.shareInstance().bgLayerColor = color
    }
    
    public class func setStatus(status: String?) {
        self.shareInstance().setHUDStatus(status, true)
    }
    
    public class func setCenterOffset(offset: UIOffset) {
        self.shareInstance().centerOffset = offset
    }
    
    public class func resetCenterOffset() {
        self.shareInstance().centerOffset = UIOffsetZero
    }
    
    public class func setDefaultStyle(style: ZProgressHUDStyle) {
        self.shareInstance().defaultStyle = style
    }
    
    public class func setDefaultProgressType(progressType: ZProgressHUDProgressType) {
        self.shareInstance().defaultPorgressType = progressType
    }
    
    public class func setDefaultMaskType(maskType: ZProgressHUDMaskType) {
        self.shareInstance().defaultMaskType = maskType
    }
    
    public class func setDefaultPositionType(positionType: ZProgressHUDPositionType) {
        self.shareInstance().defaultPositionType = positionType
    }
    
    public class func setMinimumDismissDuration(duration: NSTimeInterval) {
        self.shareInstance().minimumDismissDuration = duration
    }
    
    public class func setFadeInAnimationDuration(duration: NSTimeInterval) {
        self.shareInstance().fadeInAnimationDuration = duration
    }
    
    public class func setFadeOutAnimationDuration(duration: NSTimeInterval) {
        self.shareInstance().fadeOutAnimationDuration = duration
    }
}

// MARK: - public show methods
public extension ZProgressHUD {
    
    public class func show(status: String? = nil) {
        self.shareInstance().show(status)
    }
    
    public class func showImage(image: UIImage? = nil, status: String? = nil) {
        self.shareInstance().showStatus(image, status: status, statusType: .Custom)
    }
    
    public class func showError(status: String? = nil) {
        self.shareInstance().showStatus(nil, status: status, statusType: .Error)
    }
    
    public class func showInfo(status: String? = nil) {
        self.shareInstance().showStatus(nil, status: status, statusType: .Info)
    }
    
    public class func showSuccess(status: String? = nil) {
        self.shareInstance().showStatus(nil, status: status, statusType: .Success)
    }
    
    public class func showStatus(status: String) {
        self.shareInstance().showStatus(status: status, statusType: .PureStatus)
    }
    
    public class func dismiss(delay: NSTimeInterval = 0.0) {
        self.shareInstance().dismiss(delay)
    }
    
    public class func isVisible() -> Bool {
        return self.shareInstance().isVisible()
    }
}

// MARK: - internal UIImage Utils
internal extension UIImage {
    
    /**
     apply colours to a image
     
     - parameter color: a color
     
     - returns: UIImage
     */
    func tintColor(color: UIColor?) -> UIImage! {
        if color == nil {
            return self
        }
        let rect = CGRectMake(0.0, 0.0, self.size.width, self.size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        self.drawInRect(rect)
        CGContextSetFillColorWithColor(context, color!.CGColor)
        CGContextSetBlendMode(context, CGBlendMode.SourceAtop)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /**
     get the image from this framework
     
     - parameter frameworknamed: image name
     
     - returns: UIImage
     */
    class func resourceNamed(frameworknamed: String) -> UIImage? {
        let manualSoure = "ZProgressHUD.bundle".stringByAppendingFormat("%@", frameworknamed)
        let frameworkSoure = NSBundle(forClass: ZProgressHUD.classForCoder()).bundlePath.stringByAppendingFormat("/ZProgressHUD.bundle/%@", frameworknamed)
        let image = UIImage(named: manualSoure) == nil ? UIImage(named: frameworkSoure) : UIImage(named: manualSoure)
        return image
    }
}