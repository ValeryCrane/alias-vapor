import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    app.middleware.use(UserAuthenticator())
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "debug",
        password: Environment.get("DATABASE_PASSWORD") ?? "debug",
        database: Environment.get("DATABASE_NAME") ?? "postgres"
    ), as: .psql)
    
    // register routes
    try routes(app)
}
