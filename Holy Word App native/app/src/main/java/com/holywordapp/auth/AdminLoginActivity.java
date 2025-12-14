package com.holywordapp.auth;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textview.MaterialTextView;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.holywordapp.R;
import com.holywordapp.dashboard.AdminDashboardActivity;
import com.holywordapp.dashboard.UserDashboardActivity;

public class AdminLoginActivity extends AppCompatActivity {
    
    private TextInputEditText emailInput;
    private TextInputEditText passwordInput;
    private MaterialButton loginButton;
    private MaterialTextView forgotPasswordLink;
    private MaterialTextView backToUserDashboardLink;
    
    private FirebaseAuth auth;
    private FirebaseFirestore firestore;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin_login);
        
        // Initialize Firebase
        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
        
        // Initialize views
        initViews();
        setupListeners();
        
        // Check if user is already logged in as admin
        if (auth.getCurrentUser() != null) {
            checkUserRoleAndNavigate();
        }
    }
    
    private void initViews() {
        emailInput = findViewById(R.id.email_input);
        passwordInput = findViewById(R.id.password_input);
        loginButton = findViewById(R.id.login_button);
        forgotPasswordLink = findViewById(R.id.forgot_password_link);
        backToUserDashboardLink = findViewById(R.id.back_to_user_dashboard_link);
    }
    
    private void setupListeners() {
        loginButton.setOnClickListener(v -> attemptLogin());
        
        forgotPasswordLink.setOnClickListener(v -> {
            Intent intent = new Intent(AdminLoginActivity.this, ForgotPasswordActivity.class);
            startActivity(intent);
        });
        
        backToUserDashboardLink.setOnClickListener(v -> {
            finish();
        });
    }
    
    private void attemptLogin() {
        String email = emailInput.getText().toString().trim();
        String password = passwordInput.getText().toString().trim();
        
        // Validate input
        if (TextUtils.isEmpty(email)) {
            emailInput.setError(getString(R.string.enter_email));
            return;
        }
        
        if (TextUtils.isEmpty(password)) {
            passwordInput.setError(getString(R.string.enter_password));
            return;
        }
        
        if (password.length() < 6) {
            passwordInput.setError(getString(R.string.password_too_short));
            return;
        }
        
        // Show loading state
        loginButton.setEnabled(false);
        loginButton.setText(R.string.loading);
        
        // Attempt login
        auth.signInWithEmailAndPassword(email, password)
                .addOnCompleteListener(this, task -> {
                    if (task.isSuccessful()) {
                        // Login successful, check user role
                        checkUserRoleAndNavigate();
                    } else {
                        // Login failed
                        String errorMessage = task.getException() != null ? 
                                task.getException().getMessage() : 
                                getString(R.string.error_occurred);
                        Toast.makeText(AdminLoginActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                        
                        // Reset button state
                        loginButton.setEnabled(true);
                        loginButton.setText("Admin Login");
                    }
                });
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
                            // Admin - proceed to admin dashboard
                            intent = new Intent(AdminLoginActivity.this, AdminDashboardActivity.class);
                            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                            startActivity(intent);
                            finish();
                        } else {
                            // Regular user - show error and sign out
                            auth.signOut();
                            Toast.makeText(AdminLoginActivity.this, 
                                    "Access denied. Admin privileges required.", 
                                    Toast.LENGTH_LONG).show();
                            
                            // Reset button state
                            loginButton.setEnabled(true);
                            loginButton.setText("Admin Login");
                        }
                    } else {
                        // User document doesn't exist - sign out and show error
                        auth.signOut();
                        Toast.makeText(AdminLoginActivity.this, 
                                "User not found. Please contact administrator.", 
                                Toast.LENGTH_LONG).show();
                        
                        // Reset button state
                        loginButton.setEnabled(true);
                        loginButton.setText("Admin Login");
                    }
                })
                .addOnFailureListener(e -> {
                    Toast.makeText(AdminLoginActivity.this, R.string.error_occurred, Toast.LENGTH_LONG).show();
                    loginButton.setEnabled(true);
                    loginButton.setText("Admin Login");
                });
    }
}


