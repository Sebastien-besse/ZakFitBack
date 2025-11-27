//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

struct CaloriesGoalDTO: Content {
    let caloriesGoal: Int
    let proteinsGoal: Int
    let carbsGoal: Int
    let lipidsGoal: Int
}

struct CaloriesGoalResponseDTO: Content {
    var id: UUID
    var caloriesGoal: Int
    var proteinsGoal: Int
    var carbsGoal: Int
    var lipidsGoal: Int
    
    init(from goal: CaloriesGoal) throws {
        self.id = try goal.requireID()
        self.caloriesGoal = goal.caloriesGoal
        self.proteinsGoal = goal.proteinsGoal
        self.carbsGoal = goal.carbsGoal
        self.lipidsGoal = goal.lipidsGoal
    }
}
