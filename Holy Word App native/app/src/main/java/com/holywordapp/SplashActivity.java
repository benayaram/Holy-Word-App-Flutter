package com.holywordapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import com.holywordapp.utils.LanguageManager;

import androidx.appcompat.app.AppCompatActivity;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.holywordapp.auth.LoginActivity;
import com.holywordapp.dashboard.AdminDashboardActivity;
import com.holywordapp.dashboard.UserDashboardActivity;
import com.holywordapp.onboarding.OnboardingActivity;

public class SplashActivity extends AppCompatActivity {
    
    private static final int SPLASH_DELAY = 2000; // 2 seconds
    private FirebaseAuth auth;
    private FirebaseFirestore firestore;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Apply saved language before setting content view
        LanguageManager.applySavedLanguage(this);
        
        setContentView(R.layout.activity_splash);

        // Initialize Firebase
        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();

        // Start splash timer
        new Handler(Looper.getMainLooper()).postDelayed(this::checkAuthAndNavigate, SPLASH_DELAY);
    }
    
    private void checkAuthAndNavigate() {
        // Check if this is the first time user is opening the app
        if (isFirstTimeUser()) {
            navigateToOnboarding();
        } else {
            // Go directly to user dashboard without authentication
            navigateToUserDashboard();
        }
    }
    
    private boolean isFirstTimeUser() {
        SharedPreferences sharedPreferences = getSharedPreferences("app_prefs", MODE_PRIVATE);
        return !sharedPreferences.getBoolean("onboarding_completed", false);
    }
    
    private void navigateToOnboarding() {
        Intent intent = new Intent(SplashActivity.this, OnboardingActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }
    
    private void checkUserRoleAndNavigate() {
        String uid = auth.getCurrentUser().getUid();
        
        firestore.collection("users").document(uid)
                .get()
                .addOnSuccessListener(documentSnapshot -> {
                    if (documentSnapshot.exists()) {
                        Integer role = documentSnapshot.getLong("role").intValue();
                        
                        Intent intent;
                        if (role == 0) {
                            // Admin
                            intent = new Intent(SplashActivity.this, AdminDashboardActivity.class);
                        } else {
                            // User
                            intent = new Intent(SplashActivity.this, UserDashboardActivity.class);
                        }
                        
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                        startActivity(intent);
                        finish();
                    } else {
                        // User document doesn't exist, create default user
                        createDefaultUser(uid);
                    }
                })
                .addOnFailureListener(e -> {
                    // If there's an error, go to user dashboard
                    navigateToUserDashboard();
                });
    }
    
    private void createDefaultUser(String uid) {
        String email = auth.getCurrentUser().getEmail();
        String name = auth.getCurrentUser().getDisplayName();
        if (name == null || name.isEmpty()) {
            name = email != null ? email.split("@")[0] : "User";
        }
        
        // Create user data map with only the fields we want to save to Firestore
        java.util.Map<String, Object> userData = com.holywordapp.utils.UserRoleUtils.createUserDataMap(uid, email, name);
        
        firestore.collection("users").document(uid)
                .set(userData)
                .addOnSuccessListener(aVoid -> {
                    Intent intent = new Intent(SplashActivity.this, UserDashboardActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                })
                .addOnFailureListener(e -> {
                    // If there's an error, go to user dashboard
                    navigateToUserDashboard();
                });
    }
    
    private void navigateToUserDashboard() {
        Intent intent = new Intent(SplashActivity.this, UserDashboardActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }
}