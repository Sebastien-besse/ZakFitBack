//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//
import Vapor
import Fluent

struct FoodController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let food = routes.grouped("food")
        let protected = food.grouped(JWTMiddleware())
        protected.post("create", use: createFood)
        protected.get("foods", use: getAllFoods)
    }

    @Sendable
    func createFood(req: Request) async throws -> Food {
        let payload = try req.auth.require(UserPayload.self)
        let data = try req.content.decode(FoodDTO.self)
        let food = Food(
            foodName: data.name,
            calories: data.calories,
            proteins: data.proteins,
            carbs: data.carbs,
            lipids: data.lipids,
            userID: payload.id
        )
        try await food.create(on: req.db)
        return food
    }

    @Sendable
    func getAllFoods(req: Request) async throws -> [Food] {
        try await Food.query(on: req.db).all()
    }
}
