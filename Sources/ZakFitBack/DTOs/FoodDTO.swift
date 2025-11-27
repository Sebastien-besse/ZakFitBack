//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

struct FoodDTO: Content {
    var name: String
    var calories: Int
    var proteins: Int
    var carbs: Int
    var lipids: Int
}
