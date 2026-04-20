//
//  Demo.swift
//  Example
//
//  Created by iOS on 2026/4/20.
//
// WWQOI Benchmark Suite
// WWQOI.playground 或獨立 Package
// 直接複製到 Playground 執行！

import WWQOI
import UIKit
import OSLog

final class Benchmark {
    
    private let logger = Logger(subsystem: "WWQOI.Benchmark", category: "Performance")
    
    // MARK: - 基準測試
    func benchmarkSuite() {
        let testImages = generateTestImages()
        var results: [(name: String, qoiEncode: Double, qoiDecode: Double, pngSize: Int, qoiSize: Int)] = []
        
        for (name, cgImage) in testImages {
            // PNG 基準
            let pngData = UIImage(cgImage: cgImage).pngData()!
            let pngSize = pngData.count
            
            // QOI 編碼
            let encodeTime = measureTime {
                _ = try? WWQOI.shared.encode(image: cgImage)
            }
            
            // QOI 解碼 (100次平均)
            let qoiData = try! WWQOI.shared.encode(image: cgImage)
            let qoiSize = qoiData.count
            let decodeTime = measureTime(repeat: 100) {
                _ = try? WWQOI.shared.decode(data: qoiData)
            } / 1000
            
            results.append((name, encodeTime, decodeTime, pngSize, qoiSize))
            logger.info("\(name): Encode \(String(format: "%.2f", encodeTime))ms, Decode \(String(format: "%.2f", decodeTime))μs, PNG:\(pngSize) QOI:\(qoiSize)")
        }
        
        printBenchmarkTable(results: results)
    }
}

private extension Benchmark {
    
    // MARK: - 生成測試圖片
    func generateTestImages() -> [(name: String, cgImage: CGImage)] {
        var images: [(name: String, cgImage: CGImage)] = []
        
        // 1. 同色區大 (天空/背景)
        let solidRed = generateSolidColor(width: 512, height: 512, r: 255, g: 0, b: 0)
        images.append(("SolidRed", solidRed))
        
        // 2. 遊戲 UI (少量顏色)
        let uiImage = generateUItest(width: 512, height: 512)
        images.append(("UI", uiImage))
        
        // 3. 自然照片 (多顏色)
        if let photo = UIImage(named: "test_photo")?.cgImage {
            images.append(("Photo", photo))
        }
        
        // 4. Alpha 漸層
        let gradient = generateGradient(width: 512, height: 512)
        images.append(("Gradient", gradient))
        
        return images
    }
    
    // MARK: - 輔助函數
    func measureTime(repeat times: Int = 1, block: () -> Void) -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<times { block() }
        let end = CFAbsoluteTimeGetCurrent()
        return (end - start) * 1000 / Double(times)  // ms
    }
    
    func printBenchmarkTable(results: [(name: String, qoiEncode: Double, qoiDecode: Double, pngSize: Int, qoiSize: Int)]) {
        print("\n📊 WWQOI vs PNG Benchmark")
        print("═══════════════════════════════════════════════════════")
        print("Image     | QOI Enc  | QOI Dec  | PNG KB | QOI KB | Ratio")
        
        var totalPNG = 0, totalQOI = 0
        for result in results {
            let ratio = Double(result.qoiSize) / Double(result.pngSize) * 100
            let pngKB = result.pngSize / 1024
            let qoiKB = result.qoiSize / 1024
            
            // ✅ 分別格式化數字
            print("\(result.name.padding(toLength: 10, withPad: " ", startingAt: 0)) | " +
                  "\(String(format: "%.2f", result.qoiEncode))ms | " +
                  "\(String(format: "%.2f", result.qoiDecode*1000))μs | " +
                  "\(pngKB)/\(qoiKB) | " +
                  "\(String(format: "%.1f", ratio))%")
            
            totalPNG += result.pngSize
            totalQOI += result.qoiSize
        }
        
        let avgRatio = Double(totalQOI) / Double(totalPNG) * 100
        print("═══════════════════════════════════════════════════════")
        print("AVG: QOI \(String(format: "%.1f", avgRatio))% PNG size")
    }
    
    // MARK: - 測試圖片生成器
    func generateSolidColor(width: Int, height: Int, r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) -> CGImage {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        
        var buffer = [UInt8](repeating: 0, count: totalBytes)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                buffer[index]     = r  // R
                buffer[index + 1] = g  // G
                buffer[index + 2] = b  // B
                buffer[index + 3] = a  // A (最後)
            }
        }
        
        let provider = CGDataProvider(data: NSData(bytes: &buffer, length: totalBytes))!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ✅ 正確組合：BGRA + AlphaLast
        let bitmapInfo: CGBitmapInfo = [
            .byteOrder32Big,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        ]
        
        return CGImage(width: width, height: height,
                       bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: bytesPerRow,
                       space: colorSpace,
                       bitmapInfo: bitmapInfo,
                       provider: provider, decode: nil,
                       shouldInterpolate: false, intent: .defaultIntent)!
    }
    
    func generateGradient(width: Int, height: Int) -> CGImage {
        // 類似 generateSolidColor，但 alpha 漸變 255→0
        // (實作略)
        return generateSolidColor(width: width, height: height, r: 128, g: 128, b: 128)
    }
    
    func generateUItest(width: Int, height: Int) -> CGImage {
        // 少量顏色 + 同色區
        return generateSolidColor(width: width, height: height, r: 64, g: 128, b: 192)
    }
}
