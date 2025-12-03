//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 26/11/2025.
//

import Vapor

// DTO pour créer une activité
struct ActivityDTO: Content {
    var exerciseID: UUID
    var duration: Int
    var caloriesBurned: Int?
    var date: Date?

    func toModel(exercise: Exercise, userID: UUID) -> Activity {
        let calories = caloriesBurned ?? (exercise.defaultCaloriesPerMin ?? 5) * duration
        return Activity(
            exerciseID: exercise.id!,
            duration: duration,
            caloriesBurned: calories,
            date: date ?? Date(),
            userID: userID
        )
    }
}

// DTO pour mettre à jour une activité
struct UpdateActivityDTO: Content {
    var exerciseID: UUID?
    var duration: Int?
    var caloriesBurned: Int?
    var date: Date?
}

// DTO pour la réponse côté front
struct ActivityResponse: Content {
    var id: UUID?
    var exerciseName: String
    var activityType: String
    var duration: Int
    var calories: Int
    var date: Date
    var motivationMessage: String  // 👈 NOUVEAU
}

extension ActivityResponse {
    init(from activity: Activity, exercise: Exercise) {
        self.id = activity.id
        self.exerciseName = exercise.name
        self.activityType = exercise.type
        self.duration = activity.duration
        self.calories = activity.caloriesBurned
        self.date = activity.dateActivity
        self.motivationMessage = exercise.motivationMessage
    }
}


struct ExerciseDTO: Content {
    var id: UUID
    var name: String
    var type: String
    var defaultCaloriesPerMin: Int
    var motivationMessage: String
}
