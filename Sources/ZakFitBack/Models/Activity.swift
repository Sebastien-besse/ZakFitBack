//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class Activity: Model, Content, @unchecked Sendable {
    static let schema = "activity"

    @ID(custom: "activity_id")
    var id: UUID?

    @Parent(key: "exercise_id")
    var exercise: Exercise

    @Field(key: "dure_activity")
    var duration: Int

    @Field(key: "calories_burned")
    var caloriesBurned: Int

    @Field(key: "date_activity")
    var dateActivity: Date

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(id: UUID? = nil, exerciseID: UUID, duration: Int, caloriesBurned: Int, date: Date, userID: UUID) {
        self.id = id
        self.$exercise.id = exerciseID
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.dateActivity = date
        self.$user.id = userID
    }
}
