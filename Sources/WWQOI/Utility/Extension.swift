//
//  Extension.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import CoreGraphics

// MARK: - UInt8
extension UInt8 {
    
    /// 不會溢位的循環加法（wrap-around addition / &+）
    /// - Parameter delta: UInt8
    /// - Returns: UInt8
    func addWrap(_ delta: Int) -> UInt8 { return UInt8(truncatingIfNeeded: Int(self) + delta) }
}

// MARK: - UInt32
extension UInt32 {
    
    /// 寫入到資料中
    /// - Parameter output: Data
    func write(to output: inout Data) {
        output.append(UInt8((self >> 24) & 0xFF))
        output.append(UInt8((self >> 16) & 0xFF))
        output.append(UInt8((self >> 8) & 0xFF))
        output.append(UInt8(self & 0xFF))
    }
}

// MARK: - String
extension String {
    
    /// 字串轉成[UInt8] ("qoif" => [0x71, 0x6F, 0x69, 0x66])
    /// - Parameter str: String
    /// - Returns: [UInt8]
    func toUInt8() -> [UInt8] { return Array(utf8) }
}

// MARK: - Data
extension Data {
    
    /// 估算 QOI 編碼輸出所需的初始 buffer 容量 (rawSize + extra + constantOverhead)
    /// - Parameters:
    ///   - pixelCount: 像素總數 (width * height)
    ///   - bytesPerPixel: 每個像素的位元組數 (RGBA: 4 / RGB:  3)
    ///   - extraPerPixelDivisor: 額外預留空間的係數分母
    ///   - constantOverhead: 固定額外空間 (header: 32)
    /// - Returns:
    ///   適合拿來初始化 `Data(capacity:)` 的估算容量。
    static func estimateQOIBuffer(pixelCount: UInt32, bytesPerPixel: Int = 4, extraPerPixelDivisor: Int = 2, constantOverhead: Int = 32) -> Data {
        
        let rawSize = Int(pixelCount) * bytesPerPixel
        let extra = Int(pixelCount) / extraPerPixelDivisor
        let capacity = rawSize + extra + constantOverhead
        
        return Data(capacity: capacity)
    }
}

// MARK: - CGImage
extension CGImage {
    
    /// 將QOI壓縮檔 => CGImage
    /// - Parameters:
    ///   - qoiImage: WWQOI.QOIImage
    ///   - colorSpace: CGColorSpace
    /// - Returns: CGImage
    static func build(qoiImage: WWQOI.Image, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) throws -> CGImage {
        
        let bytesPerPixel = Int(qoiImage.header.channels)
        let bitsPerComponent = 8
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let bytesPerRow = Int(qoiImage.header.width) * bytesPerPixel
        
        var bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            .union(.byteOrder32Big)
        
        if (qoiImage.header.channels == 3) { bitmapInfo = CGBitmapInfo.byteOrder32Big.union(.alphaInfoMask) }
        
        guard let provider = CGDataProvider(data: qoiImage.pixels as CFData),
              let cgImage = CGImage(width: Int(qoiImage.header.width), height: Int(qoiImage.header.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else {
            throw WWQOI.DecodeError.invalidData
        }
        
        return cgImage
    }
}

// MARK: - CGImage
extension CGImage {
    
    /// CGImage => RGBA8Buffer
    /// - Returns: RGBA8Buffer
    func toRGBA() throws -> WWQOI.RGBA8Buffer {
        
        let bytesPerPixel = 4
        let totalBytes = height * (width * bytesPerPixel)
        
        var pixels = [UInt8](repeating: 0, count: totalBytes)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try CGContext.build(data: &pixels, bytesPerPixel: bytesPerPixel, width: width, height: height, bitmapInfo: bitmapInfo)
        context.interpolationQuality = .none
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return .init(width: width, height: height, pixels: pixels)
    }
}

// MARK: - CGContext
extension CGContext {
    
    /// 建立CGContext
    /// - Parameters:
    ///   - data: UnsafeMutableRawPointer?
    ///   - bytesPerPixel: Int
    ///   - width: Int
    ///   - height: Int
    ///   - bitsPerComponent: Int
    ///   - colorSpace: CGColorSpace
    ///   - bitmapInfo: UInt32
    /// - Returns: CGContext?
    static func build(data: UnsafeMutableRawPointer?, bytesPerPixel: Int, width: Int, height: Int, bitsPerComponent: Int = 8, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(), bitmapInfo: UInt32) throws -> CGContext {
        
        let bytesPerRow = width * bytesPerPixel
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        
        if let context { return context }
        throw WWQOI.ImageBufferError.contextCreationFailed
    }
}
