//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 02/12/2025.
//

import Vapor
import Fluent

final class Exercise: Model, Content, @unchecked Sendable {
    static let schema = "exercise"

    @ID(custom: "exercise_id")
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "type_activity")
    var type: String

    @Field(key: "default_calories_per_min")
    var defaultCaloriesPerMin: Int?

    @Field(key: "motivation_message")
    var motivationMessage: String

    init() {}

    init(id: UUID? = nil, name: String, type: String, defaultCaloriesPerMin: Int?, motivationMessage: String) {
        self.id = id
        self.name = name
        self.type = type
        self.defaultCaloriesPerMin = defaultCaloriesPerMin
        self.motivationMessage = motivationMessage
    }
}
