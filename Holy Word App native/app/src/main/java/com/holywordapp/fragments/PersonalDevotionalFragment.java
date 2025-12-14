package com.holywordapp.fragments;

import android.os.Bundle;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.ImageButton;
import android.widget.ImageView;
import androidx.appcompat.app.AlertDialog;
import android.widget.Toast;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.graphics.Typeface;
import android.util.Log;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import android.media.MediaPlayer;
import android.os.Handler;
import android.widget.SeekBar;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import android.app.AlarmManager;
import android.app.TimePickerDialog;
import android.widget.TimePicker;
import android.widget.EditText;
import android.text.TextUtils;
import java.text.SimpleDateFormat;
import com.holywordapp.SavedAlarmsActivity;
import com.holywordapp.PrayerReminderReceiver;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.core.content.res.ResourcesCompat;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.progressindicator.CircularProgressIndicator;
import com.holywordapp.R;

import org.json.JSONObject;
import org.json.JSONException;
import org.json.JSONArray;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class PersonalDevotionalFragment extends Fragment {

    private TextView verseText;
    private TextView verseReference;
    private MaterialButton teluguLangButton;
    private MaterialButton englishLangButton;
    private MaterialButton shareButton;
    private MaterialButton audioDevotionalsButton;
    private MaterialButton prayerReminderButton; // Added for prayer reminder feature
    private MaterialButton manageReminderButton; // Added for managing reminders
    private MaterialButton savedAlarmsButton; // Added for saved alarms
    private MaterialCardView prayerReminderCard; // Added for prayer reminder card
    private TextView prayerReminderStatus; // Added for prayer reminder status
    private TextView readFullLink;
    private MaterialCardView verseOfDayCard;
    private CircularProgressIndicator loadingIndicator;
    private ImageButton settingsButton;
    private ImageView logoButton;
    private ExecutorService executorService;
    private boolean isTeluguSelected = true;
    
    // Audio Devotionals
    private MediaPlayer mediaPlayer;
    private Handler audioHandler;
    private Runnable audioRunnable;
    private AlertDialog audioDialog;
    private SeekBar audioProgress;
    private TextView currentTime, totalTime, audioTitle, audioDate, audioError;
    private ImageButton playPauseButton, rewindButton, forwardButton, closeButton;
    private CircularProgressIndicator audioLoading;
    private boolean isPlaying = false;
    private int currentPosition = 0;
    
    // Notification
    private NotificationManager notificationManager;
    private static final String CHANNEL_ID = "audio_devotionals_channel";
    private static final int NOTIFICATION_ID = 1001;
    
    // Prayer Reminder
    private AlarmManager alarmManager;
    private static final String PRAYER_CHANNEL_ID = "prayer_reminders_channel";
    private static final int PRAYER_NOTIFICATION_ID = 2001;
    private static final int PRAYER_ALARM_REQUEST_CODE = 3001;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        Log.d("PersonalDevotional", "=== PersonalDevotionalFragment onCreateView called ===");
        View view = inflater.inflate(R.layout.fragment_personal_devotional, container, false);
        
        initViews(view);
        setupListeners();
        executorService = Executors.newSingleThreadExecutor();
        Log.d("PersonalDevotional", "About to call loadDailyVerses()");
        loadDailyVerses();
        
        // Update prayer reminder status
        updatePrayerReminderStatus();
        
        return view;
    }

    private void initViews(View view) {
        verseText = view.findViewById(R.id.verse_text);
        verseReference = view.findViewById(R.id.verse_reference);
        teluguLangButton = view.findViewById(R.id.telugu_lang_button);
        englishLangButton = view.findViewById(R.id.english_lang_button);
        shareButton = view.findViewById(R.id.share_button);
        audioDevotionalsButton = view.findViewById(R.id.audio_devotionals_button);
        prayerReminderButton = view.findViewById(R.id.prayer_reminder_button);
        manageReminderButton = view.findViewById(R.id.manage_reminder_button);
        savedAlarmsButton = view.findViewById(R.id.saved_alarms_button);
        prayerReminderCard = view.findViewById(R.id.prayer_reminder_card);
        prayerReminderStatus = view.findViewById(R.id.prayer_reminder_status);
        readFullLink = view.findViewById(R.id.read_full_link);
        verseOfDayCard = view.findViewById(R.id.verse_of_day_card);
        loadingIndicator = view.findViewById(R.id.loading_indicator);
        settingsButton = view.findViewById(R.id.settings_button);
        logoButton = view.findViewById(R.id.logo_button);
        
        // Initialize audio handler
        audioHandler = new Handler();
    }

    private void setupListeners() {
        settingsButton.setOnClickListener(v -> showLanguageDialog());
        logoButton.setOnClickListener(v -> {
            // Navigate to Admin Login screen when logo tapped
            if (getContext() != null) {
                Intent intent = new Intent(getContext(), com.holywordapp.auth.AdminLoginActivity.class);
                startActivity(intent);
            }
        });
        
        // Language toggle buttons
        teluguLangButton.setOnClickListener(v -> {
            isTeluguSelected = true;
            updateLanguageButtons();
            updateVerseDisplay();
        });
        
        englishLangButton.setOnClickListener(v -> {
            isTeluguSelected = false;
            updateLanguageButtons();
            updateVerseDisplay();
        });
        
        // Action buttons
        shareButton.setOnClickListener(v -> showShareBottomSheet());
        
        audioDevotionalsButton.setOnClickListener(v -> showAudioDevotionalsDialog());
        prayerReminderButton.setOnClickListener(v -> showPrayerReminderDialog());
        manageReminderButton.setOnClickListener(v -> showManageReminderDialog());
        savedAlarmsButton.setOnClickListener(v -> openSavedAlarms());
        
        readFullLink.setOnClickListener(v -> {
            // TODO: Navigate to full devotional
            Toast.makeText(getContext(), "Full devotional coming soon!", Toast.LENGTH_SHORT).show();
        });
    }
    
    private void showShareBottomSheet() {
        BottomSheetDialog bottomSheetDialog = new BottomSheetDialog(requireContext());
        View bottomSheetView = LayoutInflater.from(requireContext()).inflate(R.layout.bottom_sheet_share, null);
        bottomSheetDialog.setContentView(bottomSheetView);
        
        MaterialButton copyTextButton = bottomSheetView.findViewById(R.id.copy_text_button);
        MaterialButton shareTextButton = bottomSheetView.findViewById(R.id.share_text_button);
        MaterialButton shareImageButton = bottomSheetView.findViewById(R.id.share_image_button);
        
        copyTextButton.setOnClickListener(v -> {
            copyVerseToClipboard();
            bottomSheetDialog.dismiss();
            Toast.makeText(getContext(), getString(R.string.copy_text), Toast.LENGTH_SHORT).show();
        });
        
        shareTextButton.setOnClickListener(v -> {
            shareVerseAsText();
            bottomSheetDialog.dismiss();
        });
        
        shareImageButton.setOnClickListener(v -> {
            shareVerseAsImage();
            bottomSheetDialog.dismiss();
        });
        
        bottomSheetDialog.show();
    }
    
    private void copyVerseToClipboard() {
        try {
            ClipboardManager clipboard = (ClipboardManager) requireContext().getSystemService(Context.CLIPBOARD_SERVICE);
            String verseContent = getCurrentVerseContent();
            ClipData clip = ClipData.newPlainText("Verse", verseContent);
            clipboard.setPrimaryClip(clip);
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error copying to clipboard", e);
            Toast.makeText(getContext(), "Failed to copy", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void shareVerseAsText() {
        try {
            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType("text/plain");
            String verseContent = getCurrentVerseContent();
            shareIntent.putExtra(Intent.EXTRA_TEXT, verseContent);
            startActivity(Intent.createChooser(shareIntent, getString(R.string.share)));
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error sharing text", e);
            Toast.makeText(getContext(), "Failed to share", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void shareVerseAsImage() {
        try {
            Intent intent = new Intent(getContext(), com.holywordapp.ShareVerseImageActivity.class);
            String verseText = isTeluguSelected ? getCachedTeluguText() : getCachedEnglishText();
            String verseRef = isTeluguSelected ? getCachedTeluguRef() : getCachedEnglishRef();
            
            // Format: "Reference - Verse Text" (as expected by ShareVerseImageActivity)
            String formattedVerse = verseRef + " - " + verseText;
            ArrayList<String> verses = new ArrayList<>();
            verses.add(formattedVerse);
            
            intent.putStringArrayListExtra("VERSES", verses);
            startActivity(intent);
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error sharing image", e);
            Toast.makeText(getContext(), "Failed to share image", Toast.LENGTH_SHORT).show();
        }
    }
    
    private String getCurrentVerseContent() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        String verse, reference;
        if (isTeluguSelected) {
            verse = prefs.getString("cached_telugu_text", "");
            reference = prefs.getString("cached_telugu_ref", "");
        } else {
            verse = prefs.getString("cached_english_text", "");
            reference = prefs.getString("cached_english_ref", "");
        }
        return verse + "\n\n" + reference;
    }
    
    private String getCachedEnglishText() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        return prefs.getString("cached_english_text", "");
    }
    
    private String getCachedEnglishRef() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        return prefs.getString("cached_english_ref", "");
    }
    
    private String getCachedTeluguText() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        return prefs.getString("cached_telugu_text", "");
    }
    
    private String getCachedTeluguRef() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        return prefs.getString("cached_telugu_ref", "");
    }

    private void showLanguageDialog() {
        if (getContext() == null) return;
        String[] languages = new String[]{getString(R.string.language_english), getString(R.string.language_telugu)};
        new AlertDialog.Builder(requireContext())
                .setTitle(getString(R.string.language_settings))
                .setItems(languages, (dialog, which) -> {
                    String code = which == 1 ? "te" : "en";
                    com.holywordapp.utils.LanguageManager.setLanguage(requireContext(), code);
                    if (getActivity() != null) {
                        getActivity().recreate();
                    }
                })
                .setNegativeButton(R.string.cancel, null)
                .show();
    }

    private void updateLanguageButtons() {
        if (isTeluguSelected) {
            teluguLangButton.setBackgroundTintList(getContext().getResources().getColorStateList(R.color.primary));
            teluguLangButton.setTextColor(getContext().getResources().getColor(android.R.color.white));
            englishLangButton.setBackgroundTintList(getContext().getResources().getColorStateList(R.color.background_card));
            englishLangButton.setTextColor(getContext().getResources().getColor(R.color.text_secondary));
        } else {
            englishLangButton.setBackgroundTintList(getContext().getResources().getColorStateList(R.color.primary));
            englishLangButton.setTextColor(getContext().getResources().getColor(android.R.color.white));
            teluguLangButton.setBackgroundTintList(getContext().getResources().getColorStateList(R.color.background_card));
            teluguLangButton.setTextColor(getContext().getResources().getColor(R.color.text_secondary));
        }
    }

    private void updateVerseDisplay() {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            String cachedEnglishText = prefs.getString("cached_english_text", "");
            String cachedEnglishRef = prefs.getString("cached_english_ref", "");
            String cachedTeluguText = prefs.getString("cached_telugu_text", "");
            String cachedTeluguRef = prefs.getString("cached_telugu_ref", "");
            
            if (isTeluguSelected) {
                verseText.setText(cachedTeluguText.isEmpty() ? "దేవుడు లోకాన్ని ఎంతో ప్రేమించాడు. అందుకే తన ఏకైక కుమారుడిని ఇచ్చాడు. అతనిలో నమ్మకముంచే ప్రతి వ్యక్తి నశించకుండా నిత్యజీవాన్ని పొందును." : cachedTeluguText);
                verseReference.setText(cachedTeluguRef.isEmpty() ? "యోహాను 3:16" : cachedTeluguRef);
                
                // Apply Telugu font
                try {
                    Typeface teluguFont = ResourcesCompat.getFont(getContext(), R.font.mandali_regular);
                    verseText.setTypeface(teluguFont);
                    verseReference.setTypeface(teluguFont);
                } catch (Exception e) {
                    Log.w("PersonalDevotional", "Could not load Telugu font", e);
                }
            } else {
                verseText.setText(cachedEnglishText.isEmpty() ? "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life." : cachedEnglishText);
                verseReference.setText(cachedEnglishRef.isEmpty() ? "John 3:16" : cachedEnglishRef);
                
                // Reset to default font
                verseText.setTypeface(null);
                verseReference.setTypeface(null);
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error updating verse display", e);
        }
    }

    private void loadDailyVerses() {
        Log.d("PersonalDevotional", "=== loadDailyVerses() called ===");
        showLoading(true);
        
        // Try to load from cache first
        if (loadFromCache()) {
            Log.d("PersonalDevotional", "Loaded from cache successfully");
            showLoading(false);
            updateLanguageButtons();
            return;
        }
        
        // Fetch from API
        executorService.execute(() -> {
            try {
                Log.d("PersonalDevotional", "Fetching daily verse from API");
                JSONObject verseData = fetchDailyVerseFromAPI();
                if (verseData != null) {
                    Log.d("PersonalDevotional", "Successfully fetched verse from API");
                    updateVersesOnUIThread(verseData);
                } else {
                    Log.e("PersonalDevotional", "Failed to fetch verse from API, trying local file");
                    // Fallback to local file if API fails
                    JSONObject localVerseData = loadDailyVerseFromLocalFile();
                    if (localVerseData != null) {
                        Log.d("PersonalDevotional", "Loaded verse from local file as fallback");
                        updateVersesOnUIThread(localVerseData);
                    } else {
                        Log.e("PersonalDevotional", "Both API and local file failed");
                        showErrorOnUIThread();
                    }
                }
            } catch (Exception e) {
                Log.e("PersonalDevotional", "Error loading daily verses", e);
                showErrorOnUIThread();
            }
        });
    }
    
    private JSONObject fetchDailyVerseFromAPI() {
        try {
            URL url = new URL("https://holyword.vercel.app/api/daily-verse");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(15000);
            
            // Add headers
            connection.setRequestProperty("Accept", "application/json");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("User-Agent", "HolyWordApp/1.0");
            
            int responseCode = connection.getResponseCode();
            Log.d("PersonalDevotional", "API Response Code: " + responseCode);
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                
                String responseString = response.toString();
                Log.d("PersonalDevotional", "API Response: " + responseString);
                
                JSONObject jsonResponse = new JSONObject(responseString);
                return jsonResponse;
            } else {
                Log.e("PersonalDevotional", "API returned error code: " + responseCode);
                return null;
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error fetching daily verse from API", e);
            return null;
        }
    }
    
    private JSONObject loadDailyVerseFromLocalFile() {
        try {
            // Read the JSON file from assets
            InputStream inputStream = getContext().getAssets().open("daily verse.json");
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            StringBuilder jsonString = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                jsonString.append(line);
            }
            reader.close();
            inputStream.close();
            
            // Parse the JSON array
            JSONArray versesArray = new JSONArray(jsonString.toString());
            Log.d("PersonalDevotional", "Total verses in file: " + versesArray.length());
            
            // Get the current day's verse index from SharedPreferences
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            int currentVerseIndex = prefs.getInt("current_verse_index", 0);
            long lastVerseDate = prefs.getLong("last_verse_date", 0);
            
            // Check if we need to move to the next verse (new day)
            long currentDate = System.currentTimeMillis();
            long oneDayMillis = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
            
            if (currentDate - lastVerseDate >= oneDayMillis) {
                // Move to next verse
                currentVerseIndex++;
                if (currentVerseIndex >= versesArray.length()) {
                    // Loop back to first verse
                    currentVerseIndex = 0;
                    Log.d("PersonalDevotional", "Reached end of verses, looping back to start");
                }
                
                // Save the new index and date
                SharedPreferences.Editor editor = prefs.edit();
                editor.putInt("current_verse_index", currentVerseIndex);
                editor.putLong("last_verse_date", currentDate);
                editor.apply();
                
                Log.d("PersonalDevotional", "Moved to next verse, index: " + currentVerseIndex);
            } else {
                Log.d("PersonalDevotional", "Same day, using cached verse index: " + currentVerseIndex);
            }
            
            // Get the verse for today
            JSONObject verse = versesArray.getJSONObject(currentVerseIndex);
            Log.d("PersonalDevotional", "Selected verse: " + verse.toString());
            
            return verse;
            
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error loading daily verse from local file", e);
            return null;
        }
    }
    
    // Old API methods removed - now using local file
    
    private String tryApiCall(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(15000);
            
            // Add headers to request JSON response
            connection.setRequestProperty("Accept", "application/json");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("User-Agent", "HolyWordApp/1.0");
            connection.setRequestProperty("Cache-Control", "no-cache");
            connection.setRequestProperty("Pragma", "no-cache");
            
            int responseCode = connection.getResponseCode();
            Log.d("PersonalDevotional", "API Call to " + urlString + " - Response Code: " + responseCode);
            
            // Log response headers
            Map<String, List<String>> headers = connection.getHeaderFields();
            Log.d("PersonalDevotional", "Response Headers: " + headers.toString());
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                
                String responseString = response.toString();
                Log.d("PersonalDevotional", "Full API Response from " + urlString + ": " + responseString);
                Log.d("PersonalDevotional", "Response length: " + responseString.length());
                
                // Extract JSON from HTML <pre> tag
                String jsonString = extractJsonFromHtml(responseString);
                Log.d("PersonalDevotional", "Extracted JSON: " + jsonString);
                
                if (jsonString != null && !jsonString.isEmpty()) {
                    try {
                        JSONObject jsonResponse = new JSONObject(jsonString);
                        Log.d("PersonalDevotional", "Successfully parsed JSON: " + jsonResponse.toString());
                        return jsonString;
                    } catch (Exception e) {
                        Log.e("PersonalDevotional", "Failed to parse JSON: " + jsonString, e);
                    }
                } else {
                    Log.e("PersonalDevotional", "Could not extract JSON from HTML response");
                    Log.e("PersonalDevotional", "Response contains <pre>: " + responseString.contains("<pre>"));
                    Log.e("PersonalDevotional", "Response contains JSON: " + responseString.contains("{"));
                }
            } else {
                Log.e("PersonalDevotional", "API returned error code: " + responseCode);
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error in API call to " + urlString, e);
        }
        return null;
    }
    
    private String tryApiCallWithDifferentHeaders(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(15000);
            
            // Try different headers
            connection.setRequestProperty("Accept", "*/*");
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
            connection.setRequestProperty("Accept-Language", "en-US,en;q=0.9");
            connection.setRequestProperty("Accept-Encoding", "gzip, deflate, br");
            connection.setRequestProperty("Connection", "keep-alive");
            
            int responseCode = connection.getResponseCode();
            Log.d("PersonalDevotional", "Alternative headers API call - Response Code: " + responseCode);
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                
                String responseString = response.toString();
                Log.d("PersonalDevotional", "Alternative headers response: " + responseString);
                
                String jsonString = extractJsonFromHtml(responseString);
                if (jsonString != null && !jsonString.isEmpty()) {
                    try {
                        JSONObject jsonResponse = new JSONObject(jsonString);
                        return jsonString;
                    } catch (Exception e) {
                        Log.e("PersonalDevotional", "Failed to parse JSON with alternative headers", e);
                    }
                }
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error in alternative headers API call", e);
        }
        return null;
    }

    private boolean loadFromCache() {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            String cachedEnglishText = prefs.getString("cached_english_text", null);
            String cachedEnglishRef = prefs.getString("cached_english_ref", null);
            String cachedTeluguText = prefs.getString("cached_telugu_text", null);
            String cachedTeluguRef = prefs.getString("cached_telugu_ref", null);
            long cacheTime = prefs.getLong("cache_time", 0);
            
            // Check if cache is valid (24 hours)
            long currentTime = System.currentTimeMillis();
            if (cachedEnglishText != null && cachedEnglishRef != null && 
                cachedTeluguText != null && cachedTeluguRef != null &&
                (currentTime - cacheTime) < 24 * 60 * 60 * 1000) {
                
                // Set the cached data and update display
                updateVerseDisplay();
                updateLanguageButtons();
                
                return true;
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error loading from cache", e);
        }
        return false;
    }

    private void clearCache() {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            SharedPreferences.Editor editor = prefs.edit();
            editor.remove("cached_english_text");
            editor.remove("cached_english_ref");
            editor.remove("cached_telugu_text");
            editor.remove("cached_telugu_ref");
            editor.remove("cache_time");
            editor.apply();
            Log.d("PersonalDevotional", "Cache cleared successfully");
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error clearing cache", e);
        }
    }

    private void saveToCache(String englishText, String englishRef, String teluguText, String teluguRef) {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString("cached_english_text", englishText);
            editor.putString("cached_english_ref", englishRef);
            editor.putString("cached_telugu_text", teluguText);
            editor.putString("cached_telugu_ref", teluguRef);
            editor.putLong("cache_time", System.currentTimeMillis());
            editor.apply();
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error saving to cache", e);
        }
    }

    private String extractJsonFromHtml(String htmlResponse) {
        try {
            Log.d("PersonalDevotional", "Attempting to extract JSON from HTML response");
            
            // Method 1: Look for <pre> tag content (as specified by XPath)
            int preStart = htmlResponse.indexOf("<pre>");
            int preEnd = htmlResponse.indexOf("</pre>");
            
            if (preStart != -1 && preEnd != -1) {
                String jsonContent = htmlResponse.substring(preStart + 5, preEnd).trim();
                Log.d("PersonalDevotional", "Found JSON in <pre> tag: " + jsonContent);
                if (isValidJson(jsonContent)) {
                    return jsonContent;
                }
            }
            
            // Method 2: Look for JSON pattern in the response
            int jsonStart = htmlResponse.indexOf("{");
            int jsonEnd = htmlResponse.lastIndexOf("}");
            
            if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
                String jsonContent = htmlResponse.substring(jsonStart, jsonEnd + 1).trim();
                Log.d("PersonalDevotional", "Found JSON pattern: " + jsonContent);
                if (isValidJson(jsonContent)) {
                    return jsonContent;
                }
            }
            
            // Method 3: Look for specific API response structure
            if (htmlResponse.contains("english") && htmlResponse.contains("telugu")) {
                Log.d("PersonalDevotional", "Found API structure keywords, attempting extraction");
                // Try to find the JSON object containing our expected fields
                String[] lines = htmlResponse.split("\n");
                for (String line : lines) {
                    if (line.trim().startsWith("{") && line.contains("english")) {
                        // Find the complete JSON object
                        int start = htmlResponse.indexOf(line.trim());
                        int end = start;
                        int braceCount = 0;
                        boolean inString = false;
                        
                        for (int i = start; i < htmlResponse.length(); i++) {
                            char c = htmlResponse.charAt(i);
                            if (c == '"' && (i == 0 || htmlResponse.charAt(i-1) != '\\')) {
                                inString = !inString;
                            } else if (!inString) {
                                if (c == '{') braceCount++;
                                else if (c == '}') braceCount--;
                                if (braceCount == 0) {
                                    end = i + 1;
                                    break;
                                }
                            }
                        }
                        
                        if (end > start) {
                            String jsonContent = htmlResponse.substring(start, end).trim();
                            Log.d("PersonalDevotional", "Extracted JSON by structure: " + jsonContent);
                            if (isValidJson(jsonContent)) {
                                return jsonContent;
                            }
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error extracting JSON from HTML", e);
        }
        
        Log.w("PersonalDevotional", "Could not extract valid JSON from response");
        return null;
    }
    
    private boolean isValidJson(String jsonString) {
        try {
            new JSONObject(jsonString);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private void updateVersesOnUIThread(JSONObject jsonResponse) {
        if (getActivity() == null) return;
        
        getActivity().runOnUiThread(() -> {
            try {
                String englishText, englishRef, teluguText, teluguRef;
                
                // Check if it's API response or local file structure
                if (jsonResponse.has("english") && jsonResponse.has("telugu")) {
                    // API response structure
                    englishText = jsonResponse.optString("english", "");
                    englishRef = jsonResponse.optString("englishReference", "");
                    teluguText = jsonResponse.optString("telugu", "");
                    teluguRef = jsonResponse.optString("teluguReference", "");
                    
                    Log.d("PersonalDevotional", "Using API response structure");
                } else {
                    // Local file structure
                    englishText = jsonResponse.optString("English verse", "");
                    englishRef = jsonResponse.optString("English reference", "");
                    String teluguPart1 = jsonResponse.optString("Telugu verse part 1", "");
                    String teluguPart2 = jsonResponse.optString("Telugu verse part 2", "");
                    teluguRef = jsonResponse.optString("Telugu reference", "");
                    
                    // Combine Telugu parts with newline
                    teluguText = teluguPart1 + "\n" + teluguPart2;
                    
                    Log.d("PersonalDevotional", "Using local file structure");
                }
                
                Log.d("PersonalDevotional", "English: " + englishText);
                Log.d("PersonalDevotional", "Telugu: " + teluguText);
                
                // Save to cache
                saveToCache(englishText, englishRef, teluguText, teluguRef);
                
                // Update display based on current language selection
                updateVerseDisplay();
                updateLanguageButtons();
                
                showLoading(false);
                
            } catch (Exception e) {
                Log.e("PersonalDevotional", "Error updating verse display", e);
                showErrorOnUIThread();
            }
        });
    }

    private void showErrorOnUIThread() {
        if (getActivity() == null) return;
        
        getActivity().runOnUiThread(() -> {
            // Show sample verses when API fails
            updateVerseDisplay();
            updateLanguageButtons();
            showLoading(false);
        });
    }

    private void showLoading(boolean show) {
        if (loadingIndicator != null) {
            loadingIndicator.setVisibility(show ? View.VISIBLE : View.GONE);
        }
        if (verseOfDayCard != null) {
            verseOfDayCard.setVisibility(show ? View.GONE : View.VISIBLE);
        }
    }

    // Audio Devotionals Methods
    private void showAudioDevotionalsDialog() {
        // If audio is already playing, just show the dialog with current state
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            Log.d("PersonalDevotional", "Audio already playing, showing dialog with current state");
            showAudioDialogWithCurrentState();
            return;
        }
        
        AlertDialog.Builder builder = new AlertDialog.Builder(requireContext());
        View dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.audio_devotionals_popup, null);
        builder.setView(dialogView);
        builder.setCancelable(true);
        
        audioDialog = builder.create();
        audioDialog.show();
        
        initAudioDialogViews(dialogView);
        setupAudioListeners();
        loadAudioDevotional();
    }
    
    private void showAudioDialogWithCurrentState() {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireContext());
        View dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.audio_devotionals_popup, null);
        builder.setView(dialogView);
        builder.setCancelable(true);
        
        audioDialog = builder.create();
        audioDialog.show();
        
        initAudioDialogViews(dialogView);
        setupAudioListeners();
        
        // Update UI with current playing state
        getActivity().runOnUiThread(() -> {
            showAudioLoading(false);
            updateAudioDuration();
            playPauseButton.setImageResource(R.drawable.ic_pause);
            isPlaying = true;
            startAudioProgressUpdate();
        });
    }
    
    private void initAudioDialogViews(View dialogView) {
        audioProgress = dialogView.findViewById(R.id.audio_progress);
        currentTime = dialogView.findViewById(R.id.current_time);
        totalTime = dialogView.findViewById(R.id.total_time);
        audioTitle = dialogView.findViewById(R.id.audio_title);
        audioDate = dialogView.findViewById(R.id.audio_date);
        audioError = dialogView.findViewById(R.id.audio_error);
        playPauseButton = dialogView.findViewById(R.id.play_pause_button);
        rewindButton = dialogView.findViewById(R.id.rewind_button);
        forwardButton = dialogView.findViewById(R.id.forward_button);
        closeButton = dialogView.findViewById(R.id.close_button);
        audioLoading = dialogView.findViewById(R.id.audio_loading);
        
        // Set current date
        SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM dd, yyyy", Locale.getDefault());
        audioDate.setText(dateFormat.format(Calendar.getInstance().getTime()));
        
        // Initialize notification manager
        notificationManager = (NotificationManager) requireContext().getSystemService(Context.NOTIFICATION_SERVICE);
        createNotificationChannel();
    }
    
    private void setupAudioListeners() {
        playPauseButton.setOnClickListener(v -> togglePlayPause());
        rewindButton.setOnClickListener(v -> rewindAudio());
        forwardButton.setOnClickListener(v -> forwardAudio());
        closeButton.setOnClickListener(v -> closeAudioDialog());
        
        audioProgress.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mediaPlayer != null) {
                    int position = (int) ((progress / 100.0) * mediaPlayer.getDuration());
                    mediaPlayer.seekTo(position);
                }
            }
            
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
    }
    
    private void loadAudioDevotional() {
        showAudioLoading(true);
        hideAudioError();
        
        // Check if MediaPlayer is already prepared and playing
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            Log.d("PersonalDevotional", "Audio already playing, updating UI");
            getActivity().runOnUiThread(() -> {
                showAudioLoading(false);
                updateAudioDuration();
                playPauseButton.setImageResource(R.drawable.ic_pause);
                isPlaying = true;
                startAudioProgressUpdate();
            });
            return;
        }
        
        executorService.execute(() -> {
            try {
                String audioUrl = generateAudioUrl();
                Log.d("PersonalDevotional", "Loading audio from: " + audioUrl);
                
                // Test URL accessibility first
                URL url = new URL(audioUrl);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("HEAD");
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                int responseCode = connection.getResponseCode();
                Log.d("PersonalDevotional", "URL response code: " + responseCode);
                connection.disconnect();
                
                if (mediaPlayer != null) {
                    mediaPlayer.release();
                }
                
                mediaPlayer = new MediaPlayer();
                mediaPlayer.setDataSource(audioUrl);
                mediaPlayer.setOnPreparedListener(mp -> {
                    getActivity().runOnUiThread(() -> {
                        showAudioLoading(false);
                        updateAudioDuration();
                        playPauseButton.setImageResource(R.drawable.ic_play_arrow);
                        isPlaying = false;
                    });
                });
                
                mediaPlayer.setOnErrorListener((mp, what, extra) -> {
                    Log.e("PersonalDevotional", "MediaPlayer error - what: " + what + ", extra: " + extra);
                    getActivity().runOnUiThread(() -> {
                        showAudioLoading(false);
                        showAudioError();
                        // Show more detailed error message
                        if (audioError != null) {
                            String errorMsg = "Error loading audio devotional\n";
                            switch (what) {
                                case MediaPlayer.MEDIA_ERROR_UNKNOWN:
                                    errorMsg += "Unknown error (Code: " + what + ", Extra: " + extra + ")";
                                    break;
                                case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                                    errorMsg += "Server died (Code: " + what + ", Extra: " + extra + ")";
                                    break;
                                case MediaPlayer.MEDIA_ERROR_MALFORMED:
                                    errorMsg += "Malformed media (Code: " + what + ", Extra: " + extra + ")";
                                    break;
                                case MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                                    errorMsg += "Unsupported format (Code: " + what + ", Extra: " + extra + ")\nTry reopening the dialog";
                                    break;
                                case MediaPlayer.MEDIA_ERROR_IO:
                                    errorMsg += "Network/IO error (Code: " + what + ", Extra: " + extra + ")";
                                    break;
                                default:
                                    errorMsg += "Error code: " + what + ", Extra: " + extra;
                                    break;
                            }
                            audioError.setText(errorMsg);
                        }
                    });
                    return true;
                });
                
                // Add completion listener
                mediaPlayer.setOnCompletionListener(mp -> {
                    Log.d("PersonalDevotional", "Audio playback completed");
                    getActivity().runOnUiThread(() -> {
                        isPlaying = false;
                        playPauseButton.setImageResource(R.drawable.ic_play_arrow);
                        stopAudioProgressUpdate();
                    });
                });
                
                mediaPlayer.prepareAsync();
                
            } catch (Exception e) {
                Log.e("PersonalDevotional", "Error loading audio", e);
                getActivity().runOnUiThread(() -> {
                    showAudioLoading(false);
                    showAudioError();
                });
            }
        });
    }
    
    private String generateAudioUrl() {
        Calendar calendar = Calendar.getInstance();
        int month = calendar.get(Calendar.MONTH) + 1; // Calendar.MONTH is 0-based
        int day = calendar.get(Calendar.DAY_OF_MONTH);
        
        // Format month with leading zero if needed
        String monthStr = String.format("%02d", month);
        String dayStr = String.format("%02d", day);
        String monthName = getMonthName(month);
        
        // For testing, let's use the known working URL first
        String audioUrl = "http://www.onlinetelugubible.net/Daily%20Devotions/Audio/10October/October-27-Website.mp3";
        
        // Original dynamic URL (commented for testing):
        // String audioUrl = String.format("http://www.onlinetelugubible.net/Daily%%20Devotions/Audio/%s%s/%s-%d-Website.mp3", 
        //         monthStr, monthName, monthName, day);
        
        Log.d("PersonalDevotional", "Generated audio URL: " + audioUrl + " (Current Day: " + day + ")");
        return audioUrl;
    }
    
    private String getMonthName(int month) {
        String[] monthNames = {"", "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"};
        return monthNames[month];
    }
    
    private void togglePlayPause() {
        if (mediaPlayer == null) return;
        
        if (isPlaying) {
            mediaPlayer.pause();
            playPauseButton.setImageResource(R.drawable.ic_play_arrow);
            isPlaying = false;
            stopAudioProgressUpdate();
        } else {
            mediaPlayer.start();
            playPauseButton.setImageResource(R.drawable.ic_pause);
            isPlaying = true;
            startAudioProgressUpdate();
        }
    }
    
    private void rewindAudio() {
        if (mediaPlayer != null) {
            int currentPos = mediaPlayer.getCurrentPosition();
            int newPos = Math.max(0, currentPos - 10000); // 10 seconds back
            mediaPlayer.seekTo(newPos);
        }
    }
    
    private void forwardAudio() {
        if (mediaPlayer != null) {
            int currentPos = mediaPlayer.getCurrentPosition();
            int duration = mediaPlayer.getDuration();
            int newPos = Math.min(duration, currentPos + 10000); // 10 seconds forward
            mediaPlayer.seekTo(newPos);
        }
    }
    
    private void startAudioProgressUpdate() {
        audioRunnable = new Runnable() {
            @Override
            public void run() {
                if (mediaPlayer != null && isPlaying) {
                    int currentPos = mediaPlayer.getCurrentPosition();
                    int duration = mediaPlayer.getDuration();
                    
                    if (duration > 0) {
                        int progress = (int) ((currentPos * 100.0) / duration);
                        audioProgress.setProgress(progress);
                        currentTime.setText(formatTime(currentPos));
                    }
                    
                    audioHandler.postDelayed(this, 1000);
                }
            }
        };
        audioHandler.post(audioRunnable);
    }
    
    private void stopAudioProgressUpdate() {
        if (audioRunnable != null) {
            audioHandler.removeCallbacks(audioRunnable);
        }
    }
    
    private void updateAudioDuration() {
        if (mediaPlayer != null) {
            totalTime.setText(formatTime(mediaPlayer.getDuration()));
        }
    }
    
    private String formatTime(int milliseconds) {
        int seconds = milliseconds / 1000;
        int minutes = seconds / 60;
        seconds = seconds % 60;
        return String.format(Locale.getDefault(), "%d:%02d", minutes, seconds);
    }
    
    private void showAudioLoading(boolean show) {
        if (audioLoading != null) {
            audioLoading.setVisibility(show ? View.VISIBLE : View.GONE);
        }
    }
    
    private void showAudioError() {
        if (audioError != null) {
            audioError.setVisibility(View.VISIBLE);
        }
    }
    
    private void hideAudioError() {
        if (audioError != null) {
            audioError.setVisibility(View.GONE);
        }
    }
    
    private void closeAudioDialog() {
        if (audioDialog != null) {
            audioDialog.dismiss();
        }
        // Show notification for background control
        showAudioNotification();
    }
    
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Audio Devotionals",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Controls for background audio devotionals");
            channel.setShowBadge(false);
            notificationManager.createNotificationChannel(channel);
        }
    }
    
    private void showAudioNotification() {
        if (notificationManager == null) return;
        
        Intent playPauseIntent = new Intent(requireContext(), getClass());
        playPauseIntent.setAction("PLAY_PAUSE");
        PendingIntent playPausePendingIntent = PendingIntent.getBroadcast(
            requireContext(), 0, playPauseIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        Intent stopIntent = new Intent(requireContext(), getClass());
        stopIntent.setAction("STOP");
        PendingIntent stopPendingIntent = PendingIntent.getBroadcast(
            requireContext(), 1, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        NotificationCompat.Builder builder = new NotificationCompat.Builder(requireContext(), CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_headphones)
            .setContentTitle("Audio Devotional")
            .setContentText(isPlaying ? "Playing" : "Paused")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(isPlaying ? R.drawable.ic_pause : R.drawable.ic_play_arrow, 
                      isPlaying ? "Pause" : "Play", playPausePendingIntent)
            .addAction(R.drawable.ic_close, "Stop", stopPendingIntent);
        
        notificationManager.notify(NOTIFICATION_ID, builder.build());
    }
    
    private void hideAudioNotification() {
        if (notificationManager != null) {
            notificationManager.cancel(NOTIFICATION_ID);
        }
    }

    // Prayer Reminder Status Update
    private void updatePrayerReminderStatus() {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            String reminderName = prefs.getString("prayer_reminder_name", null);
            String reminderTime = prefs.getString("prayer_reminder_time", null);
            
            if (reminderName != null && reminderTime != null) {
                // Update status to show reminder is active
                prayerReminderStatus.setText(getString(R.string.reminder_active));
                prayerReminderStatus.setTextColor(getResources().getColor(R.color.primary));
                prayerReminderButton.setText(getString(R.string.reminder_set_for, reminderTime));
                manageReminderButton.setVisibility(View.VISIBLE);
                
                Log.d("PersonalDevotional", "Prayer reminder status updated: " + reminderName + " at " + reminderTime);
            } else {
                // No reminder set
                prayerReminderStatus.setText(getString(R.string.set_reminder));
                prayerReminderStatus.setTextColor(getResources().getColor(R.color.text_secondary));
                prayerReminderButton.setText(getString(R.string.set_prayer_reminder));
                manageReminderButton.setVisibility(View.GONE);
                
                Log.d("PersonalDevotional", "No prayer reminder set");
            }
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error updating prayer reminder status", e);
        }
    }

    // Manage Prayer Reminder Dialog
    private void showManageReminderDialog() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        String reminderName = prefs.getString("prayer_reminder_name", "");
        String reminderTime = prefs.getString("prayer_reminder_time", "");
        
        String[] options = {
            getString(R.string.edit_reminder),
            getString(R.string.delete_reminder)
        };
        
        AlertDialog.Builder builder = new AlertDialog.Builder(requireContext());
        builder.setTitle(getString(R.string.manage) + " - " + reminderName);
        builder.setMessage(getString(R.string.reminder_set_for, reminderTime));
        builder.setItems(options, (dialog, which) -> {
            switch (which) {
                case 0: // Edit
                    showPrayerReminderDialog();
                    break;
                case 1: // Delete
                    deletePrayerReminder();
                    break;
            }
        });
        builder.setNegativeButton(getString(R.string.cancel), null);
        builder.show();
    }
    
    private void deletePrayerReminder() {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireContext());
        builder.setTitle(getString(R.string.delete_reminder));
        builder.setMessage("Are you sure you want to delete this prayer reminder?");
        builder.setPositiveButton(getString(R.string.delete), (dialog, which) -> {
            try {
                // Cancel the alarm
                Intent intent = new Intent(requireContext(), PrayerReminderReceiver.class);
                PendingIntent pendingIntent = PendingIntent.getBroadcast(requireContext(), 
                    PRAYER_ALARM_REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                
                if (alarmManager != null) {
                    alarmManager.cancel(pendingIntent);
                }
                
                // Clear SharedPreferences
                SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
                SharedPreferences.Editor editor = prefs.edit();
                editor.remove("prayer_reminder_name");
                editor.remove("prayer_reminder_time");
                editor.remove("prayer_reminder_set_time");
                editor.apply();
                
                // Update UI
                updatePrayerReminderStatus();
                
                Toast.makeText(getContext(), getString(R.string.reminder_deleted), Toast.LENGTH_SHORT).show();
                
                Log.d("PersonalDevotional", "Prayer reminder deleted successfully");
                
            } catch (Exception e) {
                Log.e("PersonalDevotional", "Error deleting prayer reminder", e);
                Toast.makeText(getContext(), "Failed to delete prayer reminder", Toast.LENGTH_SHORT).show();
            }
        });
        builder.setNegativeButton(getString(R.string.cancel), null);
        builder.show();
    }
    
    // Test alarm method to verify alarm functionality
    private void setTestAlarm() {
        try {
            Calendar testCalendar = Calendar.getInstance();
            testCalendar.add(Calendar.MINUTE, 1); // 1 minute from now
            
            Intent testIntent = new Intent(requireContext(), PrayerReminderReceiver.class);
            testIntent.putExtra("reminder_name", "Test Alarm");
            testIntent.putExtra("reminder_time", "Test");
            
            PendingIntent testPendingIntent = PendingIntent.getBroadcast(requireContext(), 
                9999, testIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            
            long testAlarmTime = testCalendar.getTimeInMillis();
            Log.d("PersonalDevotional", "Setting test alarm for: " + new java.util.Date(testAlarmTime));
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, testAlarmTime, testPendingIntent);
                    Log.d("PersonalDevotional", "Test exact alarm set successfully");
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, testAlarmTime, testPendingIntent);
                    Log.d("PersonalDevotional", "Test inexact alarm set");
                }
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, testAlarmTime, testPendingIntent);
                Log.d("PersonalDevotional", "Test alarm set for older Android");
            }
            
            Toast.makeText(getContext(), "Test alarm set for 1 minute from now", Toast.LENGTH_LONG).show();
            
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error setting test alarm", e);
        }
    }
    
    // Check notification permissions
    private void checkNotificationPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(requireContext(), 
                android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                
                Log.w("PersonalDevotional", "Notification permission not granted");
                Toast.makeText(getContext(), "Notification permission required for prayer reminders", Toast.LENGTH_LONG).show();
                
                // Request permission
                requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 100);
            } else {
                Log.d("PersonalDevotional", "Notification permission granted");
            }
        }
    }
    
    // Open Saved Alarms Activity
    private void openSavedAlarms() {
        try {
            Intent intent = new Intent(requireContext(), SavedAlarmsActivity.class);
            startActivity(intent);
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error opening saved alarms", e);
            Toast.makeText(getContext(), "Error opening saved alarms", Toast.LENGTH_SHORT).show();
        }
    }
    
    // Save alarm to saved alarms system
    private void saveToSavedAlarms(String reminderName, String timeText) {
        try {
            SharedPreferences prefs = requireContext().getSharedPreferences("saved_alarms", Context.MODE_PRIVATE);
            int alarmCount = prefs.getInt("alarm_count", 0);
            
            // Save new alarm
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString("alarm_" + alarmCount + "_name", reminderName);
            editor.putString("alarm_" + alarmCount + "_time", timeText);
            editor.putString("alarm_" + alarmCount + "_days", "1111111"); // Default: all days
            editor.putBoolean("alarm_" + alarmCount + "_active", true);
            editor.putInt("alarm_count", alarmCount + 1);
            editor.apply();
            
            Log.d("PersonalDevotional", "Alarm saved to saved alarms: " + reminderName + " at " + timeText);
            
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error saving to saved alarms", e);
        }
    }

    // Prayer Reminder Methods
    private void showPrayerReminderDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(requireContext());
        View dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.prayer_reminder_setup, null);
        builder.setView(dialogView);
        builder.setCancelable(true);
        
        AlertDialog dialog = builder.create();
        dialog.show();
        
        initPrayerReminderViews(dialogView, dialog);
    }
    
    private void initPrayerReminderViews(View dialogView, AlertDialog dialog) {
        EditText reminderNameInput = dialogView.findViewById(R.id.reminder_name_input);
        MaterialButton timePickerButton = dialogView.findViewById(R.id.time_picker_button);
        TextView selectedTimeDisplay = dialogView.findViewById(R.id.selected_time_display);
        MaterialButton saveReminderButton = dialogView.findViewById(R.id.save_reminder_button);
        MaterialButton cancelReminderButton = dialogView.findViewById(R.id.cancel_reminder_button);
        ImageButton closeReminderButton = dialogView.findViewById(R.id.close_reminder_button);
        
        // Initialize alarm manager
        alarmManager = (AlarmManager) requireContext().getSystemService(Context.ALARM_SERVICE);
        
        // Check notification permissions
        checkNotificationPermissions();
        
        // Set current time as default
        Calendar calendar = Calendar.getInstance();
        selectedTimeDisplay.setText(String.format(Locale.getDefault(), "%02d:%02d", 
            calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE)));
        
        // Time picker button click
        timePickerButton.setOnClickListener(v -> {
            TimePickerDialog timePickerDialog = new TimePickerDialog(requireContext(),
                (view, hourOfDay, minute) -> {
                    selectedTimeDisplay.setText(String.format(Locale.getDefault(), "%02d:%02d", hourOfDay, minute));
                },
                calendar.get(Calendar.HOUR_OF_DAY),
                calendar.get(Calendar.MINUTE),
                true
            );
            timePickerDialog.show();
        });
        
        // Save reminder button
        saveReminderButton.setOnClickListener(v -> {
            String reminderName = reminderNameInput.getText().toString().trim();
            String timeText = selectedTimeDisplay.getText().toString();
            
            if (TextUtils.isEmpty(reminderName)) {
                Toast.makeText(getContext(), "Please enter a reminder name", Toast.LENGTH_SHORT).show();
                return;
            }
            
            if (TextUtils.isEmpty(timeText)) {
                Toast.makeText(getContext(), "Please select a time", Toast.LENGTH_SHORT).show();
                return;
            }
            
            savePrayerReminder(reminderName, timeText);
            dialog.dismiss();
        });
        
        // Cancel button
        cancelReminderButton.setOnClickListener(v -> dialog.dismiss());
        
        // Close button
        closeReminderButton.setOnClickListener(v -> dialog.dismiss());
    }
    
    private void savePrayerReminder(String reminderName, String timeText) {
        try {
            // Check if alarm manager is available
            if (alarmManager == null) {
                alarmManager = (AlarmManager) requireContext().getSystemService(Context.ALARM_SERVICE);
                if (alarmManager == null) {
                    Toast.makeText(getContext(), "Alarm service not available", Toast.LENGTH_SHORT).show();
                    return;
                }
            }
            
            // Parse time
            String[] timeParts = timeText.split(":");
            int hour = Integer.parseInt(timeParts[0]);
            int minute = Integer.parseInt(timeParts[1]);
            
            // Create calendar for today with selected time
            Calendar calendar = Calendar.getInstance();
            calendar.set(Calendar.HOUR_OF_DAY, hour);
            calendar.set(Calendar.MINUTE, minute);
            calendar.set(Calendar.SECOND, 0);
            calendar.set(Calendar.MILLISECOND, 0);
            
            // If time has passed today, set for tomorrow
            if (calendar.getTimeInMillis() <= System.currentTimeMillis()) {
                calendar.add(Calendar.DAY_OF_MONTH, 1);
            }
            
            // Create intent for alarm
            Intent intent = new Intent(requireContext(), PrayerReminderReceiver.class);
            intent.putExtra("reminder_name", reminderName);
            intent.putExtra("reminder_time", timeText);
            
            PendingIntent pendingIntent = PendingIntent.getBroadcast(requireContext(), 
                PRAYER_ALARM_REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            
            // Set alarm - use exact alarm for Android 12+
            long alarmTime = calendar.getTimeInMillis();
            Log.d("PersonalDevotional", "Setting alarm for: " + new java.util.Date(alarmTime));
            Log.d("PersonalDevotional", "Current time: " + new java.util.Date(System.currentTimeMillis()));
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarmTime, pendingIntent);
                    Log.d("PersonalDevotional", "Exact alarm set successfully");
                } else {
                    // Fallback to inexact alarm
                    alarmManager.set(AlarmManager.RTC_WAKEUP, alarmTime, pendingIntent);
                    Log.d("PersonalDevotional", "Inexact alarm set (exact not allowed)");
                }
            } else {
                // For older Android versions, use setRepeating
                alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, alarmTime,
                    AlarmManager.INTERVAL_DAY, pendingIntent);
                Log.d("PersonalDevotional", "Repeating alarm set for older Android");
            }
            
            // Save to both old system (for backward compatibility) and new saved alarms system
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString("prayer_reminder_name", reminderName);
            editor.putString("prayer_reminder_time", timeText);
            editor.putLong("prayer_reminder_set_time", calendar.getTimeInMillis());
            editor.apply();
            
            // Also save to saved alarms system
            saveToSavedAlarms(reminderName, timeText);
            
            Toast.makeText(getContext(), getString(R.string.reminder_saved), Toast.LENGTH_SHORT).show();
            
            // Update the prayer reminder status
            updatePrayerReminderStatus();
            
            Log.d("PersonalDevotional", "Prayer reminder saved: " + reminderName + " at " + timeText);
            
            // Set a test alarm for 1 minute from now to verify alarm functionality
            setTestAlarm();
            
        } catch (Exception e) {
            Log.e("PersonalDevotional", "Error saving prayer reminder", e);
            Toast.makeText(getContext(), getString(R.string.reminder_error), Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (executorService != null) {
            executorService.shutdown();
        }
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;
        }
        if (audioHandler != null && audioRunnable != null) {
            audioHandler.removeCallbacks(audioRunnable);
        }
        hideAudioNotification();
    }
}
