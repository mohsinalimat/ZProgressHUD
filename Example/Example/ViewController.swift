//
//  ViewController.swift
//  Example
//
//  Created by ZhangZZZZ on 16/4/11.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit
import ZProgressHUD

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.progresshudRecieveTouch(_:)), name: ZProgressHUDDidRecieveTouchEvent, object: nil)
    }
    
    func progresshudRecieveTouch(notification: NSNotification) {
        ZProgressHUD.dismiss()
//        print(notification.object)
//        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func show(sender: AnyObject) {
        ZProgressHUD.setDefaultMaskType(.None)
        ZProgressHUD.setDefaultProgressType(.General)
        ZProgressHUD.show()
    }

    @IBAction func showStatus(sender: AnyObject) {
        ZProgressHUD.setDefaultMaskType(.Gradient)
        ZProgressHUD.setDefaultProgressType(.Animated)
        ZProgressHUD.show("正在加载")
    }
    @IBAction func showError(sender: AnyObject) {
//         ZProgressHUD.setDefaultMaskType(.Black)
        ZProgressHUD.showError("保存失败")
    }
    @IBAction func showSuccess(sender: AnyObject) {
//        ZProgressHUD.setDefaultMaskType(.Clear)
//        ZProgressHUD.setDefaultStyle(.Dark)
        ZProgressHUD.showSuccess("保存成功")
    }
    @IBAction func showInfo(sender: AnyObject) {
//        ZProgressHUD.setDefaultStyle(.Ligtht)
//        ZProgressHUD.setDefaultMaskType(.Gradient)
//        ZProgressHUD.setDefaultPositionType(.Center)
//        ZProgressHUD.setDefaultProgressType(<#T##progressType: ZProgressHUDProgressType##ZProgressHUDProgressType#>)
        ZProgressHUD.showInfo("错误的名称")
    }
    @IBAction func showImage(sender: AnyObject) {
        ZProgressHUD.setDefaultPositionType(.Bottom)
        ZProgressHUD.showStatus("测试")
//        ZProgressHUD.showImage(status: "Test")
//        ZProgressHUD.showImage(nil, status: "Test")
//        ZProgressHUD.showImage(UIImage(named: "show"))
    }
}

