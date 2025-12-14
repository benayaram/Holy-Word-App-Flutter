package com.holywordapp;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.app.ProgressDialog;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.holywordapp.BibleDBHelper;
import com.holywordapp.KJVBibleDBHelper;
import com.holywordapp.BibleVerse;
import com.holywordapp.Verse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class AudioBibleActivity extends AppCompatActivity {

    // Database helpers
    private BibleDBHelper dbHelper;
    private KJVBibleDBHelper kjvDbHelper;

    // UI Components
    private Spinner bookSpinner, chapterSpinner;
    private Button btnTranslate;
    private LinearLayout layoutAudioPlayer;
    private TextView tvAudioTitle, tvCurrentTime, tvTotalTime;
    private ImageButton btnPlayPause, btnPreviousChapter, btnNextChapter, btnCloseAudio;
    private SeekBar seekBarAudio;

    // Audio state
    private MediaPlayer mediaPlayer;
    private Handler audioHandler = new Handler();
    private boolean isAudioPrepared = false;
    private boolean isAutoPlayNext = true;
    private ProgressDialog progressDialog;

    // Language state
    private boolean isEnglishMode = false; // Default to Telugu
    private String selectedBook;
    private int selectedChapter;

    // Audio Bible data
    private String[] versionCodes = {"1", "29"}; // English, Telugu
    private int selectedVersionIndex = 1; // Default to Telugu

    // Book arrays
    public static final String[] BOOKS_IN_ORDER = {
            "ఆదికాండము", "నిర్గమకాండము", "లేవీయకాండము", "సంఖ్యాకాండము", "ద్వితీయోపదేశకాండమ",
            "యెహొషువ", "న్యాయాధిపతులు", "రూతు", "సమూయేలు మొదటి గ్రంథము", "సమూయేలు రెండవ గ్రంథము",
            "రాజులు మొదటి గ్రంథము", "రాజులు రెండవ గ్రంథము", "దినవృత్తాంతములు మొదటి గ్రంథము", "దినవృత్తాంతములు రెండవ గ్రంథము",
            "ఎజ్రా", "నెహెమ్యా", "ఎస్తేరు", "యోబు గ్రంథము", "కీర్తనల గ్రంథము", "సామెతలు",
            "ప్రసంగి", "పరమగీతము", "యెషయా గ్రంథము", "యిర్మీయా", "విలాపవాక్యములు", "యెహెజ్కేలు", "దానియేలు",
            "హొషేయ", "యోవేలు", "ఆమోసు", "ఓబద్యా", "యోనా", "మీకా", "నహూము", "హబక్కూకు",
            "జెఫన్యా", "హగ్గయి", "జెకర్యా", "మలాకీ", "మత్తయి సువార్త", "మార్కు సువార్త",
            "లూకా సువార్త", "యోహాను సువార్త", "అపొస్తలుల కార్యములు", "రోమీయులకు",
            "1 కొరింథీయులకు", "2 కొరింథీయులకు", "గలతీయులకు", "ఎఫెసీయులకు",
            "ఫిలిప్పీయులకు", "కొలొస్సయులకు", "1 థెస్సలొనీకయులకు", "2 థెస్సలొనీకయులకు",
            "1 తిమోతికి", "2 తిమోతికి", "తీతుకు", "ఫిలేమోనుకు", "హెబ్రీయులకు", "యాకోబు",
            "1 పేతురు", "2 పేతురు", "1 యోహాను", "2 యోహాను", "3 యోహాను", "యూదా", "ప్రకటన గ్రంథము"
    };

    public static final String[] ENGLISH_BOOKS_IN_ORDER = {
            "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges",
            "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
            "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes",
            "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
            "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
            "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", "Mark", "Luke",
            "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians",
            "Ephesians", "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
            "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter",
            "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_audio_bible);

        // Initialize database helpers
        dbHelper = new BibleDBHelper(this);
        kjvDbHelper = new KJVBibleDBHelper(this);

        // Setup toolbar
        setupToolbar();

        // Initialize views
        initViews();

        // Setup spinners
        setupSpinners();

        // Setup audio player
        setupAudioPlayer();

        // Load initial data
        loadInitialData();
    }

    private void setupToolbar() {
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Audio Bible");
            getSupportActionBar().setSubtitle("Listen to the Word of God");
        }
    }

    private void initViews() {
        bookSpinner = findViewById(R.id.book_spinner);
        chapterSpinner = findViewById(R.id.chapter_spinner);
        btnTranslate = findViewById(R.id.btn_translate);
        
        layoutAudioPlayer = findViewById(R.id.layout_audio_player);
        tvAudioTitle = findViewById(R.id.tv_audio_title);
        tvCurrentTime = findViewById(R.id.tv_current_time);
        tvTotalTime = findViewById(R.id.tv_total_time);
        btnPlayPause = findViewById(R.id.btn_play_pause);
        btnPreviousChapter = findViewById(R.id.btn_previous_chapter);
        btnNextChapter = findViewById(R.id.btn_next_chapter);
        btnCloseAudio = findViewById(R.id.btn_close_audio);
        seekBarAudio = findViewById(R.id.seek_bar_audio);

        // Set initial language button text
        btnTranslate.setText("EN");
    }

    private void setupSpinners() {
        // Setup book spinner
        String[] booksToUse = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, booksToUse);
        bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        bookSpinner.setAdapter(bookAdapter);

        bookSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
                selectedBook = currentBooks[position];
                loadChaptersForCurrentBook();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        chapterSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                selectedChapter = (int) chapterSpinner.getSelectedItem();
                updateAudioTitle();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        // Setup translate button
        btnTranslate.setOnClickListener(v -> toggleLanguage());
        
        // Setup play button
        Button btnPlay = findViewById(R.id.btn_play);
        btnPlay.setOnClickListener(v -> playAudio());
    }

    private void setupAudioPlayer() {
        btnPlayPause.setOnClickListener(v -> togglePlayPause());
        btnPreviousChapter.setOnClickListener(v -> playPreviousChapter());
        btnNextChapter.setOnClickListener(v -> playNextChapter());
        btnCloseAudio.setOnClickListener(v -> closeAudioPlayer());

        seekBarAudio.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mediaPlayer != null && isAudioPrepared) {
                    mediaPlayer.seekTo(progress);
                    updateCurrentTime(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
    }

    private void loadInitialData() {
        // Set initial book and chapter
        selectedBook = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER[0] : BOOKS_IN_ORDER[0];
        selectedChapter = 1;
        
        // Load chapters for first book
        loadChaptersForCurrentBook();
        
        // Update audio title
        updateAudioTitle();
    }

    private void loadChaptersForCurrentBook() {
        if (selectedBook == null) return;

        List<Integer> chapters;
        if (isEnglishMode) {
            // Use KJV database for English
            String mappedBookName = mapToKJVBookName(selectedBook);
            chapters = kjvDbHelper.getChaptersForBook(mappedBookName);
        } else {
            // Use Telugu database
            chapters = dbHelper.getChapters(selectedBook);
        }

        if (chapters.isEmpty()) {
            Toast.makeText(this, "No chapters found for " + selectedBook, Toast.LENGTH_SHORT).show();
            return;
        }

        ArrayAdapter<Integer> chapAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, chapters);
        chapAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        chapterSpinner.setAdapter(chapAdapter);

        // Set to first chapter
        if (chapters.size() > 0) {
            selectedChapter = chapters.get(0);
            chapterSpinner.setSelection(0);
        }
    }

    private void toggleLanguage() {
        isEnglishMode = !isEnglishMode;
        
        // Update button text
        btnTranslate.setText(isEnglishMode ? "TE" : "EN");
        
        // Update title
        if (getSupportActionBar() != null) {
            getSupportActionBar().setSubtitle("Listen to the Word of God - " + (isEnglishMode ? "English" : "Telugu"));
        }
        
        // Update selected version index for audio
        selectedVersionIndex = isEnglishMode ? 0 : 1;
        
        // Reload book spinner
        String[] booksToUse = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, booksToUse);
        bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        bookSpinner.setAdapter(bookAdapter);
        
        // Set to first book
        selectedBook = booksToUse[0];
        bookSpinner.setSelection(0);
        
        Toast.makeText(this, 
            isEnglishMode ? "Switched to English Audio Bible" : "Switched to Telugu Audio Bible", 
            Toast.LENGTH_SHORT).show();
    }

    private void togglePlayPause() {
        if (mediaPlayer == null) {
            playAudio();
        } else if (mediaPlayer.isPlaying()) {
            pauseAudio();
        } else {
            resumeAudio();
        }
    }

    private void playAudio() {
        if (selectedBook == null || selectedChapter <= 0) {
            Toast.makeText(this, "Please select a book and chapter", Toast.LENGTH_SHORT).show();
            return;
        }
        
        // Check network connectivity
        if (!isNetworkAvailable()) {
            Toast.makeText(this, "No internet connection. Please check your network and try again.", Toast.LENGTH_LONG).show();
            return;
        }

        // Stop any existing audio
        stopAudio();

        // Get book number for audio URL
        int bookNumber = getBookNumber(selectedBook);
        if (bookNumber == -1) {
            Toast.makeText(this, "Invalid book selection", Toast.LENGTH_SHORT).show();
            return;
        }

        // Construct audio URL - using the same format as BibleActivity
        String versionCode = versionCodes[selectedVersionIndex];
        String audioUrl;
        
        if (versionCode.equals("29")) {
            // Telugu audio
            audioUrl = String.format("http://audio4.wordfree.net/bibles/app/audio/%s/%d/%d.mp3", 
                versionCode, bookNumber, selectedChapter);
        } else {
            // English audio
            audioUrl = String.format("http://kjv.wordfree.net/bibles/app/audio/%s/%d/%d.mp3", 
                versionCode, bookNumber, selectedChapter);
        }

        try {
            // Show loading dialog
            if (progressDialog == null) {
                progressDialog = new ProgressDialog(this);
                progressDialog.setMessage("Loading audio...");
                progressDialog.setCancelable(false);
            }
            progressDialog.show();
            
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setDataSource(audioUrl);
            mediaPlayer.setOnPreparedListener(mp -> {
                isAudioPrepared = true;
                mp.start();
                btnPlayPause.setImageResource(android.R.drawable.ic_media_pause);
                layoutAudioPlayer.setVisibility(View.VISIBLE);
                startProgressUpdate();
                
                // Hide loading dialog
                if (progressDialog != null && progressDialog.isShowing()) {
                    progressDialog.dismiss();
                }
            });
            mediaPlayer.setOnCompletionListener(mp -> {
                btnPlayPause.setImageResource(android.R.drawable.ic_media_play);
                if (isAutoPlayNext) {
                    playNextChapter();
                }
            });
            mediaPlayer.setOnErrorListener((mp, what, extra) -> {
                // Hide loading dialog
                if (progressDialog != null && progressDialog.isShowing()) {
                    progressDialog.dismiss();
                }
                
                String errorMessage = "Error playing audio";
                switch (what) {
                    case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                        errorMessage = "Audio server error. Please try again.";
                        break;
                    case MediaPlayer.MEDIA_ERROR_IO:
                        errorMessage = "Network error. Please check your internet connection.";
                        break;
                    case MediaPlayer.MEDIA_ERROR_MALFORMED:
                        errorMessage = "Audio format error.";
                        break;
                    case MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                        errorMessage = "Audio format not supported.";
                        break;
                    case MediaPlayer.MEDIA_ERROR_TIMED_OUT:
                        errorMessage = "Connection timeout. Please try again.";
                        break;
                    default:
                        errorMessage = "Audio playback error. Please try again.";
                        break;
                }
                Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show();
                return true;
            });
            mediaPlayer.prepareAsync();
        } catch (IOException e) {
            Toast.makeText(this, "Error loading audio: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void pauseAudio() {
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            mediaPlayer.pause();
            btnPlayPause.setImageResource(android.R.drawable.ic_media_play);
        }
    }

    private void resumeAudio() {
        if (mediaPlayer != null && !mediaPlayer.isPlaying()) {
            mediaPlayer.start();
            btnPlayPause.setImageResource(android.R.drawable.ic_media_pause);
        }
    }

    private void stopAudio() {
        if (mediaPlayer != null) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
            isAudioPrepared = false;
            btnPlayPause.setImageResource(android.R.drawable.ic_media_play);
        }
    }

    private void playPreviousChapter() {
        List<Integer> chapters = getCurrentChapters();
        if (chapters.isEmpty()) return;

        int currentIndex = chapters.indexOf(selectedChapter);
        if (currentIndex > 0) {
            selectedChapter = chapters.get(currentIndex - 1);
            chapterSpinner.setSelection(currentIndex - 1);
            playAudio();
        }
    }

    private void playNextChapter() {
        List<Integer> chapters = getCurrentChapters();
        if (chapters.isEmpty()) return;

        int currentIndex = chapters.indexOf(selectedChapter);
        if (currentIndex < chapters.size() - 1) {
            selectedChapter = chapters.get(currentIndex + 1);
            chapterSpinner.setSelection(currentIndex + 1);
            playAudio();
        }
    }

    private void closeAudioPlayer() {
        stopAudio();
        layoutAudioPlayer.setVisibility(View.GONE);
    }

    private List<Integer> getCurrentChapters() {
        if (selectedBook == null) return new ArrayList<>();

        if (isEnglishMode) {
            String mappedBookName = mapToKJVBookName(selectedBook);
            return kjvDbHelper.getChaptersForBook(mappedBookName);
        } else {
            return dbHelper.getChapters(selectedBook);
        }
    }

    private void updateAudioTitle() {
        if (selectedBook != null && selectedChapter > 0) {
            tvAudioTitle.setText(selectedBook + " Chapter " + selectedChapter);
        }
    }

    private void startProgressUpdate() {
        audioHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (mediaPlayer != null && isAudioPrepared) {
                    int currentPosition = mediaPlayer.getCurrentPosition();
                    int totalDuration = mediaPlayer.getDuration();
                    
                    seekBarAudio.setMax(totalDuration);
                    seekBarAudio.setProgress(currentPosition);
                    
                    updateCurrentTime(currentPosition);
                    updateTotalTime(totalDuration);
                    
                    audioHandler.postDelayed(this, 1000);
                }
            }
        }, 1000);
    }

    private void updateCurrentTime(int milliseconds) {
        int seconds = (milliseconds / 1000) % 60;
        int minutes = (milliseconds / (1000 * 60)) % 60;
        tvCurrentTime.setText(String.format("%02d:%02d", minutes, seconds));
    }

    private void updateTotalTime(int milliseconds) {
        int seconds = (milliseconds / 1000) % 60;
        int minutes = (milliseconds / (1000 * 60)) % 60;
        tvTotalTime.setText(String.format("%02d:%02d", minutes, seconds));
    }

    private int getBookNumber(String bookName) {
        String[] books = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        for (int i = 0; i < books.length; i++) {
            if (books[i].equals(bookName)) {
                return i + 1; // Book numbers start from 1
            }
        }
        return -1;
    }

    /**
     * Map standard English book names to KJV database format
     */
    private String mapToKJVBookName(String standardBookName) {
        switch (standardBookName) {
            case "1 Samuel": return "I Samuel";
            case "2 Samuel": return "II Samuel";
            case "1 Kings": return "I Kings";
            case "2 Kings": return "II Kings";
            case "1 Chronicles": return "I Chronicles";
            case "2 Chronicles": return "II Chronicles";
            case "1 Corinthians": return "I Corinthians";
            case "2 Corinthians": return "II Corinthians";
            case "1 Thessalonians": return "I Thessalonians";
            case "2 Thessalonians": return "II Thessalonians";
            case "1 Timothy": return "I Timothy";
            case "2 Timothy": return "II Timothy";
            case "1 Peter": return "I Peter";
            case "2 Peter": return "II Peter";
            case "1 John": return "I John";
            case "2 John": return "II John";
            case "3 John": return "III John";
            case "Revelation": return "Revelation of John";
            default: return standardBookName;
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private boolean isNetworkAvailable() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivityManager != null) {
            NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
            return activeNetworkInfo != null && activeNetworkInfo.isConnected();
        }
        return false;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopAudio();
        if (dbHelper != null) {
            dbHelper.close();
        }
        if (kjvDbHelper != null) {
            kjvDbHelper.close();
        }
    }
}