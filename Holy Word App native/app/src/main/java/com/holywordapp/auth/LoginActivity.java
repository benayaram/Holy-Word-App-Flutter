package com.holywordapp.auth;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textview.MaterialTextView;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.holywordapp.R;
import com.holywordapp.data.entity.User;
import com.holywordapp.dashboard.AdminDashboardActivity;
import com.holywordapp.dashboard.UserDashboardActivity;
import com.holywordapp.utils.UserRoleUtils;

public class LoginActivity extends AppCompatActivity {
    
    private TextInputEditText emailInput;
    private TextInputEditText passwordInput;
    private MaterialButton loginButton;
    private MaterialTextView registerLink;
    private MaterialTextView forgotPasswordLink;
    
    private FirebaseAuth auth;
    private FirebaseFirestore firestore;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        
        // Initialize Firebase
        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
        
        // Initialize views
        initViews();
        setupListeners();
        
        // Check if user is already logged in
        if (auth.getCurrentUser() != null) {
            checkUserRoleAndNavigate();
        }
    }
    
    private void initViews() {
        emailInput = findViewById(R.id.email_input);
        passwordInput = findViewById(R.id.password_input);
        loginButton = findViewById(R.id.login_button);
        registerLink = findViewById(R.id.register_link);
        forgotPasswordLink = findViewById(R.id.forgot_password_link);
    }
    
    private void setupListeners() {
        loginButton.setOnClickListener(v -> attemptLogin());
        
        registerLink.setOnClickListener(v -> {
            Intent intent = new Intent(LoginActivity.this, RegisterActivity.class);
            startActivity(intent);
        });
        
        forgotPasswordLink.setOnClickListener(v -> {
            Intent intent = new Intent(LoginActivity.this, ForgotPasswordActivity.class);
            startActivity(intent);
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
                        Toast.makeText(LoginActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                        
                        // Reset button state
                        loginButton.setEnabled(true);
                        loginButton.setText(R.string.login);
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
                            // Admin
                            intent = new Intent(LoginActivity.this, AdminDashboardActivity.class);
                        } else {
                            // User
                            intent = new Intent(LoginActivity.this, UserDashboardActivity.class);
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
                    Toast.makeText(LoginActivity.this, R.string.error_occurred, Toast.LENGTH_LONG).show();
                    loginButton.setEnabled(true);
                    loginButton.setText(R.string.login);
                });
    }
    
    private void createDefaultUser(String uid) {
        String email = auth.getCurrentUser().getEmail();
        String name = auth.getCurrentUser().getDisplayName();
        if (name == null || name.isEmpty()) {
            name = email != null ? email.split("@")[0] : "User";
        }
        
        // Create user data map with only the fields we want to save to Firestore
        java.util.Map<String, Object> userData = UserRoleUtils.createUserDataMap(uid, email, name);
        
        firestore.collection("users").document(uid)
                .set(userData)
                .addOnSuccessListener(aVoid -> {
                    Intent intent = new Intent(LoginActivity.this, UserDashboardActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                })
                .addOnFailureListener(e -> {
                    Toast.makeText(LoginActivity.this, R.string.error_occurred, Toast.LENGTH_LONG).show();
                    loginButton.setEnabled(true);
                    loginButton.setText(R.string.login);
                });
    }
} 