//
//  ZProgressHUD.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/3/20.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

public class ZProgressHUD: UIView {
    
    private var ringThickness: CGFloat = 2.0
    private var ringRadius: CGFloat = 18.0
    private var ringNoTextRadius: CGFloat = 24.0
    
    private var fadeOutTimer: NSTimer?
    
    private var minmumSize = CGSizeMake(100, 100)
    private var pureLabelminmumSize = CGSizeMake(100, 28.0)
    private let maxmumLabelSize = CGSizeMake(160, 260)
    private let minmumLabelHeight: CGFloat = 20.0
    private var font = UIFont.systemFontOfSize(14.0)
    private var cornerRadius: CGFloat = 14.0

    private var errorImage: UIImage?
    private var successImage: UIImage?
    private var infoImage: UIImage?
    private var customImage: UIImage?
    
    private var fgColor: UIColor?
    private var bgColor: UIColor?
    private var bgLayerColor: UIColor?
    
    private var defaultStyle: ZProgressHUDStyle = .Dark
    private var defaultMaskType: ZProgressHUDMaskType = .Clear
    private var defaultPorgressType: ZProgressHUDProgressType = .General
    private var defaultStatusType: ZProgressHUDStatusType = .Error
    private var minimumDismissDuration: NSTimeInterval = 3.0
    private var fadeInAnimationDuration: NSTimeInterval = 0.25
    private var fadeOutAnimationDuration: NSTimeInterval = 0.25
    
    private var status: String? = "保存成功"{
        didSet {
            self.statusLabel?.text = self.status
            self.placeSubviews()
        }
    }
    
    private var centerOffset: UIOffset = UIOffsetZero {
        didSet {
            if let center = self.hudView?.center {
                let c = CGPointMake(center.x + self.centerOffset.horizontal,
                                    center.y + self.centerOffset.vertical)
                self.hudView?.center = c
            }
        }
    }
    
    // MARK: - Page Controls
    private var overlayView: UIControl?
    private var statusLabel: UILabel?
    private var imageView: UIImageView?
    private var hudView: UIView?
    private var progressView: ZProgressAnimatedView?
    private var indefinteView:ZIndefiniteAnimatedView?
    private var bgLayer: CALayer?
    
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
                                                         selector: #selector(ZProgressHUD.rotate(_:)),
                                                         name: UIDeviceOrientationDidChangeNotification,
                                                         object: nil)
        
        self.prepare()
        
        self.errorImage = Config.imageFor("error.png")
        self.successImage = Config.imageFor("success")
        self.infoImage = Config.imageFor("info")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(UIDeviceOrientationDidChangeNotification)
    }
    
    // MARK: -
    private func prepare() {
        
        /**
         *  set the overlayer view
         */
        if self.overlayView == nil {
            self.overlayView = UIControl(frame: self.frame)
            self.overlayView?.backgroundColor = UIColor.clearColor()
            self.overlayView?.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.overlayView?.addTarget(self,
                                       action: #selector(ZProgressHUD.overlayViewDidReceiveTouchEvent(_:event:)),
                                       forControlEvents: .TouchDown)
            self.overlayView?.backgroundColor = UIColor.clearColor()
        }
        
        /**
         *  set the base hud view
         */
        if self.hudView == nil {
            self.hudView = UIView(frame: CGRectMake(0, 0, minmumSize.width, minmumSize.height))
            self.hudView?.layer.masksToBounds = true
            self.hudView?.autoresizingMask = [.FlexibleBottomMargin,
                                              .FlexibleTopMargin,
                                              .FlexibleRightMargin,
                                              .FlexibleLeftMargin ]
            self.hudView?.layer.cornerRadius = self.cornerRadius
            self.hudView?.backgroundColor = self.backgroundColor()
        }
        
        /**
         *  set the status label
         *  if status exist
         */
        if self.status != nil && !self.status!.isEmpty && self.statusLabel == nil {
            self.statusLabel = UILabel(frame: CGRectZero)
            self.statusLabel?.backgroundColor = UIColor.clearColor()
            self.statusLabel?.adjustsFontSizeToFitWidth = true
            self.statusLabel?.textAlignment = .Center
            self.statusLabel?.font = self.font
            self.statusLabel?.baselineAdjustment = .AlignCenters
            self.statusLabel?.numberOfLines = 0
        }
        
        if self.statusLabel != nil {
            self.statusLabel?.textColor = self.foregroundColor()
            self.statusLabel?.text = self.status
        }
        
        /**
         *  set the status view
         */
        switch self.defaultStatusType {
        case .Success, .Error, .Info:
            if self.imageView != nil { break }
            self.imageView = UIImageView(frame: CGRectMake(0, 0, 28.0, 28.0))
            break
        case .Custom:
            if self.customImage == nil || self.imageView != nil { break }
            self.imageView = UIImageView(frame: CGRectMake(0, 0, 28.0, 28.0))
            break
        case .Indefinite:
            if self.indefinteView != nil { break }
            self.indefinteView = ZIndefiniteAnimatedView(frame: CGRectZero)
            self.indefinteView?.strokeColor = self.foregroundColor()
            break
        case .Progress:
            if self.progressView != nil { break }
            self.progressView = ZProgressAnimatedView(frame: CGRectZero)
            break
        }
    
        if self.imageView != nil {
            self.imageView?.image = self.statusImage()?.tintColor(self.foregroundColor())
        }
        
        /**
         *  set the background mask
         */
        if self.bgLayer != nil {
            self.bgLayer?.removeFromSuperlayer()
            self.bgLayer = nil
        }
        
        switch self.defaultMaskType {
        case .Black, .Custom:
            
                self.bgLayer = CALayer()
                self.bgLayer?.frame = self.bounds
                let bgColor = self.defaultMaskType == .Custom ?
                    self.bgLayerColor?.CGColor : UIColor(white: 0.0, alpha: 0.4).CGColor
                self.bgLayer?.backgroundColor = bgColor
                self.bgLayer?.setNeedsDisplay()
                self.layer.insertSublayer(self.bgLayer!, atIndex: 0)
            break
        case .Gradient:
            let layer = ZGradientLayer()
            layer.frame = self.bounds
            
            var gradientCenter = self.center
            gradientCenter.y = (self.bounds.size.height) / 2
            layer.gradientCenter = gradientCenter;
            
            self.bgLayer = layer
            self.bgLayer?.setNeedsDisplay()
            self.layer.insertSublayer(self.bgLayer!, atIndex: 0)
            break
        default: break
            
        }

        self.addSubviews()
        self.placeSubviews()
    }
    
    /**
     *  add the subviews
     */
    private func addSubviews() {
        if self.overlayView?.superview == nil {
            dispatch_async(dispatch_get_main_queue()) {
                for window in UIApplication.sharedApplication().windows.reverse() {
                    let windowOnMainScreen = window.screen == UIScreen.mainScreen()
                    let windowIsVisible = !window.hidden && window.alpha > 0;
                    let windowLevelNormal = window.windowLevel == UIWindowLevelNormal;
                    
                    if windowOnMainScreen && windowIsVisible && windowLevelNormal {
                        window.addSubview(self.overlayView!)
                        break
                    }
                }
            }
        } else {
            self.overlayView?.superview?.bringSubviewToFront(self.overlayView!)
        }
        
        if self.superview == nil {
            self.overlayView?.addSubview(self)
        }
        
        if self.hudView?.superview == nil {
            self.addSubview(self.hudView!)
        }
        
        if self.status != nil && !self.status!.isEmpty && self.statusLabel?.superview == nil {
            self.hudView?.addSubview(self.statusLabel!)
        }
        
        switch self.defaultStatusType {
        case .Success, .Error, .Info, .Custom:
            if self.imageView?.superview == nil && self.statusImage() != nil {
                self.hudView?.addSubview(self.imageView!)
            }
            break
        case .Indefinite:
            if self.indefinteView?.superview == nil {
                self.hudView?.addSubview(self.indefinteView!)
            }
            break
        case .Progress:
            if self.progressView?.superview == nil {
                self.hudView?.addSubview(self.progressView!)
            }
            break
        }
    }
    
    /*
     set the view's frame
     */
    private func placeSubviews() {
        var rect = CGRectZero
        var minSize = self.minmumSize
        var labelSize = CGSizeZero
        let margin: CGFloat = 14.0
        
        var pureLabel:  Bool = false
        if self.imageView?.superview == nil &&
            self.indefinteView?.superview == nil &&
            self.progressView?.superview == nil {
            pureLabel = true
            minSize = self.pureLabelminmumSize
        }
        
        // 计算文本大小
        if let status = self.status {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = NSLineBreakMode.ByCharWrapping
            let attributes = [NSFontAttributeName: self.font,
                              NSParagraphStyleAttributeName: style.copy()]
            let option: NSStringDrawingOptions = [.UsesLineFragmentOrigin,
                                                  .UsesFontLeading,
                                                  .TruncatesLastVisibleLine]
            labelSize = (status as NSString).boundingRectWithSize(self.maxmumLabelSize,
                                                                 options: option,
                                                                 attributes: attributes,
                                                                 context: nil).size
            let sizeWidth = labelSize.width + margin * 2
            // 图片最大高度为28.0
            let sizeHeight = max(self.minmumLabelHeight, labelSize.height) + margin * 2.75 + 28.0
            print(sizeHeight)
            rect.size.width = max(minSize.width, sizeWidth)
            rect.size.height = max(minSize.height, sizeHeight)
        } else {
            rect = CGRectMake(0, 0, minSize.width, minSize.height)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.hudView?.bounds = rect
        self.hudView?.center = self.center
        
        let labelOriginY = pureLabel ?
            rect.height / 2.0 - labelSize.height / 2.0 :
            rect.height - margin - labelSize.height
        
        self.statusLabel?.frame = CGRectMake(rect.width / 2.0 - labelSize.width / 2.0,
                                             labelOriginY,
                                             labelSize.width, labelSize.height)
        // 计算状态视图位置
        var centerY: CGFloat = 0.0
        if self.status == nil || self.status!.isEmpty {
            centerY = rect.height / 2.0
        } else if labelSize.height > self.minmumLabelHeight {
            centerY = (rect.height - margin * 2.75 - labelSize.height) / 2.0 + margin
        } else {
            centerY = (rect.height - margin * 2.0 - labelSize.height) / 2.0 + margin
        }
        let center = CGPointMake(rect.width / 2.0, centerY)
        self.indefinteView?.center = center
        self.imageView?.center = center
        self.progressView?.center = center
        
        CATransaction.commit()
    }
    
    private func removeSubviews() {
        
        self.imageView?.removeFromSuperview()
        self.statusLabel?.removeFromSuperview()
        self.progressView?.removeFromSuperview()
        self.indefinteView?.removeFromSuperview()
        self.hudView?.removeFromSuperview()
        self.removeFromSuperview()
        self.overlayView?.removeFromSuperview()
    }
    
    internal func overlayViewDidReceiveTouchEvent(sender: AnyObject?, event: UIEvent) {
    
    }
    
    private func isVisible() -> Bool {
        return self.alpha > 0
    }
    
    func rotate(sender: NSNotification?) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.frame = UIScreen.mainScreen().bounds
        self.overlayView?.frame = self.frame
        self.hudView?.center = self.center
        
        CATransaction.commit()
    }
}

// MAKR:- Utils
private extension ZProgressHUD {
    
    private func backgroundColor() -> UIColor? {
        var backgroundColor: UIColor?
        switch self.defaultStyle {
        case .Ligtht:
            backgroundColor = UIColor(white: 0.0, alpha: 0.8)
            break
        case .Dark:
            backgroundColor = UIColor.blackColor()
            break
        case .Custom:
            backgroundColor = self.bgColor
            break
        }
        return backgroundColor
    }
    
    private func foregroundColor() -> UIColor? {
        var foregroundColor: UIColor?
        switch self.defaultStyle {
        case .Ligtht:
            foregroundColor = UIColor.blackColor()
            break
        case .Dark:
            foregroundColor = UIColor.whiteColor()
            break
        case .Custom:
            foregroundColor = self.fgColor
            break
        }
        return foregroundColor
    }
    
    func statusImage() -> UIImage? {
        var statusImage: UIImage?
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
}

// MARK:- Setters
public extension ZProgressHUD {
    
    public class func setRingThickness(ringThickness: CGFloat) {
        
    }
    
    public class func setRingRadius(radius: CGFloat) {
        
    }
    
    public class func setRingNoTextRadius(radius: CGFloat) {
        
    }

    public class func setMinmumSize(size: CGSize) {
        self.shareInstance().minmumSize = size
    }
    
    public class func setCornerRadius(radius: CGFloat) {
        
    }
    
    public class func setFont(font: UIFont?) {
        
    }
    
    public class func setErrorImage(image: UIImage?) {
        
    }
    
    public class func setSuccessImage(image: UIImage?) {
        
    }
    
    public class func setInfoImage(image: UIImage?) {
        
    }
    
    public class func setForegroundColor(color: UIColor?) {
        
    }
    
    public class func setBackgroundColor(color: UIColor?) {
        
    }
    
    public class func setBackgroundLayerColor(color: UIColor?) {
        
    }
    
    public class func setStatus(status: String?) {
        
    }
    
    public class func setCenterOffset(offset: UIOffset) {
        
    }
    
    public class func setDefaultStyle(style: ZProgressHUDStyle) {
        
    }
    
    public class func setDefaultMaskType(maskType: ZProgressHUDMaskType) {
        
    }
    
    public class func setDefaultPorgressType(porgressType: ZProgressHUDProgressType) {
        
    }
    
    public class func setMinimumDismissDuration(duration: NSTimeInterval) {
        
    }
    
    public class func setFadeInAnimationDuration(duration: NSTimeInterval) {
        
    }
    
    public class func setFadeOutAnimationDuration(duration: NSTimeInterval) {
        
    }
}

// MARK: - show methods
public extension ZProgressHUD {
    
    public class func show() {
        self.shareInstance()
  
    }
    
    public class func show(status: String?) {
        
    }
    
    public class func showImage(image: UIImage?, status: String? = nil) {
        
    }
    
    public class func showProgress(progress: Double, status: String? = nil) {
        
    }
    
    public class func showError(status: String) {
        
    }
    
    public class func showInfo(status: String) {
        
    }
    
    public class func showSuccess(status: String) {
        
    }
    
    public class func dismiss(delay: NSTimeInterval = 0.0) {
        
    }
    
    public class func isVisible() -> Bool {
        return false
    }
    
    public class func resetCenterOffset() {
        
    }
}


// MARK: - UIImage Tint Color
internal extension UIImage {
    /**
     为图片指定颜色
     
     - parameter color: 图片颜色
     
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
}