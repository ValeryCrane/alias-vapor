import Vapor
import Fluent

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        print("auth")
        return Token.query(on: request.db)
            .filter(\.$token == bearer.token)
            .first()
            .tryFlatMap({ token in
                if let token = token {
                    return token.$user.get(on: request.db).tryFlatMap({ user in
                        request.auth.login(user)
                        return request.eventLoop.makeSucceededFuture(())
                    })
                } else {
                    return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }
            })
   }
}
