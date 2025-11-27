//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 26/11/2025.
//

import Vapor

struct ActivityDTO: Content {
    var type: String
    var duration: Int
    var caloriesBurned: Int?
    var date: Date?
    
    func estimatedCalories() -> Int {
        switch type.lowercased() {
        case "cardio": return duration * 8
        case "musculation": return duration * 6
        case "yoga": return duration * 4
        case "marche": return duration * 3
        default: return duration * 5
        }
    }
    
    func toModel(userID: UUID) -> Activity {
        Activity(
            activityName: type,
            dureActivity: duration,
            caloriesBurned: caloriesBurned ?? estimatedCalories(),
            dateActivity: date ?? Date(),
            userID: userID
        )
    }
}

struct UpdateActivityDTO: Content {
    var type: String?
    var duration: Int?
    var caloriesBurned: Int?
    var date: Date?
}

struct ActivityResponse: Content{
    var id: UUID?
    var type: String
    var duration: Int
    var calories: Int
    var date: Date
}
extension ActivityResponse {
    init(from activity: Activity) throws {
        self.id = try activity.requireID()
        self.type = activity.activityName
        self.duration = activity.dureActivity
        self.calories = activity.caloriesBurned
        self.date = activity.dateActivity
    }
}

