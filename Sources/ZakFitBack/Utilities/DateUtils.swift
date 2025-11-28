//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 28/11/2025.
//

import Foundation

enum DateUtils {

    //Format unique utilisé dans toute l'app : dd-MM-yyyy
    static let defaultFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    //Début d'une journée
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    //Fin d'une journée
    static func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(date))!
    }
}
