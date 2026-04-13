# [WWQOI](https://qoiformat.org/qoi-specification.pdf)

[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-16.0](https://img.shields.io/badge/iOS-16.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWQOI) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction - 簡介](https://swiftpackageindex.com/William-Weng)
- [A pure Swift QOI (Quite OK Image) encoder / decoder package without BinaryParsing.](https://qoiformat.org/)
- [一個使用純Swift寫的QOI (Quite OK Image) 壓縮 / 解縮壓工具包 (沒有使用BinaryParsing)。](https://blog.gslin.org/archives/2021/11/27/10433/qoi-圖片無損壓縮演算法/)

![](https://github.com/user-attachments/assets/bc6f2305-55fb-41e0-bedd-782063a98b9c)

> [Johnathan Higdon (CC BY-NC 4.0) ](https://freepngimg.com/png/114573-mario-photos-download-free-image)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)
```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWQOI.git", .upToNextMajor(from: "1.0.0"))
]
```

### [可用函式 (Function)](https://peterpanswift.github.io/iphone-bezels/)
|函式|功能|
|-|-|
|encode(image:)|[壓縮 (.qoi)](https://qoiformat.org/qoi-specification.pdf)|
|decode(data:)|[解壓縮 (ImageData)](https://github.com/apple/swift-binary-parsing/tree/main/Examples)|

### [Example](https://imagetostl.com/tw/view-qoi-online)
```swift
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
```

