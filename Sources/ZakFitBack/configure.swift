import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "zakfit_db"
    ), as: .mysql)

    app.migrations.add(CreateTodo())
    
        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .custom("http://127.0.0.1:5500"),
            allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin],
            cacheExpiration: 120
        )

    // register routes
    try routes(app)
}
