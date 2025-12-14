package com.holywordapp.dashboard;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;

import com.holywordapp.utils.LanguageManager;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.firebase.auth.FirebaseAuth;
import com.holywordapp.R;
import com.holywordapp.SettingsActivity;

public class AdminDashboardActivity extends AppCompatActivity {

    private MaterialButton logoutButton;
    private FirebaseAuth auth;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Apply saved language
        LanguageManager.applySavedLanguage(this);
        
        setContentView(R.layout.activity_admin_dashboard);

        // Initialize Firebase Auth
        auth = FirebaseAuth.getInstance();

        // Initialize views
        initViews();
        setupListeners();
    }

    private void initViews() {
        logoutButton = findViewById(R.id.logout_button);
    }

    private void setupListeners() {
        logoutButton.setOnClickListener(v -> showLogoutConfirmation());
    }

    private void showLogoutConfirmation() {
        new AlertDialog.Builder(this)
                .setTitle("Logout")
                .setMessage("Are you sure you want to logout?")
                .setPositiveButton("Yes", (dialog, which) -> performLogout())
                .setNegativeButton("No", null)
                .show();
    }

    private void performLogout() {
        // Sign out from Firebase Auth
        auth.signOut();
        
        // Show logout message
        Toast.makeText(this, "Logged out successfully", Toast.LENGTH_SHORT).show();
        
        // Navigate to user dashboard
        Intent intent = new Intent(AdminDashboardActivity.this, com.holywordapp.dashboard.UserDashboardActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.action_settings) {
            openSettings();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void openSettings() {
        Intent intent = new Intent(AdminDashboardActivity.this, SettingsActivity.class);
        startActivity(intent);
    }
} 