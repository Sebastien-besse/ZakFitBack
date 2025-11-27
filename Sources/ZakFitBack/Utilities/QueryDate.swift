//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

struct QueryDate: LosslessStringConvertible, Codable {
    let date: Date

    init(_ date: Date) {
        self.date = date
    }

    init?(_ description: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let d = formatter.date(from: description) else { return nil }
        self.date = d
    }

    var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

