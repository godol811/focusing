//
//  ResponseModel.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import Foundation

// MARK: - ResponseModel
struct ResponseModel: Codable {
    let faces: [Faces]
    let nFaces: Int
    let responseTime: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case faces
        case nFaces = "n_faces"
        case responseTime = "response_time"
        case status
    }
}

// MARK: - Face
struct Faces: Codable {
    let bbox: Bbox
    let index: Int
    let scores: Scores
}

// MARK: - Bbox
struct Bbox: Codable {
    let h, w, x, y: Int
}

// MARK: - Scores
struct Scores: Codable {
    let beauty, cute, money, trouble: Double
}
