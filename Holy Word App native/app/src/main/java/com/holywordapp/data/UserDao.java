package com.holywordapp.data;

import androidx.lifecycle.LiveData;
import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.Update;

import com.holywordapp.data.entity.User;

import java.util.List;

/**
 * Data Access Object for User entity
 * Provides methods for database operations on users
 */
@Dao
public interface UserDao {

    /**
     * Insert a new user
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertUser(User user);

    /**
     * Update an existing user
     */
    @Update
    void updateUser(User user);

    /**
     * Delete a user
     */
    @Delete
    void deleteUser(User user);

    /**
     * Get user by UID
     */
    @Query("SELECT * FROM users WHERE uid = :uid")
    LiveData<User> getUserByUid(String uid);

    /**
     * Get user by UID (synchronous)
     */
    @Query("SELECT * FROM users WHERE uid = :uid")
    User getUserByUidSync(String uid);

    /**
     * Get user by email
     */
    @Query("SELECT * FROM users WHERE email = :email")
    LiveData<User> getUserByEmail(String email);

    /**
     * Get all users
     */
    @Query("SELECT * FROM users ORDER BY createdAt DESC")
    LiveData<List<User>> getAllUsers();

    /**
     * Get all admin users
     */
    @Query("SELECT * FROM users WHERE role = 0 ORDER BY createdAt DESC")
    LiveData<List<User>> getAdminUsers();

    /**
     * Get all regular users
     */
    @Query("SELECT * FROM users WHERE role = 1 ORDER BY createdAt DESC")
    LiveData<List<User>> getRegularUsers();

    /**
     * Update last login time
     */
    @Query("UPDATE users SET lastLoginAt = :timestamp WHERE uid = :uid")
    void updateLastLogin(String uid, long timestamp);

    /**
     * Check if user exists
     */
    @Query("SELECT COUNT(*) FROM users WHERE uid = :uid")
    int userExists(String uid);

    /**
     * Delete all users
     */
    @Query("DELETE FROM users")
    void deleteAllUsers();
}