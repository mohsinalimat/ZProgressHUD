//
//  ZProgressHUD.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/3/20.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

public enum ZProgressHUDStyle {
    case ligtht
    case dark
    case custom
}

public enum ZProgressHUDMaskType {
    case none
    case clear
    case black
    case gradient
    case custom
}

public enum ZProgressHUDPositionType {
    case bottom
    case center
}

public enum ZProgressHUDProgressType {
    case general
    case animated
    case native
}

public enum ZProgressHUDStatusType {
    
    case error
    case success
    case info
    case custom
    
    case pureStatus
    
    case indicator
    case progress // development
}

public extension NSNotification.Name {
    
    public static let ZProgressHUDDidRecieveTouchEvent = NSNotification.Name(rawValue: "com.zevwings.events.touchevent")
}

public class ZProgressHUD: UIView {
    
    private var lineWidth: CGFloat = 2.0
    private var fadeOutTimer: Timer?
    
    private var minmumSize = CGSize(width: 100, height: 100)
    private var pureLabelminmumSize = CGSize(width: 100, height: 28.0)
    private let maxmumLabelSize = CGSize(width: UIScreen.main().bounds.width / 2.0, height: 260)
    private let minmumLabelHeight: CGFloat = 20.0
    private var minimumDismissDuration: TimeInterval = 3.0
    private var fadeInAnimationDuration: TimeInterval = 0.15
    private var fadeOutAnimationDuration: TimeInterval = 0.25

    private var errorImage: UIImage?
    private var successImage: UIImage?
    private var infoImage: UIImage?
    private var customImage: UIImage?
    
    private var fgColor: UIColor?
    private var bgColor: UIColor?
    private var bgLayerColor: UIColor?

    private var defaultStyle: ZProgressHUDStyle = .dark
    private var defaultMaskType: ZProgressHUDMaskType = .none
    private var defaultPorgressType: ZProgressHUDProgressType = .general
    private var defaultStatusType: ZProgressHUDStatusType = .indicator
    private var defaultPositionType: ZProgressHUDPositionType = .center
    
    private var centerOffset: UIOffset = UIOffsetZero
    
    private var font = UIFont.systemFont(ofSize: 16.0) {
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
        overlayView.backgroundColor = UIColor.clear()
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.addTarget(self,
                              action: #selector(ZProgressHUD.overlayViewDidReceiveTouchEvent(_:event:)),
                              for: .touchDown)

        return overlayView
    }()
    
    private lazy var statusLabel: UILabel = {
        var statusLabel = UILabel(frame: CGRect.zero)
        statusLabel.backgroundColor = UIColor.clear()
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.textAlignment = .center
        statusLabel.font = self.font
        statusLabel.baselineAdjustment = .alignCenters
        statusLabel.numberOfLines = 0
        return statusLabel
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28.0, height: 28.0))
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var hudView: UIView = {
        var hudView = UIView(frame: CGRect(x: 0, y: 0, width: self.minmumSize.width, height: self.minmumSize.height))
        hudView.layer.masksToBounds = true
        hudView.autoresizingMask = [.flexibleBottomMargin,
                                    .flexibleTopMargin,
                                    .flexibleRightMargin,
                                    .flexibleLeftMargin ]
        return hudView
    }()
    
    private lazy var colouredLayer: CALayer = {
        let colouredLayer = CALayer()
        colouredLayer.frame = self.bounds
        let backgroundColor = self.defaultMaskType == .custom ?
            self.bgLayerColor?.cgColor : UIColor(white: 0.0, alpha: 0.4).cgColor
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
        let animationIndicator = ZAnimationIndicatorView(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
        animationIndicator.lineWidth = self.lineWidth
        animationIndicator.strokeColor = self.foregroundColor() ?? UIColor.white()
        return animationIndicator
    }()
    
    private lazy var activityIndicator: ZActivityIndicatorView = {
        let activityIndicator = ZActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
        activityIndicator.lineWidth = self.lineWidth
        activityIndicator.strokeColor = self.foregroundColor() ?? UIColor.white()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.autoAnimating = true
        return activityIndicator
    }()
    
    private lazy var nativeIndicator: UIActivityIndicatorView = {
        let nativeIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        nativeIndicator.tintColor = self.foregroundColor() ?? UIColor.white()
        nativeIndicator.hidesWhenStopped = true
        nativeIndicator.startAnimating()
        return nativeIndicator
    }()
    
    private var indicatorView: UIView?
    
    // MARK: - Singleton && initialization
    
    public static let shared: ZProgressHUD = {
        return ZProgressHUD()
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default().addObserver(self,
                                                 selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                 name:NSNotification.Name.UIApplicationDidChangeStatusBarOrientation,
                                                 object: nil)
        
            NotificationCenter.default().addObserver(self,
                                                         selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                         name: NSNotification.Name.UIKeyboardWillHide,
                                                         object: nil)
        
        NotificationCenter.default().addObserver(self,
                                                 selector: #selector(ZProgressHUD.positionHUD(_:)),
                                                 name: NSNotification.Name.UIKeyboardWillShow,
                                                 object: nil)
        self.isUserInteractionEnabled = false
        
        self.errorImage = UIImage.resource(named: "error.png")
        self.successImage = UIImage.resource(named: "success")
        self.infoImage = UIImage.resource(named: "info")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(NSNotification.Name.UIDeviceOrientationDidChange)
    }
    
    // MARK: - Events
    // recieve notification and position the subviews
    internal func positionHUD(_ notification: NSNotification?) {
        var visibleKeyboardHeight = self.visibleKeyboardHeight;
        if notification?.name == NSNotification.Name.UIKeyboardWillHide {
            visibleKeyboardHeight = 0.0
        }
        
        UIView.beginAnimations("com.zevwings.animation.positionhud", context: nil)
        UIView.setAnimationDuration(0.25)
        UIView.setAnimationCurve(UIViewAnimationCurve.easeInOut)
        self.frame = UIScreen.main().bounds
        self.backgroundLayer?.frame = self.frame
        self.overlayView.frame = self.frame
        self.hudView.center = CGPoint(x: self.frame.width/2.0 + self.centerOffset.horizontal,
                                      y: self.frame.height/2.0 + self.centerOffset.vertical - visibleKeyboardHeight/2.0)
        UIView.commitAnimations()
    }
    
    // overlay touch event
    internal func overlayViewDidReceiveTouchEvent(_ sender: AnyObject?, event: UIEvent) {
        NotificationCenter.default().post(name: NSNotification.Name.ZProgressHUDDidRecieveTouchEvent,
                                          object: self)
    }
}

// MARK: - Basic Views
extension ZProgressHUD {
    // set the views' properties
    private func prepare() {
        
        print(self)
        
        if !self.isVisible() {
            self.alpha = 0
            self.overlayView.alpha = 0
        }
        
        if self.defaultMaskType != .none {
            self.overlayView.isUserInteractionEnabled = true
            self.accessibilityLabel = status
            self.isAccessibilityElement = true
            
        } else {
            self.overlayView.isUserInteractionEnabled = false
            self.hudView.accessibilityLabel = status
            self.hudView.isAccessibilityElement = true
        }
        
        self.hudView.layer.cornerRadius = self.defaultStatusType == .pureStatus ?
            self.pureLabelCornerRadius :
            self.cornerRadius
        self.hudView.backgroundColor = self.backgroundColor()
        
        self.statusLabel.textColor = self.foregroundColor()
        self.statusLabel.text = self.status
        
        switch self.defaultStatusType {
        case .success, .error, .info :
            self.imageView.image = self.statusImage?.tintColor(self.foregroundColor())
            break
        case .custom:
            self.imageView.image = self.statusImage
            break
        case .indicator:
            switch self.defaultPorgressType {
            case .native:
                self.indicatorView = self.nativeIndicator
                (self.indicatorView as? UIActivityIndicatorView)?.tintColor = self.foregroundColor()
                break
            case .animated:
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
        case .black, .custom:
            self.backgroundLayer = self.colouredLayer
            break
        case .gradient:
            self.backgroundLayer = self.gradientLayer
            break
        default: break
        }
        
        if self.backgroundLayer != nil {
            self.layer.insertSublayer(self.backgroundLayer!, at: 0)
        }
    }
    
    //  add the subviews
    private func addSubviews() {
        self.removeSubviews()
        self.prepare()
        
        if self.overlayView.superview == nil {
            for window in UIApplication.shared().windows.reversed() {
                let windowOnMainScreen = window.screen == UIScreen.main()
                let windowIsVisible = !window.isHidden && window.alpha > 0
                let windowLevelNormal = window.windowLevel == UIWindowLevelNormal
                
                if windowOnMainScreen && windowIsVisible && windowLevelNormal {
                    window.addSubview(self.overlayView)
                    break
                }
            }
        } else {
            self.overlayView.superview?.bringSubview(toFront: self.overlayView)
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
        case .success, .error, .info, .custom:
            if self.imageView.superview == nil && self.statusImage != nil {
                self.hudView.addSubview(self.imageView)
            }
            break
        case .indicator:
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
        var rect = CGRect.zero
        let minSize = self.defaultStatusType == .pureStatus ? self.pureLabelminmumSize : self.minmumSize
        var labelSize = CGSize.zero
        let margin: CGFloat = 14.0

        // calculate the stautus frame.size
        if let status = self.status {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = NSLineBreakMode.byCharWrapping
            let attributes = [NSFontAttributeName: self.font, NSParagraphStyleAttributeName: style]
            let option: NSStringDrawingOptions = [.usesLineFragmentOrigin,
                                                  .usesFontLeading,
                                                  .truncatesLastVisibleLine]
            labelSize = (status as NSString).boundingRect(with: self.maxmumLabelSize, options: option,attributes: attributes, context: nil).size
            let sizeWidth = labelSize.width + margin * 2
            
            // the max indicator view size is 30 * 30
            // the max image view size is 28 * 28
            var sizeHeight: CGFloat = 0.0
            if self.defaultStatusType == .pureStatus {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + 12.0
            } else if self.defaultStatusType == .indicator {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + margin * 2.75 + 37.0
            } else {
                sizeHeight = max(self.minmumLabelHeight, labelSize.height) + margin * 2.75 + 28.0
            }
            rect.size.width = max(minSize.width, sizeWidth)
            rect.size.height = max(minSize.height, sizeHeight)
        } else {
            rect = CGRect(x: 0, y: 0, width: minSize.width, height: minSize.height)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.hudView.bounds = rect
        
        if self.defaultPositionType == .center {
            self.hudView.center = CGPoint(x: self.frame.width / 2.0 + self.centerOffset.horizontal,
                                          y: self.frame.height / 2.0 + self.centerOffset.vertical - self.visibleKeyboardHeight / 2.0)
        } else {
            // tabbar view's height is 49.0
            self.hudView.center = CGPoint(x: self.frame.width / 2.0 + self.centerOffset.horizontal,
                                          y: self.frame.height - self.hudView.frame.height - 49.0 - margin + self.centerOffset.vertical - self.visibleKeyboardHeight / 2.0)
        }
        
        let labelOriginY = self.defaultStatusType == .pureStatus ?
            rect.height / 2.0 - labelSize.height / 2.0 :
            rect.height - margin - labelSize.height
        
        self.statusLabel.frame = CGRect(x: rect.width / 2.0 - labelSize.width / 2.0,
                                        y:labelOriginY,
                                        width:labelSize.width,
                                        height: labelSize.height)
        var centerY: CGFloat = 0.0
        if self.status == nil || self.status!.isEmpty {
            centerY = rect.height / 2.0
        } else if labelSize.height > self.minmumLabelHeight {
            centerY = (rect.height - margin * 2.75 - labelSize.height) / 2.0 + margin
        } else {
            centerY = (rect.height - margin * 2.0 - labelSize.height) / 2.0 + margin
        }
        let center = CGPoint(x: rect.width / 2.0, y: centerY)
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

    private func show(_ status: String? = nil) {
        self.setHUD(with: status, false)
        self.defaultStatusType = .indicator
        DispatchQueue.main.async {
            self.addSubviews()
            UIView.animate(withDuration: self.fadeInAnimationDuration, animations: {
                self.alpha = 1.0
                self.overlayView.alpha = 1.0
            })
        }
    }
    
    private func showStatus(_ image: UIImage? = nil, status: String? = nil, statusType:
        ZProgressHUDStatusType = .custom) {

        self.setHUD(with: status, false)
        self.defaultStatusType = statusType
        self.customImage = image
        DispatchQueue.main.async {
            self.addSubviews()
            UIView.animate(withDuration: self.fadeInAnimationDuration, animations: {
                self.alpha = 1.0
                self.overlayView.alpha = 1.0
                }, completion: { (flag) in
                    self.setFadeOutTimter(self.minimumDismissDuration)
            })
        }
    }
    
    private func dismiss(delay: TimeInterval = 0.0) {
        if delay > 0 {
            self.setFadeOutTimter(delay)
            return
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.fadeOutAnimationDuration, animations: {
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

    private func setFadeOutTimter(_ timeInterval: TimeInterval) {
        if self.fadeOutTimer != nil {
            self.fadeOutTimer?.invalidate()
            self.fadeOutTimer = nil
        }
        
        self.fadeOutTimer = Timer(timeInterval: timeInterval,
                                  target: self,
                                  selector: #selector(self.fadeOut(_:)),
                                  userInfo: nil, repeats: true)
        RunLoop.main().add(self.fadeOutTimer!, forMode:RunLoopMode.commonModes)
    }
    
    func fadeOut(_ timer: Timer) {
        self.dismiss()
    }
}

// MARK:- private utils
private extension ZProgressHUD {
    
    private func backgroundColor() -> UIColor {
        var backgroundColor: UIColor = UIColor.black()
        switch self.defaultStyle {
        case .ligtht:
            backgroundColor = UIColor(white: 1.0, alpha: 1.0)
            break
        case .dark:
            backgroundColor = UIColor(white: 0.0, alpha: 0.8)
            break
        case .custom:
            backgroundColor = self.bgColor ?? UIColor.black()
            break
        }
        return backgroundColor
    }
    
    private func foregroundColor() -> UIColor {
        var foregroundColor: UIColor = UIColor.white()
        switch self.defaultStyle {
        case .ligtht:
            foregroundColor = UIColor.black()
            break
        case .dark:
            foregroundColor = UIColor.white()
            break
        case .custom:
            foregroundColor = self.fgColor ?? UIColor.white()
            break
        }
        return foregroundColor
    }
    
    var statusImage: UIImage? {
        var statusImage: UIImage? = nil
        switch self.defaultStatusType {
        case .success:
            statusImage = self.successImage
            break
        case .error:
            statusImage = self.errorImage
            break
        case .info:
            statusImage = self.infoImage
            break
        case .custom:
            statusImage = self.customImage
            break
        default:
            break
        }
        return statusImage
    }
    
    func setHUD(with status: String?, _ placeSubviews: Bool) {
        self.status = status
        if placeSubviews {
            self.placeSubviews()
        }
    }
    
    var visibleKeyboardHeight: CGFloat {
        var keyboardWindow: UIWindow? = nil
        
        if let targetClass = NSClassFromString("UITextEffectsWindow") {
            for window in UIApplication.shared().windows {
                
                if window.isKind(of: targetClass) {
                    keyboardWindow = window
                    break
                }
            }
        }
        
        var inputSetHostView: UIView? = nil
        if let window = keyboardWindow {
            for possibleKeyboard in window.subviews {
                if possibleKeyboard.isKind(of: NSClassFromString("UIInputSetHostView")!) {
                    inputSetHostView = possibleKeyboard
                }
            }
        }
        
        if let inputSetHostView = inputSetHostView {
            for possibleKeyboard in inputSetHostView.subviews {
                if possibleKeyboard.isKind(of: NSClassFromString("UIInputSetHostView")!) {
                    return possibleKeyboard.frame.height
                }
            }
        }
        
        return 0
    }
}

// MARK:- public Setters
public extension ZProgressHUD {

    public class func setLineWidth(width: CGFloat) {
        self.shared.lineWidth = width
    }
    
    public class func setMinmumSize(size: CGSize) {
        self.shared.minmumSize = size
    }
    
    public class func setCornerRadius(radius: CGFloat) {
        self.shared.cornerRadius = radius
    }
    
    public class func setFont(font: UIFont) {
        self.shared.font = font
    }
    
    public class func setErrorImage(image: UIImage?) {
        self.shared.errorImage = image
    }
    
    public class func setSuccessImage(image: UIImage?) {
        self.shared.successImage = image
    }
    
    public class func setInfoImage(image: UIImage?) {
        self.shared.infoImage = image
    }
    
    public class func setForegroundColor(color: UIColor?) {
        self.shared.fgColor = color
    }
    
    public class func setBackgroundColor(color: UIColor?) {
        self.shared.bgColor = color
    }
    
    public class func setBackgroundLayerColor(color: UIColor?) {
        self.shared.bgLayerColor = color
    }
    
    public class func setStatus(status: String?) {
        self.shared.setHUD(with: status, true)
    }
    
    public class func setCenterOffset(offset: UIOffset) {
        self.shared.centerOffset = offset
    }
    
    public class func resetCenterOffset() {
        self.shared.centerOffset = UIOffsetZero
    }
    
    public class func setDefault(style: ZProgressHUDStyle) {
        self.shared.defaultStyle = style
    }
    
    public class func setDefault(progressType: ZProgressHUDProgressType) {
        self.shared.defaultPorgressType = progressType
    }
    
    public class func setDefault(maskType: ZProgressHUDMaskType) {
        self.shared.defaultMaskType = maskType
    }
    
    public class func setDefault(positionType: ZProgressHUDPositionType) {
        self.shared.defaultPositionType = positionType
    }
    
    public class func setMinimumDismissDuration(duration: TimeInterval) {
        self.shared.minimumDismissDuration = duration
    }
    
    public class func setFadeInAnimationDuration(duration: TimeInterval) {
        self.shared.fadeInAnimationDuration = duration
    }
    
    public class func setFadeOutAnimationDuration(duration: TimeInterval) {
        self.shared.fadeOutAnimationDuration = duration
    }
}

// MARK: - public show methods
public extension ZProgressHUD {
    
    public class func show(_ status: String? = nil) {
        self.shared.show(status)
    }
    
    public class func showImage(_ image: UIImage? = nil, status: String? = nil) {
        self.shared.showStatus(image, status: status, statusType: .custom)
    }
    
    public class func showError(_ status: String? = nil) {
        self.shared.showStatus(nil, status: status, statusType: .error)
    }
    
    public class func showInfo(_ status: String? = nil) {
        self.shared.showStatus(nil, status: status, statusType: .info)
    }
    
    public class func showSuccess(_ status: String? = nil) {
        self.shared.showStatus(nil, status: status, statusType: .success)
    }
    
    public class func showStatus(_ status: String) {
        self.shared.showStatus(status: status, statusType: .pureStatus)
    }
    
    public class func dismiss(_ delay: TimeInterval = 0.0) {
        self.shared.dismiss(delay: delay)
    }
    
    public class func isVisible() -> Bool {
        return self.shared.isVisible()
    }
    
    public class func test() {
        for _ in 1 ..< 10 {
            print(ZProgressHUD.shared)
        }
    }
}

// MARK: - internal UIImage Utils
internal extension UIImage {
    
    /**
     apply colours to a image
     
     - parameter color: a color
     
     - returns: UIImage
     */
    func tintColor(_ color: UIColor?) -> UIImage! {
        if color == nil { return self }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        
        if let context = UIGraphicsGetCurrentContext() {
            self.draw(in: rect)
            context.setFillColor(color!.cgColor)
            context.setBlendMode(CGBlendMode.sourceAtop)
            context.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        } else {
            return self
        }
    }
    
    /**
     get the image from this framework
     
     - parameter frameworknamed: image name
     
     - returns: UIImage
     */
    class func resource(named name: String) -> UIImage? {
        let manualPath = "ZProgressHUD.bundle".appendingFormat("%@", name)
        let frameworkPath = Bundle(for: ZProgressHUD.classForCoder()).bundlePath.appendingFormat("/ZProgressHUD.bundle/%@", name)
        let image = UIImage(named: manualPath) == nil ? UIImage(named: frameworkPath) : UIImage(named: manualPath)
        return image
    }
}
