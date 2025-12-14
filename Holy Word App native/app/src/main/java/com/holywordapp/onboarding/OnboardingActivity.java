package com.holywordapp.onboarding;

import android.animation.ObjectAnimator;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RadioButton;

import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager2.widget.ViewPager2;

import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;
import com.holywordapp.R;
import com.holywordapp.dashboard.UserDashboardActivity;
import com.holywordapp.utils.LanguageManager;

public class OnboardingActivity extends AppCompatActivity {

    private ViewPager2 viewPager;
    private ProgressBar progressBar;
    private Button nextButton;
    private Button skipButton;
    private OnboardingAdapter adapter;
    private SharedPreferences sharedPreferences;
    private String selectedLanguage = "en";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_onboarding);

        // Initialize SharedPreferences
        sharedPreferences = getSharedPreferences("app_prefs", MODE_PRIVATE);

        // Initialize views
        initViews();
        setupViewPager();
        setupListeners();
    }

    private void initViews() {
        viewPager = findViewById(R.id.view_pager);
        progressBar = findViewById(R.id.progress_bar);
        nextButton = findViewById(R.id.next_button);
        skipButton = findViewById(R.id.skip_button);
    }

    private void setupViewPager() {
        adapter = new OnboardingAdapter(this);
        viewPager.setAdapter(adapter);

        // Listen to page changes
        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                updateButtonText(position);
                updateProgressBar(position);
            }
        });
    }


    private void updateProgressBar(int position) {
        int progress = ((position + 1) * 100) / adapter.getItemCount();
        ObjectAnimator animator = ObjectAnimator.ofInt(progressBar, "progress", progressBar.getProgress(), progress);
        animator.setDuration(300);
        animator.setInterpolator(new DecelerateInterpolator());
        animator.start();
    }

    private void setupListeners() {
        nextButton.setOnClickListener(v -> {
            int currentItem = viewPager.getCurrentItem();
            if (currentItem < adapter.getItemCount() - 1) {
                viewPager.setCurrentItem(currentItem + 1);
            } else {
                completeOnboarding();
            }
        });

        skipButton.setOnClickListener(v -> completeOnboarding());
    }

    private void updateButtonText(int position) {
        if (position == adapter.getItemCount() - 1) {
            nextButton.setText(getString(R.string.start_dashboard));
            skipButton.setVisibility(View.GONE);
        } else {
            nextButton.setText(getString(R.string.continue_text));
            skipButton.setVisibility(View.VISIBLE);
        }
        // Ensure buttons are all-caps disabled for readability in Telugu
        nextButton.setAllCaps(false);
        skipButton.setAllCaps(false);
    }

    private void completeOnboarding() {
        // Save selected language preference
        String selectedLanguage = getSelectedLanguage();
        LanguageManager.setLanguage(this, selectedLanguage);

        // Mark onboarding as completed
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putBoolean("onboarding_completed", true);
        editor.putString("selected_language", selectedLanguage);
        editor.apply();

        // Navigate to user dashboard
        Intent intent = new Intent(OnboardingActivity.this, UserDashboardActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }
    
    private String getSelectedLanguage() {
        return selectedLanguage;
    }
    
    public void setSelectedLanguage(String languageCode) {
        this.selectedLanguage = languageCode;
        applyLanguage(languageCode);
        // Update adapter with new language
        adapter.updateScreens();
        adapter.notifyDataSetChanged();
        // Refresh current button texts to reflect new locale
        updateButtonText(viewPager.getCurrentItem());
    }
    
    private void applyLanguage(String languageCode) {
        Configuration config = new Configuration(getResources().getConfiguration());
        if (languageCode.equals("te")) {
            config.locale = new java.util.Locale("te");
        } else {
            config.locale = java.util.Locale.ENGLISH;
        }
        getResources().updateConfiguration(config, getResources().getDisplayMetrics());
    }
}
