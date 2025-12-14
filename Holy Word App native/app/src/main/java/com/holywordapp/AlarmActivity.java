package com.holywordapp;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.MediaPlayer;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.holywordapp.KJVBibleDBHelper;

import java.util.Calendar;
import java.util.Locale;
import java.util.Random;

public class AlarmActivity extends AppCompatActivity {
    
    private TextView alarmNameText;
    private TextView alarmTimeText;
    private TextView bibleVerseText;
    private TextView bibleReferenceText;
    private Button snoozeButton;
    private Button stopButton;
    private MediaPlayer alarmPlayer;
    private Handler handler;
    private Runnable stopAlarmRunnable;
    
    private String reminderName;
    private String reminderTime;
    private int snoozeMinutes = 5;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Make screen turn on and stay on
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON |
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON |
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD);
        
        setContentView(R.layout.activity_alarm);
        
        // Get alarm data from intent
        Intent intent = getIntent();
        reminderName = intent.getStringExtra("reminder_name");
        reminderTime = intent.getStringExtra("reminder_time");
        
        if (reminderName == null) {
            reminderName = "Prayer Time";
        }
        
        initViews();
        setupAlarm();
        loadBibleVerse();
    }
    
    private void initViews() {
        alarmNameText = findViewById(R.id.alarm_name_text);
        alarmTimeText = findViewById(R.id.alarm_time_text);
        bibleVerseText = findViewById(R.id.bible_verse_text);
        bibleReferenceText = findViewById(R.id.bible_reference_text);
        snoozeButton = findViewById(R.id.snooze_button);
        stopButton = findViewById(R.id.stop_button);
        
        // Set alarm info
        alarmNameText.setText(reminderName);
        alarmTimeText.setText(reminderTime);
        
        // Setup buttons
        snoozeButton.setOnClickListener(v -> snoozeAlarm());
        stopButton.setOnClickListener(v -> stopAlarm());
        
        handler = new Handler(Looper.getMainLooper());
    }
    
    private void setupAlarm() {
        try {
            // Get default alarm sound
            Uri alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
            if (alarmSound == null) {
                alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
            }
            
            // Create and start alarm sound
            alarmPlayer = new MediaPlayer();
            alarmPlayer.setDataSource(this, alarmSound);
            alarmPlayer.setLooping(true);
            alarmPlayer.setVolume(1.0f, 1.0f);
            alarmPlayer.prepare();
            alarmPlayer.start();
            
            Log.d("AlarmActivity", "Alarm sound started");
            
            // Auto-stop alarm after 5 minutes if not manually stopped
            stopAlarmRunnable = () -> {
                if (alarmPlayer != null && alarmPlayer.isPlaying()) {
                    stopAlarm();
                }
            };
            handler.postDelayed(stopAlarmRunnable, 5 * 60 * 1000); // 5 minutes
            
        } catch (Exception e) {
            Log.e("AlarmActivity", "Error setting up alarm sound", e);
            Toast.makeText(this, "Error playing alarm sound", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void loadBibleVerse() {
        try {
            // Check current language setting
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
            String currentLanguage = prefs.getString("language", "en");
            boolean isTelugu = "te".equals(currentLanguage);
            
            KJVBibleDBHelper dbHelper = new KJVBibleDBHelper(this);

            // Get a random verse from popular books
            String[] popularBooks = {"John", "Matthew", "Psalms", "Proverbs", "Romans", "Ephesians", "Philippians", "Colossians"};
            Random random = new Random();
            String randomBook = popularBooks[random.nextInt(popularBooks.length)];

            // Get a random chapter (1-10 for most books)
            int randomChapter = random.nextInt(10) + 1;

            // Get verses for the chapter
            java.util.List<com.holywordapp.Verse> verses = dbHelper.getVersesForChapterRange(randomBook, randomChapter);

            if (verses != null && !verses.isEmpty()) {
                // Get a random verse from the chapter
                com.holywordapp.Verse randomVerse = verses.get(random.nextInt(verses.size()));

                if (isTelugu) {
                    // Try to get Telugu verse if available
                    String teluguVerse = getTeluguVerse(randomBook, randomChapter, randomVerse.getVerseNumber());
                    if (teluguVerse != null && !teluguVerse.isEmpty()) {
                        bibleVerseText.setText(teluguVerse);
                        bibleReferenceText.setText(getTeluguReference(randomBook) + " " + randomChapter + ":" + randomVerse.getVerseNumber());
                    } else {
                        // Fallback to English if Telugu not available
                        bibleVerseText.setText(randomVerse.getVerseText());
                        bibleReferenceText.setText(randomBook + " " + randomChapter + ":" + randomVerse.getVerseNumber());
                    }
                } else {
                    // English verse
                    bibleVerseText.setText(randomVerse.getVerseText());
                    bibleReferenceText.setText(randomBook + " " + randomChapter + ":" + randomVerse.getVerseNumber());
                }
            } else {
                // Fallback verses based on language
                if (isTelugu) {
                    bibleVerseText.setText("దేవుడు లోకమును ఎంత ప్రేమించెనో, తన ఏకైక కుమారుడైన యేసుక్రీస్తును ఇచ్చెను. అతనిమీద విశ్వాసముంచువాడెవడును నశింపక నిత్యజీవమును పొందును.");
                    bibleReferenceText.setText("యోహాను 3:16");
                } else {
                    bibleVerseText.setText("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.");
                    bibleReferenceText.setText("John 3:16");
                }
            }

            dbHelper.close();

        } catch (Exception e) {
            Log.e("AlarmActivity", "Error loading bible verse", e);
            // Fallback verses based on language
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
            String currentLanguage = prefs.getString("language", "en");
            boolean isTelugu = "te".equals(currentLanguage);
            
            if (isTelugu) {
                bibleVerseText.setText("దేవుడు లోకమును ఎంత ప్రేమించెనో, తన ఏకైక కుమారుడైన యేసుక్రీస్తును ఇచ్చెను. అతనిమీద విశ్వాసముంచువాడెవడును నశింపక నిత్యజీవమును పొందును.");
                bibleReferenceText.setText("యోహాను 3:16");
            } else {
                bibleVerseText.setText("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.");
                bibleReferenceText.setText("John 3:16");
            }
        }
    }
    
    private String getTeluguVerse(String book, int chapter, int verse) {
        // This would ideally load from a Telugu Bible database
        // For now, return some common Telugu verses
        String[] teluguVerses = {
            "దేవుడు లోకమును ఎంత ప్రేమించెనో, తన ఏకైక కుమారుడైన యేసుక్రీస్తును ఇచ్చెను. అతనిమీద విశ్వాసముంచువాడెవడును నశింపక నిత్యజీవమును పొందును.",
            "యేసు నాకు మార్గమును, సత్యమును, జీవమును. నా ద్వారానే తప్ప యెవడును తండ్రియొద్దకు రాడు.",
            "నేను నిన్ను ప్రేమించుచున్నాను, నీవు నన్ను ప్రేమించుము.",
            "దేవుడు మన ప్రేమకు ముందుగా మనలను ప్రేమించెను.",
            "యేసు క్రీస్తు నిన్ను ప్రేమించుచున్నాడు, నీవు నన్ను ప్రేమించుము."
        };
        Random random = new Random();
        return teluguVerses[random.nextInt(teluguVerses.length)];
    }
    
    private String getTeluguReference(String book) {
        // Convert English book names to Telugu
        switch (book) {
            case "John": return "యోహాను";
            case "Matthew": return "మత్తయి";
            case "Psalms": return "కీర్తనలు";
            case "Proverbs": return "సామెతలు";
            case "Romans": return "రోమీయులకు";
            case "Ephesians": return "ఎఫెసీయులకు";
            case "Philippians": return "ఫిలిప్పీయులకు";
            case "Colossians": return "కొలస్సయులకు";
            default: return book;
        }
    }
    
    private void snoozeAlarm() {
        try {
            // Stop current alarm
            stopAlarmSound();
            
            // Set snooze alarm
            Calendar snoozeCalendar = Calendar.getInstance();
            snoozeCalendar.add(Calendar.MINUTE, snoozeMinutes);
            
            Intent snoozeIntent = new Intent(this, AlarmActivity.class);
            snoozeIntent.putExtra("reminder_name", reminderName);
            snoozeIntent.putExtra("reminder_time", reminderTime);
            
            android.app.PendingIntent snoozePendingIntent = android.app.PendingIntent.getActivity(this, 
                2000 + snoozeMinutes, snoozeIntent, android.app.PendingIntent.FLAG_UPDATE_CURRENT | android.app.PendingIntent.FLAG_IMMUTABLE);
            
            android.app.AlarmManager alarmManager = (android.app.AlarmManager) getSystemService(ALARM_SERVICE);
            alarmManager.set(android.app.AlarmManager.RTC_WAKEUP, snoozeCalendar.getTimeInMillis(), snoozePendingIntent);
            
            Toast.makeText(this, "Alarm snoozed for " + snoozeMinutes + " minutes", Toast.LENGTH_SHORT).show();
            
            Log.d("AlarmActivity", "Alarm snoozed for " + snoozeMinutes + " minutes");
            
            finish();
            
        } catch (Exception e) {
            Log.e("AlarmActivity", "Error snoozing alarm", e);
            Toast.makeText(this, "Error snoozing alarm", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void stopAlarm() {
        stopAlarmSound();
        Toast.makeText(this, "Alarm stopped", Toast.LENGTH_SHORT).show();
        Log.d("AlarmActivity", "Alarm stopped by user");
        finish();
    }
    
    private void stopAlarmSound() {
        if (alarmPlayer != null) {
            try {
                alarmPlayer.stop();
                alarmPlayer.release();
                alarmPlayer = null;
            } catch (Exception e) {
                Log.e("AlarmActivity", "Error stopping alarm sound", e);
            }
        }
        
        // Remove auto-stop runnable
        if (stopAlarmRunnable != null) {
            handler.removeCallbacks(stopAlarmRunnable);
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopAlarmSound();
    }
    
    @Override
    public void onBackPressed() {
        // Don't allow back button to dismiss alarm
        // User must use snooze or stop buttons
    }
}
