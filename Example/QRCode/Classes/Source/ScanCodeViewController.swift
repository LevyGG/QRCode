//
//  ScanCodeViewController.swift
//  QRCode
//
//  Created by gaofu on 16/9/9.
//  Copyright © 2016年 gaofu. All rights reserved.
//

import UIKit
import AVFoundation

private let scanAnimationDuration = 3.0//扫描时长

class ScanCodeViewController: UIViewController
{
    
    //MARK: -
    //MARK: Global Variables
    
    @IBOutlet weak var scanPane: UIImageView!///扫描框
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var lightOn = false///开光灯
    
    
    //MARK: -
    //MARK: Lazy Components
    
    lazy var scanLine : UIImageView =
        {
            
            let scanLine = UIImageView()
            scanLine.frame = CGRect(x: 0, y: 0, width: self.scanPane.bounds.width, height: 3)
            scanLine.image = UIImage(named: "QRCode_ScanLine")
            
            return scanLine
            
    }()
    
    var scanSession :  AVCaptureSession?
    
    
    //MARK: -
    //MARK: Public Methods
    
    
    //MARK: -
    //MARK: Data Initialize
    
    
    //MARK: -
    //MARK: Life Cycle
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        
        view.layoutIfNeeded()
        scanPane.addSubview(scanLine)
        
        setupScanSession()
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        startScan()
        
    }
    
    
    //MARK: -
    //MARK: Interface Components
    
    func setupScanSession()
    {
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do
        {
            let input = try AVCaptureDeviceInput(device: device)
            
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            let  scanSession = AVCaptureSession()
            scanSession.canSetSessionPreset(AVCaptureSessionPresetHigh)
            
            if scanSession.canAddInput(input)
            {
                scanSession.addInput(input)
            }
            
            if scanSession.canAddOutput(output)
            {
                scanSession.addOutput(output)
            }
            
            output.metadataObjectTypes = [
            AVMetadataObjectTypeQRCode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeCode93Code]
            
            let scanPreviewLayer = AVCaptureVideoPreviewLayer(session:scanSession)
            scanPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            scanPreviewLayer?.frame = view.layer.bounds
            
            view.layer.insertSublayer(scanPreviewLayer!, at: 0)
            
            if (device?.isFocusModeSupported(.autoFocus))!
            {
                do { try input.device.lockForConfiguration() } catch{ }
                input.device.focusMode = .autoFocus
                input.device.unlockForConfiguration()
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: {[weak self] (noti) in
                    output.rectOfInterest = (scanPreviewLayer?.metadataOutputRectOfInterest(for: self!.scanPane.frame))!
            })
            
            self.scanSession = scanSession
            
        }
        catch
        {
            //摄像头不可用
            
            Tool.confirm(title: "温馨提示", message: "摄像头不可用", controller: self)
            
            return
        }

    }
    
    //MARK: -
    //MARK: Target Action
    
    @IBAction func light(_ sender: UIButton)
    {
        
        lightOn = !lightOn
        sender.isSelected = lightOn
        turnTorchOn()
        
    }
    
    @IBAction func photo()
    {
        
        Tool.shareTool.choosePicture(self, editor: true, options: .photoLibrary) {[weak self] (image) in

            self!.activityIndicatorView.startAnimating()
            
            DispatchQueue.global().async {
                let recognizeResult = image.recognizeQRCode()
                let result = recognizeResult?.characters.count > 0 ? recognizeResult : "无法识别"
                DispatchQueue.main.async {
                    self!.activityIndicatorView.stopAnimating()
                    Tool.confirm(title: "扫描结果", message: result, controller: self!)
                }
            }
        }
        
    }
    
    //MARK: -
    //MARK: Data Request
    
    
    //MARK: -
    //MARK: Private Methods
    
    fileprivate func startScan()
    {
    
        scanLine.layer.add(scanAnimation(), forKey: "scan")
        
        guard let scanSession = scanSession else { return }
        
        if !scanSession.isRunning
        {
            scanSession.startRunning()
        }
        
        
    }
    
    private func scanAnimation() -> CABasicAnimation
    {
    
        let startPoint = CGPoint(x: scanLine .center.x  , y: 1)
        let endPoint = CGPoint(x: scanLine.center.x, y: scanPane.bounds.size.height - 2)
        
        let translation = CABasicAnimation(keyPath: "position")
        translation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translation.fromValue = NSValue(cgPoint: startPoint)
        translation.toValue = NSValue(cgPoint: endPoint)
        translation.duration = scanAnimationDuration
        translation.repeatCount = MAXFLOAT
        translation.autoreverses = true
        
        return translation
    }
    
    
    ///闪光灯
    private func turnTorchOn()
    {
        
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else
        {
            
            if lightOn
            {
                
                Tool.confirm(title: "温馨提示", message: "闪光灯不可用", controller: self)

            }
            
            return
        }
        
        if device.hasTorch
        {
            do
            {
                try device.lockForConfiguration()
                
                if lightOn && device.torchMode == .off
                {
                    device.torchMode = .on
                }
                
                if !lightOn && device.torchMode == .on
                {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            }
            catch{ }
        
        }
        
    }
    
    //MARK: -
    //MARK: Dealloc
    
    deinit
    {
        
        ///移除通知
        NotificationCenter.default.removeObserver(self)
        
    }
    
}


//MARK: -
//MARK: AVCaptureMetadataOutputObjects Delegate

extension ScanCodeViewController : AVCaptureMetadataOutputObjectsDelegate
{
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
    {
        
        self.scanLine.layer.removeAllAnimations()
        self.scanSession!.stopRunning()
        
        Tool.playAlertSound(sound: "noticeMusic.caf")
        
        //扫完完成
        if metadataObjects.count > 0
        {
            
            if let resultObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject
            {
                
                Tool.confirm(title: "扫描结果", message: resultObj.stringValue, controller: self,handler: { (_) in
                    self.startScan()
                })
                
            }
            
        }
        
    }
    
}

