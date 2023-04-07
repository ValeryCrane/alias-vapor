import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("signup", use: signupHandler)
        users.post("signin", use: signinHandler)
        users.post("signout", use: signoutHandler)
        users.get("info", use: infoHandler)
    }
    
    /// Метод регистрации.
    /// - Parameter req: Запрос.
    /// - Returns: Токен.
    func signupHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.content.decode(User.self)
        return User.query(on: req.db)
            .filter(\.$username == user.username)
            .first()
            .tryFlatMap ({ existingUser in
                if existingUser != nil {
                    throw Abort(.conflict, reason: "A user with that username already exists")
                }
                user.password = try Bcrypt.hash(user.password)
                return user.save(on: req.db).tryFlatMap({
                    let token = try Token.generate(for: user)
                    return token.save(on: req.db).map { token }
                })
            })
    }
    
    /// Метод авторизации.
    /// - Parameter req: Запрос.
    /// - Returns: Токен.
    func signinHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.content.decode(User.self)
        return User.query(on: req.db)
            .filter(\.$username == user.username)
            .first()
            .tryFlatMap ({ existingUser in
                guard
                    let existingUser = existingUser,
                    try Bcrypt.verify(user.password, created: existingUser.password)
                else {
                    throw Abort(.notFound, reason: "There is no users with such username")
                }
                
                let token = try Token.generate(for: existingUser)
                return token.save(on: req.db).map { token }
            })
    }
    
    /// Метод выхода из аккаунта (удаляет токен).
    /// - Parameter req: Запрос.
    /// - Returns: true - если все ок.
    func signoutHandler(_ req: Request) throws -> EventLoopFuture<Bool> {
        try req.auth.require(User.self)
        guard let bearerToken = req.headers.bearerAuthorization?.token else {
            throw Abort(.notFound, reason: "You didn't provide auth token.")
        }
        
        return Token.query(on: req.db)
            .filter(\.$token == bearerToken)
            .first()
            .tryFlatMap({ token in
                guard let token = token else {
                    throw Abort(.notFound, reason: "Invalid access token")
                }
                
                return token.delete(on: req.db).map({
                    req.auth.logout(User.self)
                    return true
                })
            })
    }
    
    /// Информация о пользователе.
    /// - Parameter req: Запрос.
    /// - Returns: Пользователь.
    func infoHandler(_ req: Request) throws -> User {
        try req.auth.require(User.self)
    }
}

