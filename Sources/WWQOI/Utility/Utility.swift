//
//  Utility.swift
//  WWQOI
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import CoreGraphics

// MARK: - 工具庫
final class Utility {}

// MARK: - 常用工具
extension Utility {
    
    /// [計算QOI定義的哈希函數值 (選歷史顏色用)](https://qoiformat.org/)
    /// - Parameters:
    ///   - red: 紅色 (0 ~ 255)
    ///   - green: 綠色 (0 ~ 255)
    ///   - blue: 藍色 (0 ~ 255)
    ///   - alpha: 透明度 (0 ~ 255)
    /// - Returns: Int
    func qoiHashIndex(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> Int {
        let sum = (red &* 3) &+ (green &* 5) &+ (blue &* 7) &+ (alpha &* 11)
        return Int(sum & 63)
    }
    
    /// 基本QOI的文件對不對 (大小 + 結尾)
    /// - Parameter data: Data
    /// - Returns: Error?
    func qoiCheckData(_ data: Data) -> Error? {
        
        let bytes = Array(data)
        
        if (bytes.count < qoiMinimumSize()) { return WWQOI.DecodeError.invalidData }
        if (bytes.suffix(8) != WWQOI.Constant.endMarker) { return WWQOI.DecodeError.invalidEndMarker }
        
        return nil
    }
}

// MARK: - 小工具
private extension Utility {

    /// QOI圖檔最小的文件大小值 => Header (14位元) + 結尾 (8位元)
    /// - Returns: Int
    func qoiMinimumSize() -> Int {
        return WWQOI.Constant.headerSize + WWQOI.Constant.endMarker.count
    }
}
