package com.holywordapp.dashboard;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.holywordapp.utils.LanguageManager;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.navigation.NavigationBarView;
import com.holywordapp.R;
import com.holywordapp.auth.AdminLoginActivity;
import com.holywordapp.BibleActivity;
import com.holywordapp.AudioBibleActivity;
import com.holywordapp.SettingsActivity;
import com.holywordapp.fragments.PersonalDevotionalFragment;
import com.holywordapp.fragments.BibleStudyToolsFragment;
import com.holywordapp.fragments.WorshipMusicFragment;
import com.holywordapp.fragments.SermonsTeachingsFragment;
import com.holywordapp.fragments.CommunityChurchFragment;

public class UserDashboardActivity extends AppCompatActivity {

    private BottomNavigationView bottomNavigationView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Apply saved language
        LanguageManager.applySavedLanguage(this);
        
        setContentView(R.layout.activity_user_dashboard);

        // Initialize views
        initViews();
        setupListeners();
        
        // Set default fragment
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.fragment_container, new PersonalDevotionalFragment())
                    .commit();
        }
    }

    private void initViews() {
        bottomNavigationView = findViewById(R.id.bottom_navigation);
    }

    private void setupListeners() {
        bottomNavigationView.setOnItemSelectedListener(item -> {
            Fragment selectedFragment = null;
            
            int itemId = item.getItemId();
            if (itemId == R.id.nav_personal_devotional) {
                selectedFragment = new PersonalDevotionalFragment();
            } else if (itemId == R.id.nav_bible_study_tools) {
                selectedFragment = new BibleStudyToolsFragment();
            } else if (itemId == R.id.nav_worship_music) {
                selectedFragment = new WorshipMusicFragment();
            } else if (itemId == R.id.nav_sermons_teachings) {
                selectedFragment = new SermonsTeachingsFragment();
            } else if (itemId == R.id.nav_community_church) {
                selectedFragment = new CommunityChurchFragment();
            }
            
            if (selectedFragment != null) {
                getSupportFragmentManager().beginTransaction()
                        .replace(R.id.fragment_container, selectedFragment)
                        .commit();
                return true;
            }
            
            return false;
        });
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
        Intent intent = new Intent(UserDashboardActivity.this, SettingsActivity.class);
        startActivity(intent);
    }

} 