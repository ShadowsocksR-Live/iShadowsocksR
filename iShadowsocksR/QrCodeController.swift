//
//  QrCodeController.swift
//  iShadowsocksR
//
//  Created by ssrlive on 2020/5/20.
//  Copyright © 2020 ssrLive. All rights reserved.
//

import UIKit

class QrCodeController: UIViewController {
    
    public var qrCodeInfo: String?
    
    private var qrText: UILabel?
    private var qrImage: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Long Press to share".localized()
        
        qrText = UILabel()
        qrText?.isUserInteractionEnabled = true
        qrText?.numberOfLines = 0
        qrText?.text = qrCodeInfo
        self.view.addSubview(qrText!)
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressHandler(_:)))
        qrText?.addGestureRecognizer(tap)

        qrImage = UIImageView()
        qrImage?.isUserInteractionEnabled = true
        qrImage?.image = self.genQRCode(from: qrCodeInfo!)
        self.view.addSubview(qrImage!)
        let tap2 = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressHandler2(_:)))
        qrImage?.addGestureRecognizer(tap2)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = self.view.frame.size
        var width = (size.width-10*2)
        qrText?.frame = CGRect(x: 10, y: 10, width: width, height: 200)
        
        width = (size.width-40*2)
        let width2 = size.height - (10 + 200)
        width = min(width, width2)
        qrImage?.frame = CGRect(x: 40, y: 10 + 200, width: width, height: width)
    }
    
    func genQRCode(from input: String) -> UIImage? {
        let data = input.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    @objc func longPressHandler(_ sender: UITapGestureRecognizer? = nil) {
        UIPasteboard.general.string = qrCodeInfo
        let a = UIAlertController(title: "QR Code URI".localized(), message: "Copied to Pasteboard".localized(), preferredStyle: .alert)
        let b = UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil)
        a.addAction(b)
        self.navigationController?.present(a, animated: true, completion: nil)
    }
    
    @objc func longPressHandler2(_ sender: UITapGestureRecognizer? = nil) {
        guard var selectedImage = qrImage!.image else {
            return
        }
        selectedImage = selectedImage.copyOriginalImage()
        
        guard let txt = qrCodeInfo else {
            return
        }
        
        let avc = UIActivityViewController(activityItems: [selectedImage, txt, ], applicationActivities: nil)
        if UIDevice.current.model == "iPad" {
            avc.popoverPresentationController?.sourceView = qrImage
        }
        self.navigationController?.present(avc, animated: true, completion: nil)
    }
}

extension UIImage {
    // https://cloud.tencent.com/developer/ask/124238/answer/223895

    /**
     Creates the UIImageJPEGRepresentation out of an UIImage
     @return Data
     */
    func generatePNGRepresentation() -> Data? {
        let newImage = self.copyOriginalImage()
        let newData = UIImagePNGRepresentation(newImage)
        return newData!
    }

    /**
     Copies Original Image which fixes the crash for extracting Data from UIImage
     @return UIImage
     */
    func copyOriginalImage() -> UIImage {
        UIGraphicsBeginImageContext(self.size);
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return newImage!
    }
}
