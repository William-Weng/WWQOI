//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/4/11.
//

import UIKit
import WWQOI

final class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rawLabel: UILabel!
    @IBOutlet weak var pngLabel: UILabel!
    @IBOutlet weak var qoiLabel: UILabel!
    
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
            let rawSize = Int64(info.pixels.count)._bytes(units: [.useMB])
            let pngSize = Int64(pngData.count)._bytes(units: [.useMB])
            let qoiSize = Int64(qoiData.count)._bytes(units: [.useMB])

            imageView.image = UIImage(cgImage: cgImge)
            
            rawLabel.text = "[raw] \(rawSize) (100%)"
            pngLabel.text = "[png] \(pngSize) (\(pngData.count * 100 / info.pixels.count)%)"
            qoiLabel.text = "[qoi] \(qoiSize) (\(qoiData.count * 100 / info.pixels.count)%)"
        } catch {
            print(error)
        }
    }
}
