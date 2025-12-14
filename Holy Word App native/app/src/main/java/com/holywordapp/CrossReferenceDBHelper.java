package com.holywordapp;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class CrossReferenceDBHelper extends SQLiteOpenHelper {
    private static final String TAG = "CrossReferenceDBHelper";
    private static final String DATABASE_NAME = "cross_references.db"; // Use single database file
    private static final int DATABASE_VERSION = 1;
    
    // Table name
    private static final String TABLE_CROSS_REFERENCES = "cross_references";
    
    // Column names - based on the actual schema from the database
    private static final String COLUMN_SOURCE_BOOK = "source_book";
    private static final String COLUMN_SOURCE_CHAPTER = "source_chapter";
    private static final String COLUMN_SOURCE_VERSE = "source_verse";
    private static final String COLUMN_REFERENCE_BOOK = "reference_book";
    private static final String COLUMN_REFERENCE_CHAPTER = "reference_chapter";
    private static final String COLUMN_REFERENCE_VERSE = "reference_verse";
    
    private Context context;
    private String currentDatabaseName;

    public CrossReferenceDBHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
        this.context = context;
        this.currentDatabaseName = DATABASE_NAME;
        
        // Initialize the single cross reference database
        copyDatabaseFromAssets(DATABASE_NAME);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // This is called only when the database is created for the first time
        // Since we're copying from assets, we don't need to create tables here
        Log.d(TAG, "onCreate called - database will be copied from assets");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // Handle database upgrade if needed
        Log.d(TAG, "onUpgrade called from version " + oldVersion + " to " + newVersion);
    }



    /**
     * Copy the database from assets folder to the app's database directory
     */
    private void copyDatabaseFromAssets() {
        copyDatabaseFromAssets(DATABASE_NAME);
    }

    /**
     * Copy a specific database from assets folder to the app's database directory
     */
    private void copyDatabaseFromAssets(String databaseName) {
        try {
            String dbPath = context.getDatabasePath(databaseName).getPath();
            File dbFile = new File(dbPath);
            
            // Only copy if the database doesn't exist
            if (!dbFile.exists()) {
                Log.d(TAG, "Database " + databaseName + " not found, copying from assets...");
                
                // Create the database directory if it doesn't exist
                if (!dbFile.getParentFile().exists()) {
                    dbFile.getParentFile().mkdirs();
                }
                
                // Copy the database from assets
                InputStream inputStream = context.getAssets().open(databaseName);
                FileOutputStream outputStream = new FileOutputStream(dbPath);
                
                byte[] buffer = new byte[8192]; // 8KB buffer
                int length;
                while ((length = inputStream.read(buffer)) > 0) {
                    outputStream.write(buffer, 0, length);
                }
                
                outputStream.close();
                inputStream.close();
                
                Log.d(TAG, "Database " + databaseName + " successfully copied from assets");
            } else {
                Log.d(TAG, "Database " + databaseName + " already exists, skipping copy");
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error copying database " + databaseName + " from assets: " + e.getMessage());
        }
    }

    /**
     * Get cross references for a specific verse
     */
    public List<CrossReference.Reference> getCrossReferences(String book, int chapter, int verse) {
        return getCrossReferences(book, chapter, verse, false); // Default to Telugu
    }

    /**
     * Get cross references for a specific verse with language support
     */
    public List<CrossReference.Reference> getCrossReferences(String book, int chapter, int verse, boolean isEnglishMode) {
        List<CrossReference.Reference> references = new ArrayList<>();
        
        // Map English book name to Telugu if needed for cross reference lookup
        String lookupBook = book;
        if (isEnglishMode) {
            lookupBook = mapEnglishToTeluguBookName(book);
        }
        
        Log.d(TAG, "Searching for cross references: " + lookupBook + " " + chapter + ":" + verse);
        
        try {
            // Use the single cross reference database
            SQLiteDatabase db = this.getReadableDatabase();
                    
                    String[] columns = {
                        COLUMN_REFERENCE_BOOK,
                        COLUMN_REFERENCE_CHAPTER,
                        COLUMN_REFERENCE_VERSE
                    };
                    
                    String selection = COLUMN_SOURCE_BOOK + " = ? AND " + 
                                     COLUMN_SOURCE_CHAPTER + " = ? AND " + 
                                     COLUMN_SOURCE_VERSE + " = ?";
                    
                    String[] selectionArgs = {lookupBook, String.valueOf(chapter), String.valueOf(verse)};
                    
                    Cursor cursor = db.query(
                        TABLE_CROSS_REFERENCES,
                        columns,
                        selection,
                        selectionArgs,
                        null,
                        null,
                        COLUMN_REFERENCE_BOOK + ", " + COLUMN_REFERENCE_CHAPTER + ", " + COLUMN_REFERENCE_VERSE
                    );
                    
                    if (cursor != null) {
                        try {
                                                    while (cursor.moveToNext()) {
                            String refBook = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_REFERENCE_BOOK));
                            int refChapter = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_REFERENCE_CHAPTER));
                            int refVerse = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_REFERENCE_VERSE));
                            
                            // Convert Telugu book name to English if needed
                            String refBookName = refBook;
                            if (isEnglishMode) {
                                refBookName = mapTeluguToEnglishBookName(refBook);
                                Log.d(TAG, "Mapped Telugu book '" + refBook + "' to English '" + refBookName + "'");
                                
                                // Check if mapping was successful
                                if (refBookName.equals(refBook)) {
                                    Log.w(TAG, "No mapping found for Telugu book: " + refBook);
                                }
                            }
                            
                            // Get the actual verse text from Bible database
                            String verseText = getVerseText(refBookName, refChapter, refVerse, isEnglishMode);
                            Log.d(TAG, "Retrieved verse text for " + refBookName + " " + refChapter + ":" + refVerse + " = " + (verseText != null ? verseText.substring(0, Math.min(50, verseText.length())) + "..." : "null"));
                            
                            // Create reference with verse text
                            CrossReference.Reference reference = new CrossReference.Reference(refBookName, refChapter, refVerse, verseText, "Reference");
                            references.add(reference);
                        }
                        } finally {
                            cursor.close();
                        }
                    }
                    
                    db.close();
                    
                } catch (Exception e) {
                    Log.e(TAG, "Error getting cross references: " + e.getMessage());
                }
        
        Log.d(TAG, "Found " + references.size() + " cross references for " + book + " " + chapter + ":" + verse);
        return references;
    }

    /**
     * Check if database has data
     */
    public boolean hasData() {
        try {
            SQLiteDatabase db = this.getReadableDatabase();
            Cursor cursor = db.rawQuery("SELECT COUNT(*) FROM " + TABLE_CROSS_REFERENCES, null);
            
            if (cursor != null) {
                try {
                    if (cursor.moveToFirst()) {
                        int count = cursor.getInt(0);
                        return count > 0;
                    }
                } finally {
                    cursor.close();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error checking if database has data: " + e.getMessage());
        }
        return false;
    }

    /**
     * Get total number of cross references
     */
    public int getTotalReferences() {
        try {
            SQLiteDatabase db = this.getReadableDatabase();
            Cursor cursor = db.rawQuery("SELECT COUNT(*) FROM " + TABLE_CROSS_REFERENCES, null);
            
            if (cursor != null) {
                try {
                    if (cursor.moveToFirst()) {
                        return cursor.getInt(0);
                    }
                } finally {
                    cursor.close();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting total references: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Load cross references from JSON (not needed for database approach)
     */
    public boolean loadCrossReferencesFromJson() {
        // Since we're using pre-built database, this always succeeds
        return true;
    }

    /**
     * Get verse text from the Bible database
     */
    private String getVerseText(String book, int chapter, int verse) {
        return getVerseText(book, chapter, verse, false); // Default to Telugu
    }

    /**
     * Map English book names to Telugu book names for cross reference validation
     */
    private String mapEnglishToTeluguBookName(String englishBookName) {
        // Map English book names to Telugu book names (using the same names as BibleActivity)
        switch (englishBookName) {
            case "Genesis": return "ఆదికాండము";
            case "Exodus": return "నిర్గమకాండము";
            case "Leviticus": return "లేవీయకాండము";
            case "Numbers": return "సంఖ్యాకాండము";
            case "Deuteronomy": return "ద్వితీయోపదేశకాండమ";
            case "Joshua": return "యెహొషువ";
            case "Judges": return "న్యాయాధిపతులు";
            case "Ruth": return "రూతు";
            case "1 Samuel": return "సమూయేలు మొదటి గ్రంథము";
            case "2 Samuel": return "సమూయేలు రెండవ గ్రంథము";
            case "1 Kings": return "రాజులు మొదటి గ్రంథము";
            case "2 Kings": return "రాజులు రెండవ గ్రంథము";
            case "1 Chronicles": return "దినవృత్తాంతములు మొదటి గ్రంథము";
            case "2 Chronicles": return "దినవృత్తాంతములు రెండవ గ్రంథము";
            case "Ezra": return "ఎజ్రా";
            case "Nehemiah": return "నెహెమ్యా";
            case "Esther": return "ఎస్తేరు";
            case "Job": return "యోబు గ్రంథము";
            case "Psalms": return "కీర్తనల గ్రంథము";
            case "Proverbs": return "సామెతలు";
            case "Ecclesiastes": return "ప్రసంగి";
            case "Song of Solomon": return "పరమగీతము";
            case "Isaiah": return "యెషయా గ్రంథము";
            case "Jeremiah": return "యిర్మీయా";
            case "Lamentations": return "విలాపవాక్యములు";
            case "Ezekiel": return "యెహెజ్కేలు";
            case "Daniel": return "దానియేలు";
            case "Hosea": return "హొషేయ";
            case "Joel": return "యోవేలు";
            case "Amos": return "ఆమోసు";
            case "Obadiah": return "ఓబద్యా";
            case "Jonah": return "యోనా";
            case "Micah": return "మీకా";
            case "Nahum": return "నహూము";
            case "Habakkuk": return "హబక్కూకు";
            case "Zephaniah": return "జెఫన్యా";
            case "Haggai": return "హగ్గయి";
            case "Zechariah": return "జెకర్యా";
            case "Malachi": return "మలాకీ";
            case "Matthew": return "మత్తయి సువార్త";
            case "Mark": return "మార్కు సువార్త";
            case "Luke": return "లూకా సువార్త";
            case "John": return "యోహాను సువార్త";
            case "Acts": return "అపొస్తలుల కార్యములు";
            case "Romans": return "రోమీయులకు";
            case "1 Corinthians": return "1 కొరింథీయులకు";
            case "2 Corinthians": return "2 కొరింథీయులకు";
            case "Galatians": return "గలతీయులకు";
            case "Ephesians": return "ఎఫెసీయులకు";
            case "Philippians": return "ఫిలిప్పీయులకు";
            case "Colossians": return "కొలొస్సయులకు";
            case "1 Thessalonians": return "1 థెస్సలొనీకయులకు";
            case "2 Thessalonians": return "2 థెస్సలొనీకయులకు";
            case "1 Timothy": return "1 తిమోతికి";
            case "2 Timothy": return "2 తిమోతికి";
            case "Titus": return "తీతుకు";
            case "Philemon": return "ఫిలేమోనుకు";
            case "Hebrews": return "హెబ్రీయులకు";
            case "James": return "యాకోబు";
            case "1 Peter": return "1 పేతురు";
            case "2 Peter": return "2 పేతురు";
            case "1 John": return "1 యోహాను";
            case "2 John": return "2 యోహాను";
            case "3 John": return "3 యోహాను";
            case "Jude": return "యూదా";
            case "Revelation": return "ప్రకటన గ్రంథము";
            default: return englishBookName; // Return original if no mapping found
        }
    }


    
    /**
     * Map Telugu book names to English book names
     */
    private String mapTeluguToEnglishBookName(String teluguBookName) {
        // First check if the book name is already in English
        if (isEnglishBookName(teluguBookName)) {
            return teluguBookName;
        }
        
        switch (teluguBookName) {
            case "ఆదికాండము": return "Genesis";
            case "నిర్గమకాండము": return "Exodus";
            case "లేవీయకాండము": return "Leviticus";
            case "సంఖ్యాకాండము": return "Numbers";
            case "ద్వితీయోపదేశకాండమ": return "Deuteronomy";
            case "యెహొషువ": return "Joshua";
            case "న్యాయాధిపతులు": return "Judges";
            case "రూతు": return "Ruth";
            case "సమూయేలు మొదటి గ్రంథము": return "1 Samuel";
            case "సమూయేలు రెండవ గ్రంథము": return "2 Samuel";
            case "రాజులు మొదటి గ్రంథము": return "1 Kings";
            case "రాజులు రెండవ గ్రంథము": return "2 Kings";
            case "దినవృత్తాంతములు మొదటి గ్రంథము": return "1 Chronicles";
            case "దినవృత్తాంతములు రెండవ గ్రంథము": return "2 Chronicles";
            case "ఎజ్రా": return "Ezra";
            case "నెహెమ్యా": return "Nehemiah";
            case "ఎస్తేరు": return "Esther";
            case "యోబు గ్రంథము": return "Job";
            case "కీర్తనల గ్రంథము": return "Psalms";
            case "సామెతలు": return "Proverbs";
            case "ప్రసంగి": return "Ecclesiastes";
            case "పరమగీతము": return "Song of Solomon";
            case "యెషయా గ్రంథము": return "Isaiah";
            case "యిర్మీయా": return "Jeremiah";
            case "విలాపవాక్యములు": return "Lamentations";
            case "యెహెజ్కేలు": return "Ezekiel";
            case "దానియేలు": return "Daniel";
            case "హొషేయ": return "Hosea";
            case "యోవేలు": return "Joel";
            case "ఆమోసు": return "Amos";
            case "ఓబద్యా": return "Obadiah";
            case "యోనా": return "Jonah";
            case "మీకా": return "Micah";
            case "నహూము": return "Nahum";
            case "హబక్కూకు": return "Habakkuk";
            case "జెఫన్యా": return "Zephaniah";
            case "హగ్గయి": return "Haggai";
            case "జెకర్యా": return "Zechariah";
            case "మలాకీ": return "Malachi";
            case "మత్తయి సువార్త": return "Matthew";
            case "మార్కు సువార్త": return "Mark";
            case "లూకా సువార్త": return "Luke";
            case "యోహాను సువార్త": return "John";
            case "అపొస్తలుల కార్యములు": return "Acts";
            case "రోమీయులకు": return "Romans";
            case "1 కొరింథీయులకు": return "1 Corinthians";
            case "2 కొరింథీయులకు": return "2 Corinthians";
            case "గలతీయులకు": return "Galatians";
            case "ఎఫెసీయులకు": return "Ephesians";
            case "ఫిలిప్పీయులకు": return "Philippians";
            case "కొలొస్సయులకు": return "Colossians";
            case "1 థెస్సలొనీకయులకు": return "1 Thessalonians";
            case "2 థెస్సలొనీకయులకు": return "2 Thessalonians";
            case "1 తిమోతికి": return "1 Timothy";
            case "2 తిమోతికి": return "2 Timothy";
            case "తీతుకు": return "Titus";
            case "ఫిలేమోనుకు": return "Philemon";
            case "హెబ్రీయులకు": return "Hebrews";
            case "యాకోబు": return "James";
            case "1 పేతురు": return "1 Peter";
            case "2 పేతురు": return "2 Peter";
            case "1 యోహాను": return "1 John";
            case "2 యోహాను": return "2 John";
            case "3 యోహాను": return "3 John";
            case "యూదా": return "Jude";
            case "ప్రకటన గ్రంథము": return "Revelation";
            default: return teluguBookName;
        }
    }
    

    
    /**
     * Get verse text from the Bible database with language support
     */
    private String getVerseText(String book, int chapter, int verse, boolean isEnglishMode) {
        try {
            String verseText = "";
            String bookNameToUse = book;
            
            if (isEnglishMode) {
                // Use KJV database for English
                Log.d(TAG, "Getting English verse text for: " + book + " " + chapter + ":" + verse);
                KJVBibleDBHelper kjvDBHelper = new KJVBibleDBHelper(context);
                verseText = kjvDBHelper.getVerseText(book, chapter, verse);
                Log.d(TAG, "KJV query result: " + (verseText != null ? verseText.substring(0, Math.min(50, verseText.length())) + "..." : "null"));
                kjvDBHelper.close();
            } else {
                // Use Telugu database
                BibleDBHelper bibleDBHelper = new BibleDBHelper(context);
                List<BibleVerse> verses = bibleDBHelper.getVerses(book, chapter);
                
                // Find the specific verse
                for (BibleVerse bibleVerse : verses) {
                    if (bibleVerse.verseNum == verse) {
                        verseText = bibleVerse.verseText;
                        break;
                    }
                }
                bibleDBHelper.close();
            }
            
            // Limit text length for display
            if (verseText != null && verseText.length() > 100) {
                verseText = verseText.substring(0, 97) + "...";
            }
            
            if (verseText == null || verseText.isEmpty()) {
                return "Verse not found: " + book + " " + chapter + ":" + verse;
            }
            
            return verseText;
            
        } catch (Exception e) {
            Log.e(TAG, "Error getting verse text: " + e.getMessage());
            return book + " " + chapter + ":" + verse;
        }
    }

    /**
     * Check if cross references exist for a given verse (for debugging)
     */
    public boolean hasCrossReferences(String book, int chapter, int verse) {
        try {
            // Use the single cross reference database
            SQLiteDatabase db = this.getReadableDatabase();
            
            String selection = COLUMN_SOURCE_BOOK + " = ? AND " + 
                             COLUMN_SOURCE_CHAPTER + " = ? AND " + 
                             COLUMN_SOURCE_VERSE + " = ?";
            
            String[] selectionArgs = {book, String.valueOf(chapter), String.valueOf(verse)};
            
            Cursor cursor = db.query(
                TABLE_CROSS_REFERENCES,
                new String[]{COLUMN_REFERENCE_BOOK},
                selection,
                selectionArgs,
                null,
                null,
                null
            );
            
            boolean hasResults = cursor != null && cursor.getCount() > 0;
            
            if (cursor != null) {
                cursor.close();
            }
            
            if (hasResults) {
                Log.d(TAG, "Found cross references in database for " + book + " " + chapter + ":" + verse);
            } else {
                Log.d(TAG, "No cross references found for " + book + " " + chapter + ":" + verse);
            }
            
            return hasResults;
            
        } catch (Exception e) {
            Log.e(TAG, "Error checking cross references: " + e.getMessage());
            return false;
        }
    }

    /**
     * Check if a book name is in English
     */
    private boolean isEnglishBookName(String bookName) {
        return bookName.equalsIgnoreCase("Genesis") || bookName.equalsIgnoreCase("Exodus") || bookName.equalsIgnoreCase("Leviticus") ||
               bookName.equalsIgnoreCase("Numbers") || bookName.equalsIgnoreCase("Deuteronomy") || bookName.equalsIgnoreCase("Joshua") ||
               bookName.equalsIgnoreCase("Judges") || bookName.equalsIgnoreCase("Ruth") || bookName.equalsIgnoreCase("1 Samuel") ||
               bookName.equalsIgnoreCase("2 Samuel") || bookName.equalsIgnoreCase("1 Kings") || bookName.equalsIgnoreCase("2 Kings") ||
               bookName.equalsIgnoreCase("1 Chronicles") || bookName.equalsIgnoreCase("2 Chronicles") || bookName.equalsIgnoreCase("Ezra") ||
               bookName.equalsIgnoreCase("Nehemiah") || bookName.equalsIgnoreCase("Esther") || bookName.equalsIgnoreCase("Job") ||
               bookName.equalsIgnoreCase("Psalms") || bookName.equalsIgnoreCase("Proverbs") || bookName.equalsIgnoreCase("Ecclesiastes") ||
               bookName.equalsIgnoreCase("Song of Solomon") || bookName.equalsIgnoreCase("Isaiah") || bookName.equalsIgnoreCase("Jeremiah") ||
               bookName.equalsIgnoreCase("Lamentations") || bookName.equalsIgnoreCase("Ezekiel") || bookName.equalsIgnoreCase("Daniel") ||
               bookName.equalsIgnoreCase("Hosea") || bookName.equalsIgnoreCase("Joel") || bookName.equalsIgnoreCase("Amos") ||
               bookName.equalsIgnoreCase("Obadiah") || bookName.equalsIgnoreCase("Jonah") || bookName.equalsIgnoreCase("Micah") ||
               bookName.equalsIgnoreCase("Nahum") || bookName.equalsIgnoreCase("Habakkuk") || bookName.equalsIgnoreCase("Zephaniah") ||
               bookName.equalsIgnoreCase("Haggai") || bookName.equalsIgnoreCase("Zechariah") || bookName.equalsIgnoreCase("Malachi") ||
               bookName.equalsIgnoreCase("Matthew") || bookName.equalsIgnoreCase("Mark") || bookName.equalsIgnoreCase("Luke") ||
               bookName.equalsIgnoreCase("John") || bookName.equalsIgnoreCase("Acts") || bookName.equalsIgnoreCase("Romans") ||
               bookName.equalsIgnoreCase("1 Corinthians") || bookName.equalsIgnoreCase("2 Corinthians") || bookName.equalsIgnoreCase("Galatians") ||
               bookName.equalsIgnoreCase("Ephesians") || bookName.equalsIgnoreCase("Philippians") || bookName.equalsIgnoreCase("Colossians") ||
               bookName.equalsIgnoreCase("1 Thessalonians") || bookName.equalsIgnoreCase("2 Thessalonians") || bookName.equalsIgnoreCase("1 Timothy") ||
               bookName.equalsIgnoreCase("2 Timothy") || bookName.equalsIgnoreCase("Titus") || bookName.equalsIgnoreCase("Philemon") ||
               bookName.equalsIgnoreCase("Hebrews") || bookName.equalsIgnoreCase("James") || bookName.equalsIgnoreCase("1 Peter") ||
               bookName.equalsIgnoreCase("2 Peter") || bookName.equalsIgnoreCase("1 John") || bookName.equalsIgnoreCase("2 John") ||
               bookName.equalsIgnoreCase("3 John") || bookName.equalsIgnoreCase("Jude") || bookName.equalsIgnoreCase("Revelation");
    }
}
