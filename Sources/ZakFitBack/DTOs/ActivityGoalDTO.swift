//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//


import Vapor

struct ActivityGoalDTO: Content {
    var typeActivity: String
    var trainingFrequency: Int
    var caloriesBurned: Int
    var durationOfSessions: Int
}

struct ActivityGoalResponseDTO: Content {
    var id: UUID
    var typeActivity: String
    var trainingFrequency: Int
    var caloriesBurned: Int
    var durationOfSessions: Int
    
    init(from goal: ActivityGoal) throws {
        self.id = try goal.requireID()
        self.typeActivity = goal.typeActivity
        self.trainingFrequency = goal.trainingFrequency
        self.caloriesBurned = goal.caloriesBurned
        self.durationOfSessions = goal.durationOfSessions
    }
}
