import Vapor
import JWT

extension UserAccountModel {
    func createSignedTokenPair(in tokenFamily: UserTokenFamilyModel? = nil, on req: Request) async throws -> (refreshToken: String, accessToken: String) {
        /// create token family if necessary
        let tokenFamily = try tokenFamily ?? UserTokenFamilyModel(userId: self.requireID(), tokenType: .tokenRefresh)
        /// verify token family belongs to user
        guard try tokenFamily.$user.id == self.requireID() else {
            throw Abort(.unauthorized)
        }
        /// create tokens for the user
        let refreshToken = try await UserToken.createRefreshToken(for: self, in: tokenFamily, on: req.db)
        let accessToken = try UserToken.createAccessToken(for: self)
        /// sign tokens
        let signedRefreshToken = try req.jwt.sign(refreshToken, kid: .private)
        let signedAccessToken = try req.jwt.sign(accessToken, kid: .private)
        /// return the signed tokens
        return (signedRefreshToken, signedAccessToken)
    }

    func createSignedVerificationToken(on req: Request) async throws -> String {
        /// check if verification token family exists
        let existingTokenFamily = try await self.$tokenFamilies.query(on: req.db).filter(\.$tokenType, .equal, .verification).first()
        /// create token family if necessary
        let tokenFamily = try existingTokenFamily ?? UserTokenFamilyModel(userId: self.requireID(), tokenType: .verification)
        /// verify token family belongs to user
        guard try tokenFamily.$user.id == self.requireID() else {
            throw Abort(.unauthorized)
        }
        /// create token for user
        let verificationToken = try await UserToken.createVerificationToken(for: self, in: tokenFamily, on: req.db)
        /// sign token
        let signedVerificationToken = try req.jwt.sign(verificationToken, kid: .private)
        /// return the signed token
        return signedVerificationToken
    }
}
