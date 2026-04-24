//
//  QOIDecoder.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import WWByteReader

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
        
        let outputChannels = forceChannels ?? channels
        let pixelCount = Int(header.width * header.height)
        let outputStride = Int(outputChannels.rawValue)
        
        var reader = WWByteReader(data: data, offset: WWQOI.Constant.headerSize)
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
            
            let byte1 = try reader.readUIntValue() as UInt8
            let byte1Code = try WWQOI.OperationCode.find(by: byte1)
            
            switch byte1Code {
            case .index: pixel = index[Int(byte1 & 0x3F)]
            case .run: run = Int(byte1 & 0x3F)
            case .rgba: try readRGBAColor(from: &reader, pixel: &pixel)
            case .rgb: try readRGBColor(from: &reader, pixel: &pixel)
            case .diff: parseDiffColor(from: byte1, previous: previous, pixel: &pixel)
            case .luma: try parseLuminanceColor(from: &reader, byte1: byte1, previous: previous, pixel: &pixel)
            }
        }
        
        return .init(header: header, pixels: output)
    }
}

// MARK: - 小工具
private extension WWQOI.Decoder {
    
    /// 讀取RGBA值
    /// - Parameters:
    ///   - reader: WWByteReader
    ///   - pixel: 顏色像素
    func readRGBAColor(from reader: inout WWByteReader, pixel: inout WWQOI.Pixel) throws {
        
        pixel.red = try reader.readUIntValue() as UInt8
        pixel.green = try reader.readUIntValue() as UInt8
        pixel.blue = try reader.readUIntValue() as UInt8
        pixel.alpha = try reader.readUIntValue() as UInt8
    }
    
    /// 讀取RGB值
    /// - Parameters:
    ///   - reader: WWByteReader
    ///   - pixel: 顏色像素
    func readRGBColor(from reader: inout WWByteReader, pixel: inout WWQOI.Pixel) throws {
        
        pixel.red = try reader.readUIntValue() as UInt8
        pixel.green = try reader.readUIntValue() as UInt8
        pixel.blue = try reader.readUIntValue() as UInt8
    }
    
    /// 解析亮度感知顏色 (以綠色為主軸)
    /// - Parameters:
    ///   - reader: WWByteReader
    ///   - byte1: 上一次的資料
    ///   - previous: 上一次的顏色像素資料
    ///   - pixel: 顏色像素
    func parseLuminanceColor(from reader: inout WWByteReader, byte1: UInt8, previous: WWQOI.Pixel, pixel: inout WWQOI.Pixel) throws {
        
        let byte2 = try reader.readUIntValue() as UInt8
        let deltaGreen = Int(byte1 & 0x3F) - 32
        let deltaRed_deltaGreen = Int((byte2 >> 4) & 0x0F) - 8
        let deltaBlue_deltaGreen = Int(byte2 & 0x0F) - 8
        
        pixel.red = previous.red.addWrap(deltaGreen + deltaRed_deltaGreen)
        pixel.green = previous.green.addWrap(deltaGreen)
        pixel.blue = previous.blue.addWrap(deltaGreen + deltaBlue_deltaGreen)
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
}
