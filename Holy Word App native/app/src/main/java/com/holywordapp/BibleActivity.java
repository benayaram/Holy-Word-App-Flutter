package com.holywordapp;

import android.app.AlertDialog;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Color;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.app.PictureInPictureParams;
import android.util.Rational;
import android.content.res.Configuration;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.holywordapp.utils.LanguageManager;
import com.holywordapp.SettingsActivity;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class BibleActivity extends AppCompatActivity {

    Spinner bookSpinner, chapterSpinner, verseSpinner;
    RecyclerView verseRecyclerView;
    BibleVerseAdapter verseAdapter;
    BibleDBHelper dbHelper;
    NotesDBHelper notesDBHelper;
    CrossReferenceDBHelper crossReferenceDBHelper;

    private MenuItem addToNoteMenuItem;
    private BibleVerse selectedVerse;
    private String selectedBook;
    private int selectedChapter;

    // Add navigation intent data
    private String navBookName;
    private int navChapter;
    private int navVerse;
    private boolean hasNavigationParams = false;
    private boolean isLanguageSwitching = false;

    private LinearLayout layoutMultiVerseActions;
    private ImageButton btnHighlight, btnShareText, btnShareImage, btnCopy;
    private ImageButton btnAddNote;
    private ImageButton btnCrossReferences;
    private int[] availableColors = new int[] {
        0xFFFFFF00, // Yellow
        0xFF00FF00, // Green
        0xFF00FFFF, // Cyan
        0xFFFFA500, // Orange
        0xFFFF69B4, // Pink
        0xFF87CEEB, // Light Blue
        0xFFFFFFFF  // White (no highlight)
    };

    // Audio Bible functionality
    private LinearLayout layoutAudioPlayer;
    private TextView tvAudioTitle, tvCurrentTime, tvTotalTime;
    private ImageButton btnPlayPause, btnPreviousChapter, btnNextChapter, btnCloseAudio;
    private SeekBar seekBarAudio;
    private MediaPlayer mediaPlayer;
    private Handler audioHandler = new Handler();
    private boolean isAudioPrepared = false;
    private boolean isAutoPlayNext = true;

    // Audio Bible data
    private String[] versionCodes = {"1", "29"}; // English, Telugu
    private int selectedVersionIndex = 1; // Default to Telugu
    
    // Language state
    private boolean isEnglishMode = false; // Default to Telugu
    private Button btnTranslate;
    
    // PiP support
    private boolean isInPictureInPictureMode = false;
    private PictureInPictureParams.Builder pipParamsBuilder;

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

    // English book names in the same order
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

    // Chapters per book for audio Bible
    private int[] chaptersPerBook = {
            50, 40, 27, 36, 34, 24, 21, 4, 31, 24, 22, 25, 29, 36, 10, 13, 10, 42, 150, 31, 12, 8,
            66, 52, 5, 48, 12, 14, 3, 9, 1, 4, 7, 3, 3, 3, 2, 14, 4, 28, 16, 24, 21, 28, 16, 16, 13,
            6, 6, 4, 4, 5, 3, 6, 4, 3, 1, 13, 5, 5, 3, 5, 1, 1, 1, 22
    };

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

    List<BibleVerse> verses = new ArrayList<>();
    private List<BibleVerse> versesToAddToNote = new ArrayList<>();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bible);

        // Set up toolbar/actionbar
        getSupportActionBar().setTitle("Bible");
        getSupportActionBar().setSubtitle("Read & Listen");
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        bookSpinner = findViewById(R.id.spinnerBook);
        chapterSpinner = findViewById(R.id.spinnerChapter);
        verseSpinner = findViewById(R.id.spinnerVerse);
        verseRecyclerView = findViewById(R.id.recyclerViewVerses);
        btnTranslate = findViewById(R.id.btnTranslate);

        // Multi-verse action bar
        layoutMultiVerseActions = findViewById(R.id.layoutMultiVerseActions);
        btnHighlight = findViewById(R.id.btnHighlight);
        btnShareText = findViewById(R.id.btnShareText);
        btnShareImage = findViewById(R.id.btnShareImage);
        btnCopy = findViewById(R.id.btnCopy);
        btnAddNote = findViewById(R.id.btnAddNote);
        btnCrossReferences = findViewById(R.id.btnCrossReferences);

        // Audio player views
        layoutAudioPlayer = findViewById(R.id.layoutAudioPlayer);
        tvAudioTitle = findViewById(R.id.tvAudioTitle);
        tvCurrentTime = findViewById(R.id.tvCurrentTime);
        tvTotalTime = findViewById(R.id.tvTotalTime);
        btnPlayPause = findViewById(R.id.btnPlayPause);
        btnPreviousChapter = findViewById(R.id.btnPreviousChapter);
        btnNextChapter = findViewById(R.id.btnNextChapter);
        btnCloseAudio = findViewById(R.id.btnCloseAudio);
        seekBarAudio = findViewById(R.id.seekBarAudio);

        dbHelper = new BibleDBHelper(this);
        notesDBHelper = new NotesDBHelper(this);
        crossReferenceDBHelper = new CrossReferenceDBHelper(this);

        // Check if we need to navigate to a specific verse and store parameters
        checkForNavigationParameters();

        // Set book spinner with correct language
        String[] initialBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, initialBooks);
        bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        bookSpinner.setAdapter(bookAdapter);

        bookSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                // Skip normal behavior during language switching
                if (isLanguageSwitching) {
                    return;
                }
                
                String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
                selectedBook = currentBooks[position];
                
                if (isEnglishMode) {
                    // Use KJV database for English
                    KJVBibleDBHelper kjvDbHelper = new KJVBibleDBHelper(BibleActivity.this);
                    String mappedBookName = mapToKJVBookName(selectedBook);
                    List<Integer> chapters = kjvDbHelper.getChaptersForBook(mappedBookName);
                    kjvDbHelper.close();
                    
                    ArrayAdapter<Integer> chapAdapter = new ArrayAdapter<>(BibleActivity.this, android.R.layout.simple_spinner_item, chapters);
                    chapAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                    chapterSpinner.setAdapter(chapAdapter);
                } else {
                    // Use Telugu database
                    List<Integer> chapters = dbHelper.getChapters(selectedBook);
                    ArrayAdapter<Integer> chapAdapter = new ArrayAdapter<>(BibleActivity.this, android.R.layout.simple_spinner_item, chapters);
                    chapAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                    chapterSpinner.setAdapter(chapAdapter);
                }

                // If we have navigation parameters and this is the right book, select the chapter
                if (hasNavigationParams && selectedBook.equals(navBookName)) {
                    // Find and select the correct chapter
                    List<Integer> chapters;
                    if (isEnglishMode) {
                        KJVBibleDBHelper kjvDbHelper = new KJVBibleDBHelper(BibleActivity.this);
                        String mappedBookName = mapToKJVBookName(selectedBook);
                        chapters = kjvDbHelper.getChaptersForBook(mappedBookName);
                        kjvDbHelper.close();
                    } else {
                        chapters = dbHelper.getChapters(selectedBook);
                    }
                    
                    for (int i = 0; i < chapters.size(); i++) {
                        if (chapters.get(i) == navChapter) {
                            chapterSpinner.setSelection(i);
                            break;
                        }
                    }
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        chapterSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                // Skip normal behavior during language switching
                if (isLanguageSwitching) {
                    return;
                }
                
                selectedChapter = (int) chapterSpinner.getSelectedItem();

                if (isEnglishMode) {
                    // Use KJV database for English
                    KJVBibleDBHelper kjvDbHelper = new KJVBibleDBHelper(BibleActivity.this);
                    String mappedBookName = mapToKJVBookName(selectedBook);
                    List<Verse> kjvVerses = kjvDbHelper.getVersesForChapterRange(mappedBookName, selectedChapter);
                    kjvDbHelper.close();
                    
                    // Convert KJV verses to BibleVerse format
                    verses.clear();
                    for (Verse kjvVerse : kjvVerses) {
                        BibleVerse bibleVerse = new BibleVerse(kjvVerse.getVerseNumber(), kjvVerse.getVerseText());
                        verses.add(bibleVerse);
                    }
                } else {
                    // Use Telugu database
                    verses = dbHelper.getVerses(selectedBook, selectedChapter);
                }
                
                setupVerseAdapter();

                List<Integer> verseNums = new ArrayList<>();
                for (BibleVerse v : verses) verseNums.add(v.verseNum);
                ArrayAdapter<Integer> verseAdapterSpinner = new ArrayAdapter<>(BibleActivity.this, android.R.layout.simple_spinner_item, verseNums);
                verseAdapterSpinner.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                verseSpinner.setAdapter(verseAdapterSpinner);

                // If we have navigation parameters and this is the right chapter, select the verse
                if (hasNavigationParams && selectedBook.equals(navBookName) && selectedChapter == navChapter) {
                    for (int i = 0; i < verseNums.size(); i++) {
                        if (verseNums.get(i) == navVerse) {
                            verseSpinner.setSelection(i);
                            break;
                        }
                    }
                    // Reset navigation flag after we've navigated
                    hasNavigationParams = false;
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        verseSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                verseRecyclerView.scrollToPosition(position);
                verseAdapter.highlightPosition(position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        // Start the navigation at the appropriate book if needed
        if (hasNavigationParams) {
            String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
            for (int i = 0; i < currentBooks.length; i++) {
                if (currentBooks[i].equals(navBookName)) {
                    bookSpinner.setSelection(i);
                    break;
                }
            }
        }

        // Setup multi-verse action listeners
        btnHighlight.setOnClickListener(v -> showHighlightColorDialogForSelectedVerses());
        btnShareText.setOnClickListener(v -> shareSelectedVersesAsText());
        btnShareImage.setOnClickListener(v -> shareSelectedVersesAsImage());
        btnCopy.setOnClickListener(v -> copySelectedVersesToClipboard());
        btnAddNote.setOnClickListener(v -> addSelectedVersesToNote());
        btnCrossReferences.setOnClickListener(v -> showCrossReferencesForSelectedVerses());
        
        // Setup translate button listener
        btnTranslate.setOnClickListener(v -> toggleLanguage());
        
        // Set initial button text
        btnTranslate.setText(isEnglishMode ? "TE" : "EN");

        // Setup audio player listeners
        setupAudioPlayerListeners();
        
        // Initialize PiP
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            pipParamsBuilder = new PictureInPictureParams.Builder();
        }

        // Initialize cross references database  
        initializeCrossReferencesDatabase();
    }

    private void setupAudioPlayerListeners() {
        btnPlayPause.setOnClickListener(v -> toggleAudioPlayPause());
        btnPreviousChapter.setOnClickListener(v -> playPreviousChapter());
        btnNextChapter.setOnClickListener(v -> playNextChapter());
        btnCloseAudio.setOnClickListener(v -> closeAudioPlayer());

        seekBarAudio.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && isAudioPrepared && mediaPlayer != null) {
                    mediaPlayer.seekTo(progress);
                    tvCurrentTime.setText(formatTime(progress));
                }
            }
            @Override public void onStartTrackingTouch(SeekBar seekBar) { /* No action */ }
            @Override public void onStopTrackingTouch(SeekBar seekBar) { /* No action */ }
        });
    }

    private void setupVerseAdapter() {
        verseAdapter = new BibleVerseAdapter(verses);
        verseRecyclerView.setLayoutManager(new LinearLayoutManager(BibleActivity.this));
        verseRecyclerView.setAdapter(verseAdapter);

        // Load highlight colors from DB
        List<Integer> highlightColors = new ArrayList<>();
        for (BibleVerse v : verses) {
            int color = notesDBHelper.getVerseHighlightColor(selectedBook, selectedChapter, v.verseNum);
            highlightColors.add(color);
        }
        verseAdapter.setHighlightColors(highlightColors);

        verseAdapter.setOnSelectionChangedListener(selectedPositions -> {
            if (selectedPositions != null && !selectedPositions.isEmpty()) {
                layoutMultiVerseActions.setVisibility(View.VISIBLE);
            } else {
                layoutMultiVerseActions.setVisibility(View.GONE);
            }
        });

        verseAdapter.setOnAddNoteClickListener((verse, position) -> {
            selectedVerse = verse;
            showAddToNoteDialog();
        });
        verseAdapter.setOnHighlightColorChangedListener((verse, position, color) -> {
            // Optionally persist highlight color for this verse
            // For now, just visual
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_bible, menu);
        addToNoteMenuItem = menu.findItem(R.id.action_add_to_note);
        addToNoteMenuItem.setVisible(false); // Initially hidden until a verse is long-clicked
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        int id = item.getItemId();

        if (id == android.R.id.home) {
            onBackPressed();
            return true;
        } else if (id == R.id.action_play_audio) {
            startAudioBible();
            return true;
        } else if (id == R.id.action_add_to_note) {
            if (selectedVerse != null) {
                showAddToNoteDialog();
            }
            return true;
        } else if (id == R.id.action_notes) {
            // Open NotesActivity
            Intent intent = new Intent(BibleActivity.this, NotesActivity.class);
            startActivity(intent);
            return true;
        } else if (id == R.id.action_settings) {
            openSettings();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    // Audio Bible Methods
    private void startAudioBible() {
        if (selectedBook == null || selectedChapter == 0) {
            Toast.makeText(this, "Please select a book and chapter first", Toast.LENGTH_SHORT).show();
            return;
        }

        layoutAudioPlayer.setVisibility(View.VISIBLE);
        updateAudioTitle();
        
        // Show loading message
        showLoadingMessage();
        
        loadAudioChapter(selectedChapter, true);
    }
    
    private void showLoadingMessage() {
        // Find book index using correct language array
        int bookIndex = -1;
        String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        for (int i = 0; i < currentBooks.length; i++) {
            if (currentBooks[i].equals(selectedBook)) {
                bookIndex = i;
                break;
            }
        }
        
        if (bookIndex != -1) {
            int bookApiIndex = bookIndex + 1;
            // Use English version (0) for English mode, Telugu version (1) for Telugu mode
            int versionIndex = isEnglishMode ? 0 : 1;
            String versionCode = versionCodes[versionIndex];
            String testUrl = "http://kjv.wordfree.net/bibles/app/audio/" + versionCode + "/" + bookApiIndex + "/" + selectedChapter + ".mp3";
            if (versionCode.equals("29")) {
                testUrl = "http://audio4.wordfree.net/bibles/app/audio/" + versionCode + "/" + bookApiIndex + "/" + selectedChapter + ".mp3";
            }
            Toast.makeText(this, "Loading audio...", Toast.LENGTH_SHORT).show();
        }
    }

    private void updateAudioTitle() {
        String title = selectedBook + " - Chapter " + selectedChapter;
        tvAudioTitle.setText(title);
    }

    private void loadAudioChapter(int chapter, boolean autoPlay) {
        resetAudioPlayer();
        setAudioControlsEnabled(false);
        isAudioPrepared = false;

        // Find book index using correct language array
        int bookIndex = -1;
        String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        for (int i = 0; i < currentBooks.length; i++) {
            if (currentBooks[i].equals(selectedBook)) {
                bookIndex = i;
                break;
            }
        }

        if (bookIndex == -1 || chapter < 1 || chapter > chaptersPerBook[bookIndex]) {
            Toast.makeText(this, "Invalid chapter for audio", Toast.LENGTH_SHORT).show();
            btnPlayPause.setImageResource(R.drawable.ic_play_vector);
            return;
        }

        int bookApiIndex = bookIndex + 1;
        // Use English version (0) for English mode, Telugu version (1) for Telugu mode
        int versionIndex = isEnglishMode ? 0 : 1;
        String versionCode = versionCodes[versionIndex];
        String audioUrl = "http://kjv.wordfree.net/bibles/app/audio/" + versionCode + "/" + bookApiIndex + "/" + chapter + ".mp3";
        if (versionCode.equals("29")) {
            audioUrl = "http://audio4.wordfree.net/bibles/app/audio/" + versionCode + "/" + bookApiIndex + "/" + chapter + ".mp3";
        }

        mediaPlayer = new MediaPlayer();
        try {
            mediaPlayer.setDataSource(audioUrl);
            mediaPlayer.setOnPreparedListener(mp -> {
                isAudioPrepared = true;
                setAudioControlsEnabled(true);
                seekBarAudio.setMax(mp.getDuration());
                tvTotalTime.setText(formatTime(mp.getDuration()));
                tvCurrentTime.setText(formatTime(0));
                seekBarAudio.setProgress(0);

                if (autoPlay) {
                    mp.start();
                    btnPlayPause.setImageResource(R.drawable.ic_pause_vector);
                    audioHandler.post(updateAudioSeekBar);
                } else {
                    btnPlayPause.setImageResource(R.drawable.ic_play_vector);
                }
            });

            mediaPlayer.setOnCompletionListener(mp -> {
                btnPlayPause.setImageResource(R.drawable.ic_play_vector);
                audioHandler.removeCallbacks(updateAudioSeekBar);
                if (mediaPlayer != null && isAudioPrepared) {
                    try {
                        seekBarAudio.setProgress(0);
                        tvCurrentTime.setText(formatTime(0));
                    } catch (Exception e) { /* Ignore */ }
                }
                isAudioPrepared = false;

                // Auto-play next chapter
                if (isAutoPlayNext) {
                    playNextChapter();
                }
            });

            mediaPlayer.setOnErrorListener((mp, what, extra) -> {
                String errorMsg = "Audio Error: " + what + " (Extra: " + extra + ")";
                Toast.makeText(BibleActivity.this, errorMsg, Toast.LENGTH_LONG).show();
                resetAudioPlayer();
                setAudioControlsEnabled(false);
                btnPlayPause.setImageResource(R.drawable.ic_play_vector);
                return true;
            });

            mediaPlayer.prepareAsync();

        } catch (IOException e) {
            Toast.makeText(this, "Cannot load audio: " + e.getMessage(), Toast.LENGTH_LONG).show();
            resetAudioPlayer();
            setAudioControlsEnabled(false);
            btnPlayPause.setImageResource(R.drawable.ic_play_vector);
        }
    }

    private void toggleAudioPlayPause() {
        if (mediaPlayer == null) {
            loadAudioChapter(selectedChapter, true);
            return;
        }
        if (!isAudioPrepared) {
            Toast.makeText(this, "Audio loading...", Toast.LENGTH_SHORT).show();
            return;
        }

        if (mediaPlayer.isPlaying()) {
            mediaPlayer.pause();
            btnPlayPause.setImageResource(R.drawable.ic_play_vector);
            audioHandler.removeCallbacks(updateAudioSeekBar);
        } else {
            mediaPlayer.start();
            btnPlayPause.setImageResource(R.drawable.ic_pause_vector);
            audioHandler.post(updateAudioSeekBar);
        }
    }

    private void playPreviousChapter() {
        if (selectedChapter > 1) {
            selectedChapter--;
            updateAudioTitle();
            loadAudioChapter(selectedChapter, true);
        } else {
            Toast.makeText(this, "First chapter of the book", Toast.LENGTH_SHORT).show();
        }
    }

    private void playNextChapter() {
        // Find book index using correct language array
        int bookIndex = -1;
        String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        for (int i = 0; i < currentBooks.length; i++) {
            if (currentBooks[i].equals(selectedBook)) {
                bookIndex = i;
                break;
            }
        }

        if (bookIndex == -1) return;

        int maxChapters = chaptersPerBook[bookIndex];
        if (selectedChapter < maxChapters) {
            selectedChapter++;
            updateAudioTitle();
            loadAudioChapter(selectedChapter, true);
        } else {
            Toast.makeText(this, "Last chapter of the book", Toast.LENGTH_SHORT).show();
        }
    }

    private void closeAudioPlayer() {
        resetAudioPlayer();
        if (!isInPictureInPictureMode) {
            layoutAudioPlayer.setVisibility(View.GONE);
        }
        // Exit PiP mode if in PiP
        if (isInPictureInPictureMode && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            try {
                moveTaskToBack(true);
            } catch (Exception e) {
                // Handle exception
            }
        }
    }

    private void resetAudioPlayer() {
        if (mediaPlayer != null) {
            audioHandler.removeCallbacks(updateAudioSeekBar);
            try {
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.stop();
                }
                mediaPlayer.reset();
                mediaPlayer.release();
            } catch (Exception e) { /* Ignore */ }
            mediaPlayer = null;
        }
        isAudioPrepared = false;
        seekBarAudio.setProgress(0);
        tvCurrentTime.setText("00:00");
        tvTotalTime.setText("00:00");
    }

    private void setAudioControlsEnabled(boolean enabled) {
        btnPlayPause.setEnabled(enabled);
        seekBarAudio.setEnabled(enabled);
        btnPreviousChapter.setEnabled(enabled && selectedChapter > 1);
        
        // Find book index for next button using correct language array
        int bookIndex = -1;
        String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        for (int i = 0; i < currentBooks.length; i++) {
            if (currentBooks[i].equals(selectedBook)) {
                bookIndex = i;
                break;
            }
        }
        boolean canGoNext = enabled && bookIndex != -1 && selectedChapter < chaptersPerBook[bookIndex];
        btnNextChapter.setEnabled(canGoNext);
    }

    private final Runnable updateAudioSeekBar = new Runnable() {
        public void run() {
            if (isAudioPrepared && mediaPlayer != null && mediaPlayer.isPlaying()) {
                try {
                    int current = mediaPlayer.getCurrentPosition();
                    seekBarAudio.setProgress(current);
                    tvCurrentTime.setText(formatTime(current));
                    audioHandler.postDelayed(this, 500);
                } catch (IllegalStateException e) {
                    audioHandler.removeCallbacks(this);
                }
            } else {
                audioHandler.removeCallbacks(this);
            }
        }
    };

    private String formatTime(int millis) {
        if (millis < 0) millis = 0;
        long minutes = TimeUnit.MILLISECONDS.toMinutes(millis);
        long seconds = TimeUnit.MILLISECONDS.toSeconds(millis) - TimeUnit.MINUTES.toSeconds(minutes);
        return String.format("%02d:%02d", minutes, seconds);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        resetAudioPlayer();
        
        // Close database connections
        if (crossReferenceDBHelper != null) {
            crossReferenceDBHelper.close();
        }
    }
    
    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        this.isInPictureInPictureMode = isInPictureInPictureMode;
        
        if (isInPictureInPictureMode) {
            // Hide UI elements that are not needed in PiP mode
            hideUIForPiP();
            // Show audio player in PiP mode
            if (layoutAudioPlayer != null) {
                layoutAudioPlayer.setVisibility(View.VISIBLE);
            }
        } else {
            // Show UI elements when exiting PiP mode
            showUIForPiP();
        }
    }
    
    @Override
    public void onUserLeaveHint() {
        super.onUserLeaveHint();
        // Enter PiP mode when user leaves the app and audio is playing
        if (mediaPlayer != null && mediaPlayer.isPlaying() && 
            android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startPictureInPictureMode();
        }
    }
    
    private void startPictureInPictureMode() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O && pipParamsBuilder != null) {
            try {
                // Set aspect ratio for PiP window
                Rational aspectRatio = new Rational(16, 9);
                pipParamsBuilder.setAspectRatio(aspectRatio);
                
                // Enter PiP mode
                enterPictureInPictureMode(pipParamsBuilder.build());
            } catch (Exception e) {
                // PiP not supported or failed
            }
        }
    }
    
    private void hideUIForPiP() {
        // Hide unnecessary UI elements in PiP mode
        if (layoutMultiVerseActions != null) {
            layoutMultiVerseActions.setVisibility(View.GONE);
        }
        if (verseRecyclerView != null) {
            verseRecyclerView.setVisibility(View.GONE);
        }
        if (bookSpinner != null) {
            bookSpinner.setVisibility(View.GONE);
        }
        if (chapterSpinner != null) {
            chapterSpinner.setVisibility(View.GONE);
        }
        if (verseSpinner != null) {
            verseSpinner.setVisibility(View.GONE);
        }
    }
    
    private void showUIForPiP() {
        // Show UI elements when exiting PiP mode
        if (layoutMultiVerseActions != null) {
            layoutMultiVerseActions.setVisibility(View.GONE); // Keep hidden unless needed
        }
        if (verseRecyclerView != null) {
            verseRecyclerView.setVisibility(View.VISIBLE);
        }
        if (bookSpinner != null) {
            bookSpinner.setVisibility(View.VISIBLE);
        }
        if (chapterSpinner != null) {
            chapterSpinner.setVisibility(View.VISIBLE);
        }
        if (verseSpinner != null) {
            verseSpinner.setVisibility(View.VISIBLE);
        }
    }
    
    private void setupPiPControls() {
        // Setup PiP-specific controls if needed
        if (isInPictureInPictureMode) {
            // Update PiP title
            if (tvAudioTitle != null) {
                tvAudioTitle.setText(selectedBook + " - Chapter " + selectedChapter);
            }
        }
    }

    /**
     * Initialize cross references database
     */
    private void initializeCrossReferencesDatabase() {
        new Thread(() -> {
            try {
                // Check if database has data
                int totalReferences = crossReferenceDBHelper.getTotalReferences();
                
                runOnUiThread(() -> {
                    if (totalReferences > 0) {
                        Log.d("BibleActivity", "Cross references database loaded successfully with " + totalReferences + " references");
                        Toast.makeText(BibleActivity.this, 
                            "Cross references loaded: " + totalReferences + " references", 
                            Toast.LENGTH_SHORT).show();
                    } else {
                        Log.w("BibleActivity", "Cross references database is empty");
                        Toast.makeText(BibleActivity.this, 
                            "Cross references database is empty", 
                            Toast.LENGTH_SHORT).show();
                    }
                });
                
            } catch (Exception e) {
                Log.e("BibleActivity", "Error initializing cross references: " + e.getMessage());
                runOnUiThread(() -> {
                    Toast.makeText(BibleActivity.this, 
                        "Error loading cross references: " + e.getMessage(), 
                        Toast.LENGTH_SHORT).show();
                });
            }
        }).start();
    }

    private void checkForNavigationParameters() {
        Intent intent = getIntent();
        if (intent != null && intent.hasExtra("BOOK_NAME") &&
                intent.hasExtra("CHAPTER") && intent.hasExtra("VERSE")) {

            navBookName = intent.getStringExtra("BOOK_NAME");
            navChapter = intent.getIntExtra("CHAPTER", 1);
            navVerse = intent.getIntExtra("VERSE", 1);
            
            // Check if language mode is specified
            if (intent.hasExtra("IS_ENGLISH_MODE")) {
                isEnglishMode = intent.getBooleanExtra("IS_ENGLISH_MODE", false);
            }
            
            hasNavigationParams = true;
        }
    }

    private void showAddToNoteDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Add to Note");

        // Get all notes
        List<Note> notes = notesDBHelper.getAllNotes();
        List<String> noteOptions = new ArrayList<>();
        noteOptions.add("Create New Note");

        for (Note note : notes) {
            noteOptions.add(note.getTitle());
        }

        // Create dialog view
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_add_to_note, null);
        Spinner noteSpinner = view.findViewById(R.id.spinnerNotes);

        ArrayAdapter<String> adapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, noteOptions);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        noteSpinner.setAdapter(adapter);

        builder.setView(view);

        builder.setPositiveButton("Add", (dialog, which) -> {
            int selectedPosition = noteSpinner.getSelectedItemPosition();

            if (selectedPosition == 0) {
                // Create new note
                showCreateNoteDialog();
            } else {
                // Add to existing note
                Note selectedNote = notes.get(selectedPosition - 1); // -1 because we added "Create New Note" at position 0
                addVersesToNote(selectedNote);
            }
        });

        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    private void showCreateNoteDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Create New Note");

        View view = LayoutInflater.from(this).inflate(R.layout.dialog_create_note, null);
        EditText titleEditText = view.findViewById(R.id.editTextNoteTitle);

        // Set default title as verse reference
        String defaultTitle = selectedBook + " " + selectedChapter + ":" + selectedVerse.verseNum;
        titleEditText.setText(defaultTitle);

        builder.setView(view);

        builder.setPositiveButton("Create", (dialog, which) -> {
            String title = titleEditText.getText().toString().trim();

            if (!title.isEmpty()) {
                Note newNote = new Note(0, title);
                long noteId = notesDBHelper.createNote(newNote);

                if (noteId > 0) {
                    newNote.setId(noteId);
                    addVersesToNote(newNote);
                }
            } else {
                Toast.makeText(this, "Title cannot be empty", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    private void addVersesToNote(Note note) {
        boolean allSuccess = true;
        for (BibleVerse v : versesToAddToNote) {
            VerseReference reference = new VerseReference(
                    selectedBook,
                    selectedChapter,
                    v.verseNum,
                    v.verseText);
            long id = notesDBHelper.addVerseReferenceToNote(note.getId(), reference);
            if (id <= 0) allSuccess = false;
        }
        if (allSuccess) {
            Toast.makeText(this, "Added to note: " + note.getTitle(), Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(this, "Failed to add some verses to note", Toast.LENGTH_SHORT).show();
        }
        if (addToNoteMenuItem != null) {
            addToNoteMenuItem.setVisible(false);
        }
        selectedVerse = null;
        versesToAddToNote.clear();
    }

    // --- Multi-verse Action Handlers ---
    private void showHighlightColorDialogForSelectedVerses() {
        String[] colorNames = {"Yellow", "Green", "Cyan", "Orange", "Pink", "Light Blue", "None"};
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Select Highlight Color");
        builder.setItems(colorNames, (dialog, which) -> {
            int color = availableColors[which];
            List<Integer> selectedPositions = new ArrayList<>(verseAdapter.getSelectedPositions());
            for (int pos : selectedPositions) {
                BibleVerse v = verses.get(pos);
                notesDBHelper.setVerseHighlightColor(selectedBook, selectedChapter, v.verseNum, color);
                verseAdapter.setHighlightColor(pos, color);
            }
            Toast.makeText(this, "Highlight color applied", Toast.LENGTH_SHORT).show();
            verseAdapter.clearSelection();
        });
        builder.show();
    }

    private void addSelectedVersesToNote() {
        List<BibleVerse> selected = verseAdapter.getSelectedVerses();
        if (selected.isEmpty()) return;
        versesToAddToNote = new ArrayList<>(selected);
        selectedVerse = selected.get(0); // For default title
        showAddToNoteDialog();
        verseAdapter.clearSelection();
    }

    private void highlightSelectedVerses() {
        for (int pos : verseAdapter.getSelectedPositions()) {
            // You can update your data model here if you want to persist highlights
            // For now, just visually highlight
            // Already handled by adapter's selection color
        }
        Toast.makeText(this, "Highlighted selected verses", Toast.LENGTH_SHORT).show();
        verseAdapter.clearSelection();
    }

    private void shareSelectedVersesAsText() {
        List<BibleVerse> selected = verseAdapter.getSelectedVerses();
        if (selected.isEmpty()) return;
        StringBuilder sb = new StringBuilder();
        for (BibleVerse v : selected) {
            sb.append(selectedBook).append(" ")
              .append(selectedChapter).append(":")
              .append(v.verseNum).append(" - ")
              .append(v.verseText).append("\n");
        }
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.putExtra(Intent.EXTRA_TEXT, sb.toString());
        sendIntent.setType("text/plain");
        startActivity(Intent.createChooser(sendIntent, "Share Verses"));
        verseAdapter.clearSelection();
    }

    private void copySelectedVersesToClipboard() {
        List<BibleVerse> selected = verseAdapter.getSelectedVerses();
        if (selected.isEmpty()) return;
        StringBuilder sb = new StringBuilder();
        for (BibleVerse v : selected) {
            sb.append(selectedBook).append(" ")
              .append(selectedChapter).append(":")
              .append(v.verseNum).append(" - ")
              .append(v.verseText).append("\n");
        }
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("Bible Verses", sb.toString());
        clipboard.setPrimaryClip(clip);
        Toast.makeText(this, "Copied to clipboard", Toast.LENGTH_SHORT).show();
        verseAdapter.clearSelection();
    }

    private void shareSelectedVersesAsImage() {
        List<BibleVerse> selected = verseAdapter.getSelectedVerses();
        if (selected.isEmpty()) return;
        ArrayList<String> verseTexts = new ArrayList<>();
        for (BibleVerse v : selected) {
            verseTexts.add(selectedBook + " " + selectedChapter + ":" + v.verseNum + " - " + v.verseText);
        }
        Intent intent = new Intent(this, ShareVerseImageActivity.class);
        intent.putStringArrayListExtra("VERSES", verseTexts);
        startActivity(intent);
        verseAdapter.clearSelection();
    }

    // Cross References Methods
    private void showCrossReferencesForSelectedVerses() {
        List<BibleVerse> selected = verseAdapter.getSelectedVerses();
        if (selected.isEmpty()) {
            Toast.makeText(this, "Please select a verse first", Toast.LENGTH_SHORT).show();
            return;
        }

        // For now, show cross references for the first selected verse
        BibleVerse verse = selected.get(0);
        showCrossReferencesForVerse(verse);
        verseAdapter.clearSelection();
    }

    private void showCrossReferencesForVerse(BibleVerse verse) {
        // Get cross references from database with language support
        List<CrossReference.Reference> references = crossReferenceDBHelper.getCrossReferences(selectedBook, selectedChapter, verse.verseNum, isEnglishMode);

        if (references.isEmpty()) {
            Toast.makeText(this, "No cross references found for this verse", Toast.LENGTH_SHORT).show();
            return;
        }

        // Create dialog
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_cross_references, null);
        builder.setView(dialogView);

        // Set up dialog views
        TextView tvSourceVerse = dialogView.findViewById(R.id.tvSourceVerse);
        TextView tvSourceText = dialogView.findViewById(R.id.tvSourceText);
        RecyclerView rvCrossReferences = dialogView.findViewById(R.id.rvCrossReferences);
        TextView tvNoReferences = dialogView.findViewById(R.id.tvNoReferences);

        // Set source verse info
        tvSourceVerse.setText(selectedBook + " " + selectedChapter + ":" + verse.verseNum);
        tvSourceText.setText(verse.verseText);

        // Set up RecyclerView
        rvCrossReferences.setLayoutManager(new LinearLayoutManager(this));

        if (references.isEmpty()) {
            tvNoReferences.setVisibility(View.VISIBLE);
            rvCrossReferences.setVisibility(View.GONE);
        } else {
            tvNoReferences.setVisibility(View.GONE);
            rvCrossReferences.setVisibility(View.VISIBLE);
            
            CrossReferenceAdapter adapter = new CrossReferenceAdapter(this, references, reference -> {
                // Navigate to the referenced verse
                navigateToVerse(reference.getBook(), reference.getChapter(), reference.getVerse());
            });
            rvCrossReferences.setAdapter(adapter);
        }

        // Create and show dialog
        AlertDialog dialog = builder.create();
        dialog.show();
    }

    private void navigateToVerse(String book, int chapter, int verse) {
        // Find the book index based on current language
        int bookIndex = -1;
        String[] currentBooks = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        
        for (int i = 0; i < currentBooks.length; i++) {
            if (currentBooks[i].equals(book)) {
                bookIndex = i;
                break;
            }
        }

        if (bookIndex == -1) {
            Toast.makeText(this, "Book not found: " + book, Toast.LENGTH_SHORT).show();
            return;
        }

        // Set navigation parameters
        navBookName = book;
        navChapter = chapter;
        navVerse = verse;
        hasNavigationParams = true;

        // Update book spinner - this will trigger the chapter loading
        bookSpinner.setSelection(bookIndex);

        // Wait for the spinners to update and then scroll to the verse
        new Handler().postDelayed(() -> {
            if (verses != null) {
                for (int i = 0; i < verses.size(); i++) {
                    if (verses.get(i).verseNum == verse) {
                        verseRecyclerView.scrollToPosition(i);
                        // Highlight the verse briefly
                        verseAdapter.highlightVerseTemporarily(i);
                        break;
                    }
                }
            }
        }, 1000);

        Toast.makeText(this, "Navigated to " + book + " " + chapter + ":" + verse, Toast.LENGTH_SHORT).show();
    }
    
    private void toggleLanguage() {
        isEnglishMode = !isEnglishMode;
        
        // Update button text - show the language you can switch TO
        btnTranslate.setText(isEnglishMode ? "TE" : "EN");
        
        // Update title
        if (getSupportActionBar() != null) {
            getSupportActionBar().setSubtitle("Read & Listen - " + (isEnglishMode ? "English" : "Telugu"));
        }
        
        // Set language switching flag
        isLanguageSwitching = true;
        
        // Reload current book data with new language
        reloadCurrentBookData();
        
        // Reset the flag after a short delay
        new Handler().postDelayed(() -> {
            isLanguageSwitching = false;
        }, 1000);
        
        Toast.makeText(this, 
            isEnglishMode ? "Switched to English Bible" : "Switched to Telugu Bible", 
            Toast.LENGTH_SHORT).show();
    }
    
    private void reloadCurrentBookData() {
        if (selectedBook == null) return;
        
        // Get current book index from the spinner position (not by name matching)
        int currentBookIndex = bookSpinner.getSelectedItemPosition();
        
        // Ensure the index is valid for the new language
        String[] booksToUse = isEnglishMode ? ENGLISH_BOOKS_IN_ORDER : BOOKS_IN_ORDER;
        if (currentBookIndex >= booksToUse.length) {
            currentBookIndex = 0; // Default to first book if index is out of bounds
        }
        
        // Update book spinner with new language
        ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, booksToUse);
        bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        bookSpinner.setAdapter(bookAdapter);
        
        // Set selection to current book index
        bookSpinner.setSelection(currentBookIndex);
        
        // Update selected book
        selectedBook = booksToUse[currentBookIndex];
        
        // Load chapters for the new book
        loadChaptersForCurrentBook();
    }
    
    private void loadChaptersForCurrentBook() {
        if (selectedBook == null) return;
        
        // Store current chapter to maintain position
        int currentChapter = selectedChapter;
        
        List<Integer> chapters;
        if (isEnglishMode) {
            // Use KJV database for English
            KJVBibleDBHelper kjvDbHelper = new KJVBibleDBHelper(this);
            String mappedBookName = mapToKJVBookName(selectedBook);
            chapters = kjvDbHelper.getChaptersForBook(mappedBookName);
            kjvDbHelper.close();
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
        
        // Try to maintain the same chapter, or use first chapter if not available
        if (currentChapter > 0 && chapters.contains(currentChapter)) {
            selectedChapter = currentChapter;
            int chapterIndex = chapters.indexOf(currentChapter);
            chapterSpinner.setSelection(chapterIndex);
        } else if (chapters.size() > 0) {
            selectedChapter = chapters.get(0);
        }
        
        loadVersesForCurrentChapter();
    }
    
    private void loadVersesForCurrentChapter() {
        if (selectedBook == null || selectedChapter <= 0) return;
        
        // Store current verse to maintain position
        int currentVerse = 1; // Default to first verse
        if (verseSpinner.getSelectedItem() != null) {
            currentVerse = (int) verseSpinner.getSelectedItem();
        }
        
        if (isEnglishMode) {
            // Use KJV database for English
            KJVBibleDBHelper kjvDbHelper = new KJVBibleDBHelper(this);
            String mappedBookName = mapToKJVBookName(selectedBook);
            List<Verse> kjvVerses = kjvDbHelper.getVersesForChapterRange(mappedBookName, selectedChapter);
            kjvDbHelper.close();
            
            // Convert KJV verses to BibleVerse format
            verses.clear();
            for (Verse kjvVerse : kjvVerses) {
                BibleVerse bibleVerse = new BibleVerse(kjvVerse.getVerseNumber(), kjvVerse.getVerseText());
                verses.add(bibleVerse);
            }
        } else {
            // Use Telugu database
            verses = dbHelper.getVerses(selectedBook, selectedChapter);
        }
        
        setupVerseAdapter();
        
        // Update verse spinner
        List<Integer> verseNums = new ArrayList<>();
        for (BibleVerse v : verses) verseNums.add(v.verseNum);
        ArrayAdapter<Integer> verseAdapterSpinner = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, verseNums);
        verseAdapterSpinner.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        verseSpinner.setAdapter(verseAdapterSpinner);
        
        // Try to maintain the same verse, or use first verse if not available
        if (verseNums.contains(currentVerse)) {
            int verseIndex = verseNums.indexOf(currentVerse);
            verseSpinner.setSelection(verseIndex);
        } else if (verseNums.size() > 0) {
            verseSpinner.setSelection(0);
        }
    }

    private void openSettings() {
        Intent intent = new Intent(BibleActivity.this, SettingsActivity.class);
        startActivity(intent);
    }
}