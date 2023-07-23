import JWT

extension JWTError {
    /// JWT Error thrown when the submitted token is expired.
    static let tokenExpired = Self.claimVerificationFailure(name: "exp", reason: "expired")
}
