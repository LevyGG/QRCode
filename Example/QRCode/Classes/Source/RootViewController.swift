//
//  RootViewController.swift
//  QRCode
//
//  Created by gaofu on 16/9/9.
//  Copyright © 2016年 gaofu. All rights reserved.
//

import UIKit

class RootViewController: UIViewController{

    private let segueID = "RecognizeQRCodeViewController"
    private var sourceImage : UIImage?
    

    
    override func viewDidLoad(){
        
        super.viewDidLoad()
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
        guard segue.identifier == segueID else { return }
        guard let destinationViewController =  segue.destination as? RecognizeQRCodeViewController else { return }
        destinationViewController.sourceImage = sourceImage;
        
    }
    

    
    @IBAction private  func recognizeQRCodeClick(){
        
        Tool.shareTool.choosePicture(self, editor: true) { [weak self] (image) in
            self!.sourceImage = image
            self!.performSegue(withIdentifier: self!.segueID, sender: self)
        }
        
    }

    
    
}




