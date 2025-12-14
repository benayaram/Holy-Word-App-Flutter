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
import com.holywordapp.data.entity.User;
import com.holywordapp.dashboard.UserDashboardActivity;
import com.holywordapp.utils.UserRoleUtils;

public class RegisterActivity extends AppCompatActivity {
    
    private TextInputEditText nameInput;
    private TextInputEditText emailInput;
    private TextInputEditText passwordInput;
    private TextInputEditText confirmPasswordInput;
    private MaterialButton registerButton;
    private MaterialTextView loginLink;
    
    private FirebaseAuth auth;
    private FirebaseFirestore firestore;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);
        
        // Initialize Firebase
        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
        
        // Initialize views
        initViews();
        setupListeners();
    }
    
    private void initViews() {
        nameInput = findViewById(R.id.name_input);
        emailInput = findViewById(R.id.email_input);
        passwordInput = findViewById(R.id.password_input);
        confirmPasswordInput = findViewById(R.id.confirm_password_input);
        registerButton = findViewById(R.id.register_button);
        loginLink = findViewById(R.id.login_link);
    }
    
    private void setupListeners() {
        registerButton.setOnClickListener(v -> attemptRegister());
        
        loginLink.setOnClickListener(v -> {
            Intent intent = new Intent(RegisterActivity.this, LoginActivity.class);
            startActivity(intent);
            finish();
        });
    }
    
    private void attemptRegister() {
        String name = nameInput.getText().toString().trim();
        String email = emailInput.getText().toString().trim();
        String password = passwordInput.getText().toString().trim();
        String confirmPassword = confirmPasswordInput.getText().toString().trim();
        
        // Validate input
        if (TextUtils.isEmpty(name)) {
            nameInput.setError("Please enter your name");
            return;
        }
        
        if (TextUtils.isEmpty(email)) {
            emailInput.setError(getString(R.string.enter_email));
            return;
        }
        
        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailInput.setError(getString(R.string.invalid_email));
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
        
        if (!password.equals(confirmPassword)) {
            confirmPasswordInput.setError(getString(R.string.password_mismatch));
            return;
        }
        
        // Show loading state
        registerButton.setEnabled(false);
        registerButton.setText(R.string.loading);
        
        // Attempt registration
        auth.createUserWithEmailAndPassword(email, password)
                .addOnCompleteListener(this, task -> {
                    if (task.isSuccessful()) {
                        // Registration successful, create user document
                        String uid = auth.getCurrentUser().getUid();
                        createUserDocument(uid, name, email);
                    } else {
                        // Registration failed
                        String errorMessage = task.getException() != null ? 
                                task.getException().getMessage() : 
                                getString(R.string.error_occurred);
                        Toast.makeText(RegisterActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                        
                        // Reset button state
                        registerButton.setEnabled(true);
                        registerButton.setText(R.string.register);
                    }
                });
    }
    
    private void createUserDocument(String uid, String name, String email) {
        // Create user data map with only the fields we want to save to Firestore
        java.util.Map<String, Object> userData = UserRoleUtils.createUserDataMap(uid, email, name);
        
        // Save only the specific fields to Firestore
        firestore.collection("users").document(uid)
                .set(userData)
                .addOnSuccessListener(aVoid -> {
                    Toast.makeText(RegisterActivity.this, R.string.register_success, Toast.LENGTH_SHORT).show();
                    
                    // Navigate to user dashboard
                    Intent intent = new Intent(RegisterActivity.this, UserDashboardActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                })
                .addOnFailureListener(e -> {
                    Toast.makeText(RegisterActivity.this, R.string.error_occurred, Toast.LENGTH_LONG).show();
                    registerButton.setEnabled(true);
                    registerButton.setText(R.string.register);
                });
    }
}