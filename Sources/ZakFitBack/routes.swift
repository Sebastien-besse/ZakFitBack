import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: ActivityController())
    try app.register(collection: MealController())
    try app.register(collection: FoodController())
    try app.register(collection: ActivityGoalController())
    try app.register(collection: CaloriesGoalController())
    try app.register(collection: HistoryController())
}
