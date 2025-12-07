//
//  AppState.swift
//  LostAndFound
//
//  Created by Craig Bakke on 11/19/25.
//

import SwiftUI
import Combine
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userEmail: String?
    @Published var userDisplayName: String?
    @Published var userProfile: [String: Any]?
    
    private let provider = OAuthProvider(providerID: "microsoft.com")
    
    private let keychainStore = KeychainStore(service: "edu.wit.lostandfound.auth")
    private let sessionStorageKey = "edu.wit.lostandfound.auth.userSession"
    
    private var cachedSession: StoredUserSession?
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        provider.scopes = ["email"]
        restoreSessionFromStorage()
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user = user {
                let profile = self.userProfile ?? self.cachedProfileDictionary()
                self.updatePublishedState(isLoggedIn: true,
                                          email: user.email,
                                          displayName: user.displayName,
                                          profile: profile)
                user.getIDToken { token, _ in
                    self.persistSession(for: user, idToken: token, profile: profile)
                }
            } else {
                self.resetPublishedState()
                self.clearPersistedSession()
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func login() {
        provider.getCredentialWith(nil) { [weak self] credential, error in
            guard let self else { return }
            if let error = error {
                print("OAuth credential error: \(error.localizedDescription)")
                return
            }
            
            guard let credential = credential else {
                print("OAuth credential is missing.")
                return
            }
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription)")
                    return
                }
                
                guard let authResult = authResult else {
                    print("Firebase sign-in returned no result.")
                    return
                }
                
                let normalizedProfile = self.normalizedProfile(from: authResult.additionalUserInfo?.profile)
                
                self.updatePublishedState(isLoggedIn: true,
                                          email: authResult.user.email,
                                          displayName: authResult.user.displayName,
                                          profile: normalizedProfile)
                
                authResult.user.getIDToken { token, tokenError in
                    if let tokenError = tokenError {
                        print("Failed to fetch ID token: \(tokenError.localizedDescription)")
                    }
                    self.persistSession(for: authResult.user,
                                        idToken: token,
                                        profile: normalizedProfile)
                }
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Firebase sign-out failed: \(error.localizedDescription)")
        }
        
        clearPersistedSession()
        resetPublishedState()
    }
}

private extension AppState {
    struct StoredUserSession: Codable {
        let uid: String
        let email: String?
        let displayName: String?
        let idToken: String?
        let profileJSON: String?
    }
    
    func updatePublishedState(isLoggedIn: Bool,
                              email: String?,
                              displayName: String?,
                              profile: [String: Any]?) {
        DispatchQueue.main.async {
            self.isLoggedIn = isLoggedIn
            self.userEmail = email
            self.userDisplayName = displayName
            self.userProfile = profile
        }
    }
    
    func resetPublishedState() {
        updatePublishedState(isLoggedIn: false, email: nil, displayName: nil, profile: nil)
    }
    
    func normalizedProfile(from profile: [AnyHashable: Any]?) -> [String: Any]? {
        guard let profile else { return nil }
        var normalized: [String: Any] = [:]
        for (key, value) in profile {
            guard let keyString = key as? String else { continue }
            normalized[keyString] = value
        }
        return normalized.isEmpty ? nil : normalized
    }
    
    func serializeProfile(_ profile: [String: Any]?) -> String? {
        guard let profile,
              JSONSerialization.isValidJSONObject(profile),
              let data = try? JSONSerialization.data(withJSONObject: profile, options: []) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func deserializeProfile(from json: String?) -> [String: Any]? {
        guard let json,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = object as? [String: Any] else {
            return nil
        }
        return dictionary
    }
    
    func persistSession(for user: User, idToken: String?, profile: [String: Any]?) {
        let session = StoredUserSession(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            idToken: idToken,
            profileJSON: serializeProfile(profile)
        )
        
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }
        
        do {
            try keychainStore.save(data, for: sessionStorageKey)
            cachedSession = session
        } catch {
            print("Failed to store session in Keychain: \(error)")
        }
    }
    
    func restoreSessionFromStorage() {
        guard let session = loadSessionFromStorage() else {
            return
        }
        
        let profile = deserializeProfile(from: session.profileJSON)
        updatePublishedState(isLoggedIn: true,
                             email: session.email,
                             displayName: session.displayName,
                             profile: profile)
    }
    
    func cachedProfileDictionary() -> [String: Any]? {
        guard let session = loadSessionFromStorage() else {
            return nil
        }
        return deserializeProfile(from: session.profileJSON)
    }
    
    func loadSessionFromStorage() -> StoredUserSession? {
        if let cachedSession {
            return cachedSession
        }
        
        let storedData: Data?
        do {
            storedData = try keychainStore.read(for: sessionStorageKey)
        } catch {
            print("Failed to read session from Keychain: \(error)")
            return nil
        }
        
        guard
            let sessionData = storedData,
            let session = try? JSONDecoder().decode(StoredUserSession.self, from: sessionData)
        else {
            return nil
        }
        
        cachedSession = session
        return session
    }
    
    func clearPersistedSession() {
        do {
            try keychainStore.delete(for: sessionStorageKey)
        } catch {
            print("Failed to clear stored session: \(error)")
        }
        cachedSession = nil
    }
}
