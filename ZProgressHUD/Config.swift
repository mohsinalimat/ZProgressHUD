//
//  Config.swift
//  ZProgressHUD
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

struct Config {
    static func imageFor(name: String) -> UIImage? {
        
        let manualSoure = "ZProgressHUD.bundle".stringByAppendingFormat("%@", name)
        let frameworkSoure = NSBundle(forClass: ZProgressHUD.classForCoder()).bundlePath.stringByAppendingFormat("/ZProgressHUD.bundle/%@", name)
        
        let image = UIImage(named: manualSoure) == nil ? UIImage(named: frameworkSoure) : UIImage(named: manualSoure)
        return image
    }
}

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
    case Native
}

public enum ZProgressHUDStatusType: Int {
    case Error
    case Success
    case Info
    case Progress
    case Indefinite
    case Custom
}