//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent

struct HistoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {

        let history = routes.grouped("history")
        let protected = history.grouped(JWTMiddleware())

        protected.get("daily", use: getDailyHistory)
        protected.get("month-summary", use: getMonthSummary)
    }

    // MARK: - Historique d'une journée
    @Sendable
    func getDailyHistory(req: Request) async throws -> DailyHistoryDTO {
        let payload = try req.auth.require(UserPayload.self)
        
        // Vérification du paramètre date (format dd-MM-yyyy)
        guard let dateString = req.query[String.self, at: "date"],
              let date = DateUtils.defaultFormatter.date(from: dateString) else {
            throw Abort(.badRequest, reason: "Paramètre de date invalide ou manquant")
        }

        let startOfDay = DateUtils.startOfDay(date)
        let endOfDay = DateUtils.endOfDay(date)

        // Repas du jour
        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateMeal >= startOfDay)
            .filter(\.$dateMeal < endOfDay)
            .all()

        // Activités du jour
        let activities = try await Activity.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateActivity >= startOfDay)
            .filter(\.$dateActivity < endOfDay)
            .all()

        let totalConsumed = meals.map { $0.totalCalories }.reduce(0, +)
        let totalBurned = activities.map { $0.caloriesBurned }.reduce(0, +)

        return DailyHistoryDTO(
            date: startOfDay,
            totalCaloriesConsumed: totalConsumed,
            totalCaloriesBurned: totalBurned,
            meals: meals.map {
                DailyMealDTO(
                    id: $0.id!,
                    name: $0.typeMeal,
                    calories: $0.totalCalories,
                    date: $0.dateMeal ?? Date()
                )
            },
            activities: activities.map {
                DailyActivityDTO(
                    id: $0.id!,
                    name: $0.activityName,
                    caloriesBurned: $0.caloriesBurned,
                    date: $0.dateActivity
                )
            }
        )
    }

    // MARK: - Historique global du mois
    @Sendable
    func getMonthSummary(req: Request) async throws -> MonthSummaryDTO {
        let payload = try req.auth.require(UserPayload.self)
        let calendar = Calendar.current

        // Vérifier year & month
        guard let year = req.query[Int.self, at: "year"],
              let month = req.query[Int.self, at: "month"],
              (1...12).contains(month) else {
            throw Abort(.badRequest, reason: "Année ou mois manquant ou invalide")
        }

        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = 1

        let startDate = calendar.date(from: comp)!
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count

        // Repas du mois
        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateMeal >= startDate)
            .filter(\.$dateMeal < endDate)
            .all()

        // Activités du mois
        let activities = try await Activity.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateActivity >= startDate)
            .filter(\.$dateActivity < endDate)
            .all()

        let totalMeals = meals.count
        let totalActivities = activities.count
        let totalConsumed = meals.map { $0.totalCalories }.reduce(0, +)
        let totalBurned = activities.map { $0.caloriesBurned }.reduce(0, +)

        // Formatage du nom du mois en français
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "LLLL"

        return MonthSummaryDTO(
            month: formatter.string(from: startDate).capitalized,
            averageActivitiesPerDay: Double(totalActivities) / Double(daysInMonth),
            averageCaloriesBurnedPerDay: totalBurned / daysInMonth,
            averageCaloriesConsumedPerDay: totalConsumed / daysInMonth,
            averageMealsPerDay: Double(totalMeals) / Double(daysInMonth)
        )
    }
}
