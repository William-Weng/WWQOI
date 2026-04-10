//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/10/29.
//

import UIKit
import WWQOI

final class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rawLabel: UILabel!
    @IBOutlet weak var pngLabel: UILabel!
    @IBOutlet weak var qoiImage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        demo()
    }
    
    func demo() {
        
        do {
            let qoiURL = URL.documentsDirectory.appendingPathComponent("test.qoi")
            let pngURL = Bundle.main.url(forResource: "test.png", withExtension: nil)
            let pngData = try Data(contentsOf: pngURL!)
            let pngImage = UIImage(data: pngData)!
            let qoiData = try WWQOI.shared.encode(image: pngImage.cgImage!)
            
            try qoiData.write(to: qoiURL)
            print("QOI: \(qoiURL.path)")
            
            let info = try WWQOI.shared.decode(data: qoiData)
            let cgImge = try info.cgImage()
            
            imageView.image = UIImage(cgImage: cgImge)
            
            rawLabel.text = "[raw] \(info.pixels.count) bytes (100%)"
            pngLabel.text = "[png] \(pngData.count) bytes (\(pngData.count * 100 / info.pixels.count)%)"
            qoiImage.text = "[qoi] \(qoiData.count) bytes (\(qoiData.count * 100 / info.pixels.count)%)"
            
        } catch {
            print(error)
        }
    }
}

