package com.holywordapp.data.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

import com.holywordapp.utils.UserRoleUtils;

/**
 * User entity for Room database
 * Represents a user in the Holy Word App
 */
@Entity(tableName = "users")
public class User {

    @PrimaryKey
    @NonNull
    private String uid;

    private String email;
    private String name;
    private int role; // 0 = Admin, 1 = User (default)
    private long createdAt;
    private long lastLoginAt;

    // Default constructor
    public User() {
        this.createdAt = System.currentTimeMillis();
        this.lastLoginAt = System.currentTimeMillis();
        this.role = UserRoleUtils.getDefaultRole(); // Default role is User
    }

    // Constructor with parameters
    @Ignore
    public User(@NonNull String uid, String email, String name, int role) {
        this.uid = uid;
        this.email = email;
        this.name = name;
        this.role = role;
        this.createdAt = System.currentTimeMillis();
        this.lastLoginAt = System.currentTimeMillis();
    }

    // Getters and Setters
    @NonNull
    public String getUid() {
        return uid;
    }

    public void setUid(@NonNull String uid) {
        this.uid = uid;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getRole() {
        return role;
    }

    public void setRole(int role) {
        this.role = role;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    public long getLastLoginAt() {
        return lastLoginAt;
    }

    public void setLastLoginAt(long lastLoginAt) {
        this.lastLoginAt = lastLoginAt;
    }

    // Helper methods
    public boolean isAdmin() {
        return UserRoleUtils.isAdmin(role);
    }

    public boolean isUser() {
        return UserRoleUtils.isUser(role);
    }

    public String getRoleName() {
        return UserRoleUtils.getRoleName(role);
    }

    @Override
    public String toString() {
        return "User{" +
                "uid='" + uid + '\'' +
                ", email='" + email + '\'' +
                ", name='" + name + '\'' +
                ", role=" + role +
                ", roleName='" + getRoleName() + '\'' +
                ", createdAt=" + createdAt +
                ", lastLoginAt=" + lastLoginAt +
                '}';
    }
}