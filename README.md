# [WWQOI](https://qoiformat.org/qoi-specification.pdf)

[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-16.0](https://img.shields.io/badge/iOS-16.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWQOI) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction - 簡介](https://swiftpackageindex.com/William-Weng)
- [A pure Swift QOI encoder / decoder package without BinaryParsing.](https://qoiformat.org/)
- [一個使用純Swift寫的QOI壓縮 / 解縮壓工具包 (沒有使用BinaryParsing)。](https://blog.gslin.org/archives/2021/11/27/10433/qoi-圖片無損壓縮演算法/)

### [View](https://freepngimg.com/png/114573-mario-photos-download-free-image)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)
```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWQOI.git", .upToNextMajor(from: "1.0.0"))
]
```

### 可用函式 (Function)
|函式|功能|
|-|-|
|encode(image:)|壓縮 (.qoi)|
|decode(data:)|解壓縮 (ImageData)|

### [Example](https://imagetostl.com/tw/view-qoi-online)
```swift
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
```

