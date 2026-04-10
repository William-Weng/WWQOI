//
//  Constant.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation

// MARK: - 常數
public extension WWQOI {
    
    /// [顏色通道](https://qoiformat.org/qoi-specification.pdf)
    enum Channels: UInt8, Sendable {
        case rgb = 3
        case rgba = 4
    }
    
    /// [色彩空間](https://qoiformat.org/qoi-specification.pdf)
    enum ColorSpace: UInt8, Sendable {
        case sRGBLinearAlpha = 0
        case allLinear = 1
    }
}

// MARK: - Error
public extension WWQOI {
        
    /// 取得圖片Buffer錯誤
    enum ImageBufferError: Error, Sendable {
        case contextCreationFailed
    }
    
    /// 編碼錯誤 (壓縮)
    enum EncodeError: Error, Sendable {
        case invalidImageSize
        case pixelDataSizeMismatch
    }
    
    /// 解碼錯誤 (解壓縮)
    enum DecodeError: Error, Sendable {
        case invalidData
        case invalidMagic
        case unsupportedChannels
        case unsupportedColorSpace
        case invalidImageSize
        case truncatedData
        case invalidEndMarker
    }
}

// MARK: - static
extension WWQOI {
    
    /// [常數值](https://qoiformat.org/qoi-specification.pdf)
    enum Constant {
        static let magic: [UInt8] = "qoif".toUInt8()                // "qoif" => [0x71, 0x6F, 0x69, 0x66]
        static let endMarker: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 1]    // 檔案結尾
        static let headerSize = 14                                  // Header大小
        static let maxPixels: UInt32 = 400_000_000                  // 能處理最大像素
    }
}

// MARK: - enum
extension WWQOI {
    
    /// [功能編號代號類型](https://qoiformat.org/qoi-specification.pdf)
    enum OperationCode: UInt8 {
        case index = 0x00   // 重用 history[index] 顏色 (0x00-0x3F)
        case diff  = 0x40   // dr,dg,db ∈ [-2,1] 差值 (0x40-0x7F)
        case luma  = 0x80   // dg ∈ [-32,31] + 細微差值 (0x80-0xBF)
        case run   = 0xC0   // 重複相同像素，run ∈ (0xC0-0xFD)
        case rgb   = 0xFE   // 完整 RGB (a=255) (0xFE)
        case rgba  = 0xFF   // 完整 RGBA (0xFF)
        
        /// 找出byte1的類型
        /// - Parameter byte1: UInt8
        /// - Returns: OperationCode
        static func find(by byte1: UInt8) throws -> OperationCode {
            
            let fullCode = WWQOI.OperationCode(rawValue: byte1)
            let labelCode = WWQOI.OperationCode(rawValue: byte1 & WWQOI.OperationCode.run.rawValue)
            
            switch fullCode {
            case .rgb, .rgba: return fullCode!
            default:
                switch labelCode {
                case .index, .diff, .luma, .run: return labelCode!
                default: throw WWQOI.DecodeError.invalidData
                }
            }
        }
    }
    
    /// 壓縮類型
    enum EncodeType {
        case rgba
        case rgb
        case diff(_ deltaRed: Int, _ deltaGreen: Int, _ deltaBlue: Int)
        case luma(_ deltaGreen: Int, _ deltaRed_deltaGreen: Int, _ deltaBlue_deltaGreen: Int)
    }
}
