package com.holywordapp;

import android.os.Bundle;
import android.widget.CompoundButton;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.google.android.material.switchmaterial.SwitchMaterial;
import com.holywordapp.utils.LanguageManager;

public class SettingsActivity extends AppCompatActivity {

    private SwitchMaterial languageToggle;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Apply saved language
        LanguageManager.applySavedLanguage(this);
        
        setContentView(R.layout.activity_settings);

        // Setup toolbar
        setupToolbar();
        
        // Initialize views
        initViews();
        
        // Setup listeners
        setupListeners();
        
        // Set initial toggle state
        setInitialToggleState();
    }

    private void setupToolbar() {
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
            getSupportActionBar().setTitle(R.string.settings);
        }
    }

    private void initViews() {
        languageToggle = findViewById(R.id.language_toggle_switch);
    }

    private void setupListeners() {
        languageToggle.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // isChecked = true means Telugu, false means English
                String newLang = isChecked ? "te" : "en";
                String currentLang = LanguageManager.getCurrentLanguage(SettingsActivity.this);
                
                // Only change if it's actually different
                if (!newLang.equals(currentLang)) {
                    // Apply new language
                    LanguageManager.setLanguage(SettingsActivity.this, newLang);
                    
                    // Show confirmation message
                    String message = newLang.equals("en") ? 
                        getString(R.string.language_changed) : 
                        getString(R.string.language_changed_telugu);
                    Toast.makeText(SettingsActivity.this, message, Toast.LENGTH_SHORT).show();
                    
                    // Recreate activity to apply language change
                    recreate();
                }
            }
        });
    }

    private void setInitialToggleState() {
        String currentLang = LanguageManager.getCurrentLanguage(this);
        // Set toggle: true for Telugu, false for English
        languageToggle.setChecked(currentLang.equals("te"));
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}
