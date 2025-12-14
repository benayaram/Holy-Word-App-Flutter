package com.holywordapp.auth;

import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textview.MaterialTextView;
import com.google.firebase.auth.FirebaseAuth;
import com.holywordapp.R;

public class ForgotPasswordActivity extends AppCompatActivity {
    
    private TextInputEditText emailInput;
    private MaterialButton resetButton;
    private MaterialTextView backToLoginLink;
    
    private FirebaseAuth auth;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_forgot_password);
        
        // Initialize Firebase
        auth = FirebaseAuth.getInstance();
        
        // Initialize views
        initViews();
        setupListeners();
    }
    
    private void initViews() {
        emailInput = findViewById(R.id.email_input);
        resetButton = findViewById(R.id.reset_button);
        backToLoginLink = findViewById(R.id.back_to_login_link);
    }
    
    private void setupListeners() {
        resetButton.setOnClickListener(v -> attemptPasswordReset());
        
        backToLoginLink.setOnClickListener(v -> {
            finish();
        });
    }
    
    private void attemptPasswordReset() {
        String email = emailInput.getText().toString().trim();
        
        // Validate input
        if (TextUtils.isEmpty(email)) {
            emailInput.setError(getString(R.string.enter_email));
            return;
        }
        
        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailInput.setError(getString(R.string.invalid_email));
            return;
        }
        
        // Show loading state
        resetButton.setEnabled(false);
        resetButton.setText(R.string.loading);
        
        // Send password reset email
        auth.sendPasswordResetEmail(email)
                .addOnCompleteListener(task -> {
                    if (task.isSuccessful()) {
                        Toast.makeText(ForgotPasswordActivity.this, 
                                "Password reset email sent to " + email, 
                                Toast.LENGTH_LONG).show();
                        finish();
                    } else {
                        String errorMessage = task.getException() != null ? 
                                task.getException().getMessage() : 
                                getString(R.string.error_occurred);
                        Toast.makeText(ForgotPasswordActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                        
                        // Reset button state
                        resetButton.setEnabled(true);
                        resetButton.setText("Send Reset Email");
                    }
                });
    }
}