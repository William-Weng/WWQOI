//
//  QOIEncoder.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import CoreGraphics

// MARK: - QOI編碼工具 (壓縮)
extension WWQOI {
    
    struct Encoder: Sendable {}
}

// MARK: - 公開工具
extension WWQOI.Encoder {
    
    /// 將圖片壓縮成.qoi
    /// - Parameters:
    ///   - cgImage: CGImage
    ///   - colorSpace: WWQOI.ColorSpace
    /// - Returns: Data
    func execute(with cgImage: CGImage, colorSpace: WWQOI.ColorSpace = .sRGBLinearAlpha) throws -> Data {
        
        let buffer = try cgImage.toRGBA()
        let data = try encode(buffer, colorSpace: colorSpace)
        
        return data
    }
}

// MARK: - 小工具
private extension WWQOI.Encoder {
    
    /// 將圖片資料壓縮成.qoi
    /// - Parameters:
    ///   - buffer: WWQOI.RGBA8Buffer
    ///   - colorSpace: WWQOI.ColorSpace
    /// - Returns: Data
    func encode(_ buffer: WWQOI.RGBA8Buffer, colorSpace: WWQOI.ColorSpace = .sRGBLinearAlpha) throws -> Data {
        
        let header = WWQOI.QOIHeader(magic: "qoif", width: UInt32(buffer.width), height: UInt32(buffer.height), channels: 4, colorSpace: colorSpace.rawValue)
        
        let image = WWQOI.Image(header: header, pixels: Data(buffer.pixels))
        return try encode(image)
    }
    
    /// 將圖片資料壓縮成.qoi
    /// - Parameter image: WWQOI.QOIImage
    /// - Returns: Data
    func encode(_ image: WWQOI.Image) throws -> Data {
        try encode(pixels: image.pixels, width: image.header.width, height: image.header.height, channels: image.header.channels, colorSpace: image.header.colorSpace)
    }
    
    /// 將圖片資料壓縮成.qoi
    /// - Parameters:
    ///   - pixels: Data
    ///   - width: UInt32
    ///   - height: UInt32
    ///   - channels: UInt8
    ///   - colorSpace: UInt8
    /// - Returns: Data
    func encode(pixels: Data, width: UInt32, height: UInt32, channels: UInt8, colorSpace: UInt8) throws -> Data {
        
        let channelsType = WWQOI.Channels(rawValue: channels) ?? .rgb
        let pixelStride = channels
        let pixelCount = width * height
        
        guard (pixels.count == Int(pixelCount) * Int(pixelStride)) else { throw WWQOI.EncodeError.pixelDataSizeMismatch }
        
        let input = Array(pixels)
        var output = Data.estimateQOIBuffer(pixelCount: pixelCount)
        
        writeHeader(to: &output, width: width, height: height, channels: channels, colorSpace: colorSpace)
        
        var index = Array(repeating: WWQOI.Pixel.new, count: 64)
        var previous = WWQOI.Pixel.start
        var run = 0
        
        let lastOffset = input.count - Int(pixelStride)
        
        for offset in stride(from: 0, to: input.count, by: Int.Stride(pixelStride)) {
            
            let pixel = WWQOI.Pixel.recover(from: input, offset: offset, channelsType: channelsType)

            if (pixel == previous) {
                run += 1
                if (run == 62) { flushRun(&run, output: &output) }
                if (offset == lastOffset) { flushRun(&run, output: &output) }
                continue
            }
            
            flushRun(&run, output: &output)
            
            let indexPosition = pixel.hashIndex
            
            if (index[indexPosition] == pixel) {
                output.append(WWQOI.OperationCode.index.rawValue | UInt8(indexPosition))
                previous = pixel
                continue
            }
            
            let encodeType = pixel.parseEncodeType(by: previous)
            index[indexPosition] = pixel
            
            switch encodeType {
            case .rgba: pixel.appendChunk(to: &output, hasAlpha: true)
            case .rgb: pixel.appendChunk(to: &output, hasAlpha: false)
            case let .diff(deltaRed, deltaGreen, deltaBlue): appendDiffChunk(to: &output, deltaRed: deltaRed, deltaGreen: deltaGreen, deltaBlue: deltaBlue)
            case let .luma(deltaGreen, deltaRed_deltaGreen, deltaBlue_deltaGreen): appendLumaChunk(to: &output, deltaGreen: deltaGreen, deltaRed_deltaGreen: deltaRed_deltaGreen, deltaBlue_deltaGreen: deltaBlue_deltaGreen)
            }
            
            previous = pixel
        }
        
        output.append(contentsOf: WWQOI.Constant.endMarker)
        return output
    }
    
    /// 寫入Header (順序要對)
    /// - Parameters:
    ///   - output: Data
    ///   - width: UInt32
    ///   - height: UInt32
    ///   - channels: UInt8
    ///   - colorSpace: UInt8
    func writeHeader(to output: inout Data, width: UInt32, height: UInt32, channels: UInt8, colorSpace: UInt8) {
        output.append(contentsOf: WWQOI.Constant.magic)
        width.write(to: &output)
        height.write(to: &output)
        output.append(channels)
        output.append(colorSpace)
    }
    
    /// 把run歸零 (0~62)
    /// - Parameters:
    ///   - run: Int
    ///   - output: Data
    func flushRun(_ run: inout Int, output: inout Data) {
        
        if (run < 1) { return }
        
        output.append(WWQOI.OperationCode.run.rawValue | UInt8(run - 1))
        run = 0
    }
    
    /// 加入Diff型式的資料
    /// - Parameters:
    ///   - output: Data
    ///   - deltaRed: Int
    ///   - deltaGreen: Int
    ///   - deltaBlue: Int
    func appendDiffChunk(to output: inout Data, deltaRed: Int, deltaGreen: Int, deltaBlue: Int) {
        output.append(WWQOI.OperationCode.diff.rawValue | UInt8(deltaRed + 2) << 4 | UInt8(deltaGreen + 2) << 2 | UInt8(deltaBlue + 2))
    }
    
    /// 加入Luam型式的資料
    /// - Parameters:
    ///   - output: Data
    ///   - deltaGreen: Int
    ///   - deltaRed_deltaGreen: Int
    ///   - deltaBlue_deltaGreen: Int
    func appendLumaChunk(to output: inout Data, deltaGreen: Int, deltaRed_deltaGreen: Int, deltaBlue_deltaGreen: Int) {
        output.append(WWQOI.OperationCode.luma.rawValue | UInt8(deltaGreen + 32))
        output.append(UInt8(deltaRed_deltaGreen + 8) << 4 | UInt8(deltaBlue_deltaGreen + 8))
    }
}

