//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

// MARK: - Repas d'une journée
struct DailyMealDTO: Content {
    let id: UUID
    let name: String
    let calories: Int
    let date: Date
}

// MARK: - Activité d'une journée
struct DailyActivityDTO: Content {
    let id: UUID
    let name: String
    let caloriesBurned: Int
    let date: Date
}

// MARK: - Résumé JOURNALIER
struct DailyHistoryDTO: Content {
    let date: Date
    let totalCaloriesConsumed: Int
    let totalCaloriesBurned: Int
    let meals: [DailyMealDTO]
    let activities: [DailyActivityDTO]
}

// MARK: - Résumé MENSUEL (jour par jour)
struct MonthlyDayDTO: Content {
    let date: Date
    let caloriesConsumed: Int
    let caloriesBurned: Int
    let mealCount: Int
    let activityCount: Int
}

// MARK: - Résumé MENSUEL GLOBAL (pour les cartes)
struct MonthSummaryDTO: Content {
    let month: String
    let averageActivitiesPerDay: Double
    let averageCaloriesBurnedPerDay: Int
    let averageCaloriesConsumedPerDay: Int
    let averageMealsPerDay: Double
}
