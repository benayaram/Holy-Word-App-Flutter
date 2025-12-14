package com.holywordapp;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.util.Log;
import android.os.AsyncTask;

import java.util.ArrayList;
import java.util.List;

public class CrossReferencesActivity extends AppCompatActivity {

    private Spinner bookSpinner, chapterSpinner, verseSpinner;
    private Button btnGo, btnTranslate;
    private RecyclerView rvCrossReferences;
    private TextView tvNoReferences;
    private View layoutCrossReferences;
    
    private BibleDBHelper dbHelper;
    private KJVBibleDBHelper kjvDbHelper;
    private CrossReferenceDBHelper crossReferenceDBHelper;
    
    // Translation state
    private boolean isEnglishMode = false;
    
    private String selectedBook;
    private int selectedChapter;
    private int selectedVerse;
    
    private List<BibleVerse> verses;
    private CrossReferenceAdapter adapter;

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
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            setContentView(R.layout.activity_cross_references);
            
            // Set up action bar
            if (getSupportActionBar() != null) {
                getSupportActionBar().setTitle("Cross References - " + (isEnglishMode ? "English" : "Telugu"));
                getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            }
            
            // Initialize basic views first
            initViews();
            
            // Initialize databases
            initDatabase();
            
            // Setup spinners and listeners
            setupSpinners();
            setupListeners();
            
        } catch (Exception e) {
            Toast.makeText(this, "Error initializing activity: " + e.getMessage(), Toast.LENGTH_LONG).show();
            e.printStackTrace();
            finish();
        }
    }

    private void initViews() {
        try {
            bookSpinner = findViewById(R.id.bookSpinner);
            chapterSpinner = findViewById(R.id.chapterSpinner);
            verseSpinner = findViewById(R.id.verseSpinner);
            btnGo = findViewById(R.id.btnGo);
            btnTranslate = findViewById(R.id.btnTranslate);
            rvCrossReferences = findViewById(R.id.rvCrossReferences);
            tvNoReferences = findViewById(R.id.tvNoReferences);
            layoutCrossReferences = findViewById(R.id.layoutCrossReferences);
            
            // Set up RecyclerView
            if (rvCrossReferences != null) {
                LinearLayoutManager layoutManager = new LinearLayoutManager(this);
                rvCrossReferences.setLayoutManager(layoutManager);
                rvCrossReferences.setNestedScrollingEnabled(false);
                rvCrossReferences.setHasFixedSize(false);
            }
        } catch (Exception e) {
            Toast.makeText(this, "Error initializing views: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }

    private void initDatabase() {
        try {
            dbHelper = new BibleDBHelper(this);
            kjvDbHelper = new KJVBibleDBHelper(this);
            crossReferenceDBHelper = new CrossReferenceDBHelper(this);

        } catch (Exception e) {
            Toast.makeText(this, "Database initialization failed: " + e.getMessage(), Toast.LENGTH_LONG).show();
            e.printStackTrace();
        }
    }

    private void setupSpinners() {
        try {
            // Set up book spinner based on current language
            List<String> books;
            if (isEnglishMode) {
                books = new ArrayList<>();
                for (String book : ENGLISH_BOOKS_IN_ORDER) {
                    books.add(book);
                }
            } else {
                books = new ArrayList<>();
                for (String book : BOOKS_IN_ORDER) {
                    books.add(book);
                }
            }
            
            ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, books);
            bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            bookSpinner.setAdapter(bookAdapter);

            bookSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    if (isEnglishMode) {
                        selectedBook = ENGLISH_BOOKS_IN_ORDER[position];
                    } else {
                        selectedBook = BOOKS_IN_ORDER[position];
                    }
                    loadChapters();
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {}
            });

            chapterSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    selectedChapter = (int) chapterSpinner.getSelectedItem();
                    loadVerses();
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {}
            });

            verseSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    selectedVerse = (int) verseSpinner.getSelectedItem();
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {}
            });


        } catch (Exception e) {
            Toast.makeText(this, "Error setting up spinners: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }

    private void loadChapters() {
        if (selectedBook == null) {
            Toast.makeText(this, "Please select a book first", Toast.LENGTH_SHORT).show();
            return;
        }
        
        new LoadChaptersTask().execute();
    }
    
    private class LoadChaptersTask extends AsyncTask<Void, Void, List<Integer>> {
        private Exception exception;
        
        @Override
        protected List<Integer> doInBackground(Void... voids) {
            try {
                List<Integer> chapters;
                if (isEnglishMode) {
                    String mappedBookName = mapToKJVBookName(selectedBook);
                    chapters = kjvDbHelper.getChaptersForBook(mappedBookName);
                    Log.d("CrossReferences", "Loading chapters for English book: " + selectedBook + " (mapped to: " + mappedBookName + "), found: " + chapters.size());
                } else {
                    chapters = dbHelper.getChapters(selectedBook);
                    Log.d("CrossReferences", "Loading chapters for Telugu book: " + selectedBook + ", found: " + chapters.size());
                }
                return chapters;
            } catch (Exception e) {
                exception = e;
                Log.e("CrossReferences", "Error loading chapters: " + e.getMessage());
                return new ArrayList<>();
            }
        }
        
        @Override
        protected void onPostExecute(List<Integer> chapters) {
            if (exception != null) {
                Toast.makeText(CrossReferencesActivity.this, 
                    "Error loading chapters: " + exception.getMessage(), 
                    Toast.LENGTH_SHORT).show();
                return;
            }
            
            if (chapters.isEmpty()) {
                Toast.makeText(CrossReferencesActivity.this, "No chapters found for " + selectedBook, Toast.LENGTH_SHORT).show();
                return;
            }
            
            ArrayAdapter<Integer> chapAdapter = new ArrayAdapter<>(CrossReferencesActivity.this, android.R.layout.simple_spinner_item, chapters);
            chapAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            chapterSpinner.setAdapter(chapAdapter);
            
            // Auto-select first chapter
            if (chapters.size() > 0) {
                selectedChapter = chapters.get(0);
                loadVerses();
            }
        }
    }

    private void loadVerses() {
        new LoadVersesTask().execute();
    }
    
    private class LoadVersesTask extends AsyncTask<Void, Void, List<Integer>> {
        private Exception exception;
        
        @Override
        protected List<Integer> doInBackground(Void... voids) {
            try {
                List<Integer> verseNums = new ArrayList<>();
                
                if (isEnglishMode) {
                    String mappedBookName = mapToKJVBookName(selectedBook);
                    List<Integer> verses = kjvDbHelper.getVersesForChapter(mappedBookName, selectedChapter);
                    verseNums.addAll(verses);
                    Log.d("CrossReferences", "Loaded " + verses.size() + " English verses for " + selectedBook + " (mapped to: " + mappedBookName + ") " + selectedChapter);
                } else {
                    List<BibleVerse> verses = dbHelper.getVerses(selectedBook, selectedChapter);
                    for (BibleVerse v : verses) verseNums.add(v.verseNum);
                    Log.d("CrossReferences", "Loaded " + verses.size() + " Telugu verses for " + selectedBook + " " + selectedChapter);
                }
                
                return verseNums;
            } catch (Exception e) {
                exception = e;
                Log.e("CrossReferences", "Error loading verses: " + e.getMessage());
                return new ArrayList<>();
            }
        }
        
        @Override
        protected void onPostExecute(List<Integer> verseNums) {
            if (exception != null) {
                Toast.makeText(CrossReferencesActivity.this, 
                    "Error loading verses: " + exception.getMessage(), 
                    Toast.LENGTH_SHORT).show();
                return;
            }
            
            ArrayAdapter<Integer> verseAdapter = new ArrayAdapter<>(CrossReferencesActivity.this, android.R.layout.simple_spinner_item, verseNums);
            verseAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            verseSpinner.setAdapter(verseAdapter);
            
            Log.d("CrossReferences", "Verse spinner set with " + verseNums.size() + " verses");
        }
    }

    private void setupListeners() {
        try {
            btnGo.setOnClickListener(v -> {
                if (selectedBook != null && selectedChapter > 0 && selectedVerse > 0) {
                    showCrossReferences();
                } else {
                    Toast.makeText(this, "Please select a book, chapter, and verse", Toast.LENGTH_SHORT).show();
                }
            });
            
            btnTranslate.setOnClickListener(v -> {
                toggleTranslation();
            });

        } catch (Exception e) {
            Toast.makeText(this, "Error setting up listeners: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }

    private void toggleTranslation() {
        // Store current selections before switching
        String currentBook = selectedBook;
        int currentChapter = selectedChapter;
        int currentVerse = selectedVerse;
        
        isEnglishMode = !isEnglishMode;
        
        // Update button text
        btnTranslate.setText(isEnglishMode ? "TE" : "EN");
        
        // Update title
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("Cross References - " + (isEnglishMode ? "English" : "Telugu"));
        }
        
        // Reload books data and setup spinners
        loadBooksData();
        setupSpinners();
        
        // If we had a previous selection, try to restore it
        if (currentBook != null && currentChapter > 0 && currentVerse > 0) {
            // Convert book name to appropriate language
            String targetBook = convertBookName(currentBook, !isEnglishMode);
            
            // Find the book position in the new language
            int bookPosition = findBookPosition(targetBook);
            if (bookPosition >= 0) {
                // Set the book spinner
                bookSpinner.setSelection(bookPosition);
                
                // Load chapters and verses for this book
                loadChapters();
            } else {
                // If book not found, clear selections
                clearSelections();
            }
        } else {
            clearSelections();
        }
        
        Toast.makeText(this, 
            isEnglishMode ? "Switched to English Bible" : "Switched to Telugu Bible", 
            Toast.LENGTH_SHORT).show();
    }
    
    private String convertBookName(String bookName, boolean fromEnglish) {
        if (fromEnglish) {
            // Convert from English to Telugu
            for (int i = 0; i < ENGLISH_BOOKS_IN_ORDER.length; i++) {
                if (ENGLISH_BOOKS_IN_ORDER[i].equals(bookName)) {
                    return BOOKS_IN_ORDER[i];
                }
            }
        } else {
            // Convert from Telugu to English
            for (int i = 0; i < BOOKS_IN_ORDER.length; i++) {
                if (BOOKS_IN_ORDER[i].equals(bookName)) {
                    return ENGLISH_BOOKS_IN_ORDER[i];
                }
            }
        }
        return bookName; // Return original if not found
    }
    
    private int findBookPosition(String bookName) {
        if (isEnglishMode) {
            for (int i = 0; i < ENGLISH_BOOKS_IN_ORDER.length; i++) {
                if (ENGLISH_BOOKS_IN_ORDER[i].equals(bookName)) {
                    return i;
                }
            }
        } else {
            for (int i = 0; i < BOOKS_IN_ORDER.length; i++) {
                if (BOOKS_IN_ORDER[i].equals(bookName)) {
                    return i;
                }
            }
        }
        return -1;
    }
    
    private void clearSelections() {
        selectedBook = null;
        selectedChapter = 0;
        selectedVerse = 0;
        chapterSpinner.setAdapter(null);
        verseSpinner.setAdapter(null);
        
        // Clear any existing cross references
        if (adapter != null) {
            adapter = null;
        }
        tvNoReferences.setVisibility(View.VISIBLE);
        layoutCrossReferences.setVisibility(View.GONE);
        tvNoReferences.setText("Select a book, chapter, and verse to view cross references");
    }
    
    private void loadBooksData() {
        try {
            List<String> books;
            if (isEnglishMode) {
                books = kjvDbHelper.getAllBooks();
                Log.d("CrossReferences", "Loading English books: " + books.size() + " books");
            } else {
                books = new ArrayList<>();
                for (String book : BOOKS_IN_ORDER) {
                    books.add(book);
                }
                Log.d("CrossReferences", "Loading Telugu books: " + books.size() + " books");
            }
            
            ArrayAdapter<String> bookAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, books);
            bookAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            bookSpinner.setAdapter(bookAdapter);
            
            // Reset selections
            selectedBook = null;
            selectedChapter = 0;
            selectedVerse = 0;
            chapterSpinner.setAdapter(null);
            verseSpinner.setAdapter(null);
            
            Log.d("CrossReferences", "Books data loaded successfully for " + (isEnglishMode ? "English" : "Telugu") + " mode");
        } catch (Exception e) {
            Log.e("CrossReferences", "Error loading books data: " + e.getMessage());
            Toast.makeText(this, "Error loading books: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void showCrossReferences() {
        if (crossReferenceDBHelper == null) {
            Toast.makeText(this, "Cross reference database not initialized", Toast.LENGTH_SHORT).show();
            return;
        }
        
        // Show loading state
        tvNoReferences.setVisibility(View.VISIBLE);
        layoutCrossReferences.setVisibility(View.GONE);
        tvNoReferences.setText("Loading cross references...");
        
        // Load cross references in background
        new LoadCrossReferencesTask().execute();
    }
    
    private class LoadCrossReferencesTask extends AsyncTask<Void, Void, List<CrossReference.Reference>> {
        private Exception exception;
        
        @Override
        protected List<CrossReference.Reference> doInBackground(Void... voids) {
            try {
                // Check if cross references exist first (for debugging)
                boolean hasRefs = crossReferenceDBHelper.hasCrossReferences(selectedBook, selectedChapter, selectedVerse);
                Log.d("CrossReferences", "Checking for " + selectedBook + " " + selectedChapter + ":" + selectedVerse + " - Has refs: " + hasRefs);
                
                // Get cross references from database with language support
                return crossReferenceDBHelper.getCrossReferences(selectedBook, selectedChapter, selectedVerse, isEnglishMode);
            } catch (Exception e) {
                exception = e;
                Log.e("CrossReferences", "Error loading cross references: " + e.getMessage(), e);
                return new ArrayList<>();
            }
        }
        
        @Override
        protected void onPostExecute(List<CrossReference.Reference> references) {
            if (exception != null) {
                Toast.makeText(CrossReferencesActivity.this, 
                    "Error loading cross references: " + exception.getMessage(), 
                    Toast.LENGTH_LONG).show();
                tvNoReferences.setText("Error loading cross references");
                return;
            }
            
            if (references.isEmpty()) {
                tvNoReferences.setVisibility(View.VISIBLE);
                layoutCrossReferences.setVisibility(View.GONE);
                tvNoReferences.setText("No cross references found for " + selectedBook + " " + selectedChapter + ":" + selectedVerse);
                Log.d("CrossReferences", "No cross references found for " + selectedBook + " " + selectedChapter + ":" + selectedVerse);
            } else {
                tvNoReferences.setVisibility(View.GONE);
                layoutCrossReferences.setVisibility(View.VISIBLE);
                
                adapter = new CrossReferenceAdapter(CrossReferencesActivity.this, references, reference -> {
                    // Navigate to the referenced verse in BibleActivity
                    navigateToVerse(reference.getBook(), reference.getChapter(), reference.getVerse());
                });
                rvCrossReferences.setAdapter(adapter);
                
                Log.d("CrossReferences", "Found " + references.size() + " cross references for " + selectedBook + " " + selectedChapter + ":" + selectedVerse);
                
                // Post to ensure layout is complete
                rvCrossReferences.post(() -> {
                    if (adapter != null) {
                        rvCrossReferences.requestLayout();
                    }
                });
            }
        }
    }

    private void navigateToVerse(String book, int chapter, int verse) {
        Intent intent = new Intent(this, BibleActivity.class);
        intent.putExtra("BOOK_NAME", book);
        intent.putExtra("CHAPTER", chapter);
        intent.putExtra("VERSE", verse);
        intent.putExtra("IS_ENGLISH_MODE", isEnglishMode); // Pass language information
        startActivity(intent);
        finish(); // Close this activity and go to BibleActivity
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (dbHelper != null) {
            dbHelper.close();
        }
        if (kjvDbHelper != null) {
            kjvDbHelper.close();
        }
        if (crossReferenceDBHelper != null) {
            crossReferenceDBHelper.close();
        }
    }
}