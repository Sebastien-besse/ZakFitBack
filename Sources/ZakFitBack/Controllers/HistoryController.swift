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

    // MARK: - DAILY
    @Sendable
    func getDailyHistory(req: Request) async throws -> DailyHistoryDTO {
        let payload = try req.auth.require(UserPayload.self)

        guard let dateString = req.query[String.self, at: "date"],
              let date = ISO8601DateFormatter().date(from: dateString)
        else {
            throw Abort(.badRequest, reason: "Invalid or missing date parameter.")
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateMeal >= startOfDay)
            .filter(\.$dateMeal < endOfDay)
            .all()

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
                DailyMealDTO(id: $0.id!, name: $0.typeMeal, calories: $0.totalCalories, date: $0.dateMeal ?? Date())
            },
            activities: activities.map {
                DailyActivityDTO(id: $0.id!, name: $0.activityName, caloriesBurned: $0.caloriesBurned, date: $0.dateActivity)
            }
        )
    }

    // MARK: - Historique global par mois
    @Sendable
    func getMonthSummary(req: Request) async throws -> MonthSummaryDTO {
        let payload = try req.auth.require(UserPayload.self)
        let calendar = Calendar.current

        guard
            let year = req.query[Int.self, at: "year"],
            let month = req.query[Int.self, at: "month"],
            (1...12).contains(month)
        else {
            throw Abort(.badRequest, reason: "Missing year or month.")
        }

        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = 1

        let startDate = calendar.date(from: comp)!
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count

        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateMeal >= startDate)
            .filter(\.$dateMeal < endDate)
            .all()

        let activities = try await Activity.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$dateActivity >= startDate)
            .filter(\.$dateActivity < endDate)
            .all()

        let totalMeals = meals.count
        let totalActivities = activities.count
        let totalConsumed = meals.map { $0.totalCalories }.reduce(0, +)
        let totalBurned = activities.map { $0.caloriesBurned }.reduce(0, +)

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
