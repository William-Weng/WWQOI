//
//  Model.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import CoreGraphics

// MARK: - 模型
public extension WWQOI {
    
    /// QOI的壓縮結果 (.qoi)
    struct Image: Sendable {
        
        public let header: QOIHeader
        public let pixels: Data
        
        init(header: QOIHeader, pixels: Data) {
            self.header = header
            self.pixels = pixels
        }
    }
    
    /// QOI的標頭格式
    struct QOIHeader: Sendable {
        
        let magic: String
        let width: UInt32
        let height: UInt32
        let channels: UInt8
        let colorSpace: UInt8
        
        init(magic: String = "qoif", width: UInt32, height: UInt32, channels: UInt8, colorSpace: UInt8) {
            self.magic = magic
            self.width = width
            self.height = height
            self.channels = channels
            self.colorSpace = colorSpace
        }
    }
}

// MARK: - 公開函式 (QOIImage)
public extension WWQOI.Image {
    
    /// 還原成
    /// - Returns: CGImage
    func cgImage() throws -> CGImage {
        return try CGImage.build(qoiImage: self)
    }
}

// MARK: - 模型
extension WWQOI {
    
    /// 顏色像素 - RGBA
    struct Pixel: Sendable {
        
        static let start = Pixel(red: 0, green: 0, blue: 0, alpha: 255)
        static var new: Pixel { return .init(red: 0, green: 0, blue: 0, alpha: 0) }
        
        private let util: Utility = .init()
        
        var hashIndex: Int { return util.qoiHashIndex(red: red, green: green, blue: blue, alpha: alpha) }
        
        var red: UInt8
        var green: UInt8
        var blue: UInt8
        var alpha: UInt8
    }
    
    /// 8位元RGBA數值
    struct RGBA8Buffer {
        let width: Int
        let height: Int
        let pixels: [UInt8]
    }
}

// MARK: - Equatable + Pixel
extension WWQOI.Pixel: Equatable {
    
    /// Equatable實作
    /// - Parameters:
    ///   - lhs: WWQOI.Pixel
    ///   - rhs: WWQOI.Pixel
    /// - Returns: Bool
    static func == (lhs: WWQOI.Pixel, rhs: WWQOI.Pixel) -> Bool {
        if (lhs.red != rhs.red) { return false }
        if (lhs.green != rhs.green) { return false }
        if (lhs.blue != rhs.blue) { return false }
        if (lhs.alpha != rhs.alpha) { return false }
        return true
    }
}

// MARK: - Pixel
extension WWQOI.Pixel {
    
    /// 將像素值還原成Pixel
    /// - Parameters:
    ///   - input: [UInt8]
    ///   - offset: Int
    ///   - channelsType: WWQOI.Channels
    /// - Returns: WWQOI.Pixel
    static func recover(from input: [UInt8], offset: Int, channelsType: WWQOI.Channels) -> WWQOI.Pixel {
        
        let alpha = (channelsType == .rgba) ? input[offset + 3] : 255
        let pixel = WWQOI.Pixel(red: input[offset + 0], green: input[offset + 1], blue: input[offset + 2], alpha: channelsType == .rgba ? input[offset + 3] : 255)
        
        return pixel
    }
    
    /// 將Pixel區塊加到Data中
    /// - Parameter output: Data
    func appendChunk(to output: inout Data, hasAlpha: Bool) {
        (!hasAlpha) ? appendRGBChunk(to: &output) : appendRGBAChunk(to: &output)
    }
    
    /// 將Pixel區塊加到Data中
    /// - Parameter output: Data
    func appendRGBChunk(to output: inout Data) {
        output.append(WWQOI.OperationCode.rgb.rawValue)
        output.append(red)
        output.append(green)
        output.append(blue)
    }
    
    /// 將Pixel區塊加到Data中
    /// - Parameter output: Data
    func appendRGBAChunk(to output: inout Data) {
        output.append(WWQOI.OperationCode.rgba.rawValue)
        output.append(red)
        output.append(green)
        output.append(blue)
        output.append(alpha)
    }
    
    /// 解析壓縮的格式 (由取得的顏色與上一次顏色的差異，來決定最適合的壓縮方式)
    /// - Parameters:
    ///   - pixel: 這一次的像素值
    ///   - previous: 上一次的像素值
    /// - Returns: EncodeType
    func parseEncodeType(by previous: WWQOI.Pixel) -> WWQOI.EncodeType {
        
        let deltaRed = Int(red) - Int(previous.red)
        let deltaGreen = Int(green) - Int(previous.green)
        let deltaBlue = Int(blue) - Int(previous.blue)
        let deltaRed_deltaGreen = deltaRed - deltaGreen
        let deltaBlue_deltaGreen = deltaBlue - deltaGreen

        // 有 alpha 變化，只能用 generic (QOI_OP_RGBA)
        if alpha != previous.alpha {
            return .rgba
        }
        
        // 1. QOI_OP_DIFF: R/G/B 差在 [-2,1] 之間，1-byte chunk
        if (-2 <= deltaRed && deltaRed <= 1) && (-2 <= deltaGreen && deltaGreen <= 1) && (-2 <= deltaBlue && deltaBlue <= 1) {
            return .diff(deltaRed, deltaGreen, deltaBlue)
        }
        
        // 2. QOI_OP_LUMA: 2-byte chunk，用綠色當基準，RGB 變化較大
        if (-32 <= deltaGreen && deltaGreen <= 31) && (-8 <= deltaRed_deltaGreen && deltaRed_deltaGreen <= 7) && (-8 <= deltaBlue_deltaGreen && deltaBlue_deltaGreen <= 7) {
            return .luma(deltaGreen, deltaRed_deltaGreen, deltaBlue_deltaGreen)
        }
        
        // 3. 其他情況，用 index / run 等（定義為 .rgb）
        return .rgb
    }
}

// MARK: - QOIHeader
extension WWQOI.QOIHeader {
    
    /// 從原始資料解析出Header
    /// - Parameter data: Data
    /// - Returns: QOIHeader
    static func build(from data: Data) throws -> WWQOI.QOIHeader {
        
        if let error = Utility().qoiCheckData(data) { throw error }
        
        let bytes = Array(data)
        
        let magicBytes = Data(bytes[0...3])
        let widthBytes = Data(bytes[4...7])
        let heightBytes = Data(bytes[8...11])
        let channelsByte = bytes[12]
        let colorspaceByte = bytes[13]
        
        let magic = String(bytes: magicBytes, encoding: .utf8) ?? .init()
        let width = UInt32(bigEndian: widthBytes.withUnsafeBytes { $0.load(as: UInt32.self) })
        let height = UInt32(bigEndian: heightBytes.withUnsafeBytes { $0.load(as: UInt32.self) })
        let channels = UInt8(channelsByte)
        let colorSpace = UInt8(colorspaceByte)
        
        return WWQOI.QOIHeader(magic: magic, width: width, height: height, channels: channels, colorSpace: colorSpace)
    }
}

// MARK: - QOIHeader
extension WWQOI.QOIHeader {
    
    /// 測試解出來的Header資料對不對
    /// - Returns: QOIDecodeErro?
    func checkValid() -> WWQOI.DecodeError? {
        
        if (magic != "qoif") { return .invalidMagic }
        if (width < 1) { return .invalidImageSize }
        if (height < 1) { return .invalidImageSize }
        if (WWQOI.Constant.maxPixels < width * height) { return .invalidImageSize }
        
        guard (WWQOI.Channels(rawValue: channels) != nil) else { return .unsupportedChannels }
        guard (WWQOI.ColorSpace(rawValue: colorSpace) != nil) else { return .unsupportedColorSpace }
        
        return nil
    }
}

