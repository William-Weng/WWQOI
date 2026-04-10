 //
//  QOIDecoder.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation

// MARK: - QOI解碼工具 (解壓縮)
extension WWQOI {
    
    struct Decoder: Sendable {
        private let util: Utility = .init()
    }
}

// MARK: - 公開函數
extension WWQOI.Decoder {
    
    /// 執行解碼 (解壓縮)
    /// - Parameters:
    ///   - data: Data
    ///   - forceChannels: WWQOI.Channels
    /// - Returns: WWQOI.QOIImag
    func execute(with data: Data, forceChannels: WWQOI.Channels? = nil) throws -> WWQOI.Image {
        
        if let error = util.qoiCheckData(data) { throw error }
        
        let header = try WWQOI.QOIHeader.build(from: data)
        if let error = header.checkValid() { throw error }
        
        guard let channels = WWQOI.Channels(rawValue: header.channels) else { throw WWQOI.DecodeError.unsupportedChannels }
        
        var bytes = Array(data)
        var cursor = WWQOI.Constant.headerSize
        
        let outputChannels = forceChannels ?? channels
        let pixelCount = Int(header.width * header.height)
        let outputStride = Int(outputChannels.rawValue)
        
        var index = Array(repeating: WWQOI.Pixel.new, count: 64)
        var previous = WWQOI.Pixel.start
        var run = 0
        var output = Data(capacity: pixelCount * outputStride)
        
        for _ in 0..<pixelCount {
            
            var pixel = previous
            
            defer {
                
                index[pixel.hashIndex] = pixel
                previous = pixel
                
                output.append(pixel.red)
                output.append(pixel.green)
                output.append(pixel.blue)
                
                if (outputChannels == .rgba) { output.append(pixel.alpha) }
            }
            
            if (run > 0) { run -= 1; continue }
            
            let byte1 = try bytes.readByte(at: cursor)
            let byte1Code = try WWQOI.OperationCode.find(by: byte1)
            cursor += 1
            
            switch byte1Code {
            case .index: pixel = index[Int(byte1 & 0x3F)]
            case .run: run = Int(byte1 & 0x3F)
            case .rgba: cursor = try readRGBAColor(from: cursor, bytes: bytes, pixel: &pixel)
            case .rgb: cursor = try readRGBColor(from: cursor, bytes: bytes, pixel: &pixel)
            case .diff: parseDiffColor(from: byte1, previous: previous, pixel: &pixel)
            case .luma: cursor = try parseLuminanceColor(at: cursor, bytes: bytes, byte1: byte1, previous: previous, pixel: &pixel)
            }
        }
        
        return .init(header: header, pixels: output)
    }
}

// MARK: - 小工具
private extension WWQOI.Decoder {
    
    /// 讀取RGBA值
    /// - Parameters:
    ///   - cursor: 指標位置
    ///   - bytes: 圖片資料
    ///   - pixel: 顏色像素
    /// - Returns: Int
    func readRGBAColor(from cursor: Int, bytes: [Data.Element], pixel: inout WWQOI.Pixel) throws -> Int {
        
        pixel.red = try bytes.readByte(at: cursor + 0)
        pixel.green = try bytes.readByte(at: cursor + 1)
        pixel.blue = try bytes.readByte(at: cursor + 2)
        pixel.alpha = try bytes.readByte(at: cursor + 3)
        
        return cursor + 4
    }
    
    /// 讀取RGB值
    /// - Parameters:
    ///   - cursor: 指標位置
    ///   - bytes: 圖片資料
    ///   - pixel: 顏色像素
    /// - Returns: Int
    func readRGBColor(from cursor: Int, bytes: [Data.Element], pixel: inout WWQOI.Pixel) throws -> Int {
        
        pixel.red = try bytes.readByte(at: cursor + 0)
        pixel.green = try bytes.readByte(at: cursor + 1)
        pixel.blue = try bytes.readByte(at: cursor + 2)
        
        return cursor + 3
    }
    
    /// 解析差異顏色
    /// - Parameters:
    ///   - byte1: 差異資料
    ///   - previous: 上一次的顏色像素資料
    ///   - pixel: 顏色像素
    func parseDiffColor(from byte1: UInt8, previous: WWQOI.Pixel, pixel: inout WWQOI.Pixel) {
        
        let deltaRed = Int((byte1 >> 4) & 0x03) - 2
        let deltaGreen = Int((byte1 >> 2) & 0x03) - 2
        let deltaBlue = Int(byte1 & 0x03) - 2
        
        pixel.red = previous.red.addWrap(deltaRed)
        pixel.green = previous.green.addWrap(deltaGreen)
        pixel.blue = previous.blue.addWrap(deltaBlue)
    }
    
    /// 解析亮度感知顏色 (以綠色為主軸)
    /// - Parameters:
    ///   - cursor: 指標位置
    ///   - bytes: 圖片資料
    ///   - byte1: 差異資料
    ///   - previous: 上一次的顏色像素資料
    ///   - pixel: 顏色像素
    func parseLuminanceColor(at cursor: Int, bytes: [Data.Element], byte1: UInt8, previous: WWQOI.Pixel, pixel: inout WWQOI.Pixel) throws -> Int {
        
        let byte2 = try bytes.readByte(at: cursor)
        let deltaGreen = Int(byte1 & 0x3F) - 32
        let deltaRed_deltaGreen = Int((byte2 >> 4) & 0x0F) - 8
        let deltaBlue_deltaGreen = Int(byte2 & 0x0F) - 8
        
        pixel.red = previous.red.addWrap(deltaGreen + deltaRed_deltaGreen)
        pixel.green = previous.green.addWrap(deltaGreen)
        pixel.blue = previous.blue.addWrap(deltaGreen + deltaBlue_deltaGreen)
        
        return cursor + 1
    }
}
