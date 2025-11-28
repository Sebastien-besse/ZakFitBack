//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

struct MealFoodDTO: Content {
    var id: UUID
    var name: String
    var quantity: Int
    var calories: Int
    var proteins: Int
    var carbs: Int
    var lipids: Int
}

struct MealFoodInputDTO: Content{
    var foodID: UUID
    var quantity: Int
}
