import Vapor
import Fluent

final class Token: Model, Content {
    static let schema = "tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "token")
    var token: String

    init() { }

    init(id: UUID? = nil, user: User, value: String) {
        self.id = id
        self.$user.id = try! user.requireID()
        self.token = value
    }

    static func generate(for user: User) throws -> Token {
        let value = [UInt8].random(count: 16).base64
        return Token(user: user, value: value)
    }
}

