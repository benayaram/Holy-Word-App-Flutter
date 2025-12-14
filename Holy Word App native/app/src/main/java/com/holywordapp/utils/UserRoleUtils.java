package com.holywordapp.utils;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility class for managing user roles
 */
public class UserRoleUtils {
    
    // Role constants
    public static final int ROLE_ADMIN = 0;
    public static final int ROLE_USER = 1;
    
    /**
     * Get role name from role value
     */
    public static String getRoleName(int role) {
        switch (role) {
            case ROLE_ADMIN:
                return "Admin";
            case ROLE_USER:
                return "User";
            default:
                return "User"; // Default to User
        }
    }
    
    /**
     * Check if role is Admin
     */
    public static boolean isAdmin(int role) {
        return role == ROLE_ADMIN;
    }
    
    /**
     * Check if role is User
     */
    public static boolean isUser(int role) {
        return role == ROLE_USER;
    }
    
    /**
     * Get default role for new users
     */
    public static int getDefaultRole() {
        return ROLE_USER;
    }
    
    /**
     * Create user data map for Firestore with only the fields we want to save
     */
    public static Map<String, Object> createUserDataMap(String uid, String email, String name, int role) {
        Map<String, Object> userData = new HashMap<>();
        userData.put("uid", uid);
        userData.put("email", email);
        userData.put("name", name);
        userData.put("role", role);
        userData.put("createdAt", System.currentTimeMillis());
        userData.put("lastLoginAt", System.currentTimeMillis());
        return userData;
    }
    
    /**
     * Create user data map for Firestore with default role (User)
     */
    public static Map<String, Object> createUserDataMap(String uid, String email, String name) {
        return createUserDataMap(uid, email, name, getDefaultRole());
    }
} 