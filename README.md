# ZProgressHUD
ZProgressHUD is a simple HUD for swift.

# Installation
## CocoaPods
<CocoaPods.org> is a dependency manager for Cocoa Projects.
``` bash 
use_frameworks!

pod 'ZProgressHUD', '~> 0.0.4’
```
then
``` bash 
run pod install 
```

## Manual

``` bash 
1. Download this project, And drag ZProgressHUD.xcodeproj to your own project.
2. In your target’s General tab, click the ’+’ button under Linked Frameworks and Libraries.
3. Select the ZProgressHUD.framework to Add to your platform. 
```

# Usage 

#### provide class function to use.

``` bash
public class func show(status: String? = nil)
public class func showError(status: String? = nil)
public class func showInfo(status: String? = nil)
public class func showSuccess(status: String? = nil)
public class func showStatus(status: String) 
public class func showImage(image: UIImage? = nil, status: String? = nil)
public class func dismiss(delay: NSTimeInterval = 0.0)
public class func isVisible() -> Bool
```
#### provide  class function to set HUD
``` bash
public class func setLineWidth(width: CGFloat)
public class func setMinmumSize(size: CGSize)
public class func setCornerRadius(radius: CGFloat)
public class func setFont(font: UIFont)
public class func setErrorImage(image: UIImage?)
public class func setSuccessImage(image: UIImage?)
public class func setInfoImage(image: UIImage?)
public class func setForegroundColor(color: UIColor?)
public class func setBackgroundColor(color: UIColor?)
public class func setBackgroundLayerColor(color: UIColor?)
public class func setStatus(status: String?)
public class func setCenterOffset(offset: UIOffset)
public class func resetCenterOffset()
public class func setDefaultStyle(style: ZProgressHUDStyle)
public class func setDefaultProgressType(progressType: ZProgressHUDProgressType)
public class func setDefaultMaskType(maskType: ZProgressHUDMaskType)
public class func setDefaultPositionType(positionType: ZProgressHUDPositionType)
public class func setMinimumDismissDuration(duration: NSTimeInterval)
public class func setFadeInAnimationDuration(duration: NSTimeInterval)
public class func setFadeOutAnimationDuration(duration: NSTimeInterval)
```
