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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func show(sender: AnyObject) {
        ZProgressHUD.show()
    }

    @IBAction func showStatus(sender: AnyObject) {
        ZProgressHUD.setDefaultMaskType(.Gradient)
        ZProgressHUD.show("正在加载")
    }
    @IBAction func showError(sender: AnyObject) {
         ZProgressHUD.setDefaultMaskType(.Black)
        ZProgressHUD.showError("保存失败")
    }
    @IBAction func showSuccess(sender: AnyObject) {
        ZProgressHUD.setDefaultMaskType(.Clear)
        ZProgressHUD.setDefaultStyle(.Dark)
        ZProgressHUD.showSuccess("保存成功")
    }
    @IBAction func showInfo(sender: AnyObject) {
        ZProgressHUD.setDefaultStyle(.Ligtht)
        ZProgressHUD.setDefaultMaskType(.Gradient)
        ZProgressHUD.showInfo("错误的名称")
    }
    @IBAction func showImage(sender: AnyObject) {
        ZProgressHUD.showImage(UIImage(named: "show"))
    }
    
    @IBAction func showProgress(sender: AnyObject) {
        ZProgressHUD.showProgress(0.75)
    }
    
    @IBAction func showProgressWithStatus(sender: AnyObject) {
        ZProgressHUD.showProgress(0.75, status: "正在加载")
    }
    
}

