package com.holywordapp;

import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class KJVBibleDBHelper extends SQLiteOpenHelper {
    private static final String TAG = "KJVBibleDBHelper";
    private static final String DATABASE_NAME = "KJV.db";
    private static final int DATABASE_VERSION = 1;
    
    private Context context;
    private SQLiteDatabase database;

    // English book names in order
    private static final String[] ENGLISH_BOOKS = {
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
        "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah",
        "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
        "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah",
        "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", "Mark", "Luke",
        "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
        "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy",
        "Titus", "Philemon", "Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
        "Jude", "Revelation"
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

    public KJVBibleDBHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
        this.context = context;
        
        try {
            createDataBase();
            openDataBase();
        } catch (IOException e) {
            Log.e(TAG, "Error creating database: " + e.getMessage());
        }
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // Database is copied from assets, so no need to create tables
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // Handle database upgrade if needed
    }

    private void createDataBase() throws IOException {
        boolean dbExist = checkDataBase();
        if (!dbExist) {
            this.getReadableDatabase();
            try {
                copyDataBase();
            } catch (IOException e) {
                throw new Error("Error copying database: " + e.getMessage());
            }
        }
    }

    private boolean checkDataBase() {
        File dbFile = context.getDatabasePath(DATABASE_NAME);
        return dbFile.exists();
    }

    private void copyDataBase() throws IOException {
        InputStream myInput = context.getAssets().open(DATABASE_NAME);
        String outFileName = context.getDatabasePath(DATABASE_NAME).getPath();
        FileOutputStream myOutput = new FileOutputStream(outFileName);

        byte[] buffer = new byte[1024];
        int length;
        while ((length = myInput.read(buffer)) > 0) {
            myOutput.write(buffer, 0, length);
        }

        myOutput.flush();
        myOutput.close();
        myInput.close();
    }

    private void openDataBase() throws SQLException {
        String myPath = context.getDatabasePath(DATABASE_NAME).getPath();
        database = SQLiteDatabase.openDatabase(myPath, null, SQLiteDatabase.OPEN_READONLY);
    }

    public List<String> getAllBooks() {
        List<String> books = new ArrayList<>();
        
        try {
            if (database != null) {
                // Use the correct KJV database schema: KJV_books table with id, name
                String[] possibleQueries = {
                    "SELECT name FROM KJV_books ORDER BY id",
                    // Fallback queries in case of case sensitivity issues
                    "SELECT name FROM kjv_books ORDER BY id",
                    "SELECT name FROM books ORDER BY id"
                };
                
                boolean found = false;
                for (String query : possibleQueries) {
                    try {
                        Cursor cursor = database.rawQuery(query, null);
                        if (cursor.moveToFirst()) {
                            do {
                                books.add(cursor.getString(0));
                            } while (cursor.moveToNext());
                        }
                        cursor.close();
                        if (!books.isEmpty()) {
                            found = true;
                            Log.d(TAG, "Successfully loaded " + books.size() + " books using query: " + query);
                            break;
                        }
                    } catch (Exception e) {
                        Log.d(TAG, "Query failed: " + query + " - " + e.getMessage());
                    }
                }
                
                if (!found) {
                    Log.w(TAG, "No books table found, using fallback list");
                    throw new Exception("No books table found");
                }
            } else {
                throw new Exception("Database not initialized");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting books: " + e.getMessage());
            // Fallback to hardcoded list
            books.clear();
            for (String book : ENGLISH_BOOKS) {
                books.add(book);
            }
            Log.d(TAG, "Using fallback book list with " + books.size() + " books");
        }

        return books;
    }

    public List<Integer> getChaptersForBook(String bookName) {
        List<Integer> chapters = new ArrayList<>();
        if (database == null) {
            Log.w(TAG, "Database not available, using default chapters for " + bookName);
            // Return default chapters (most books have at least 1-50 chapters)
            for (int i = 1; i <= 50; i++) {
                chapters.add(i);
            }
            return chapters;
        }

        try {
            // Map the book name to KJV database format
            String mappedBookName = mapToKJVBookName(bookName);
            Log.d(TAG, "Mapping book name from '" + bookName + "' to '" + mappedBookName + "' for chapters");
            
            // Use the correct KJV database schema: KJV_verses table with book_id, chapter
            String[] possibleQueries = {
                // Primary query using the correct schema
                "SELECT DISTINCT chapter FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE name = ?) ORDER BY chapter",
                // Case-insensitive book name matching
                "SELECT DISTINCT chapter FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE LOWER(name) = LOWER(?)) ORDER BY chapter",
                // Fallback queries
                "SELECT DISTINCT chapter FROM kjv_verses WHERE book_id = (SELECT id FROM kjv_books WHERE name = ?) ORDER BY chapter",
                "SELECT DISTINCT chapter FROM verses WHERE book_id = (SELECT id FROM books WHERE name = ?) ORDER BY chapter"
            };
            
            boolean found = false;
            for (String query : possibleQueries) {
                try {
                    Cursor cursor = database.rawQuery(query, new String[]{mappedBookName});
                    if (cursor.moveToFirst()) {
                        do {
                            chapters.add(cursor.getInt(0));
                        } while (cursor.moveToNext());
                    }
                    cursor.close();
                    if (!chapters.isEmpty()) {
                        found = true;
                        Log.d(TAG, "Successfully loaded " + chapters.size() + " chapters for " + bookName + " using query: " + query);
                        break;
                    }
                } catch (Exception e) {
                    Log.d(TAG, "Query failed for chapters: " + query + " - " + e.getMessage());
                }
            }
            
            if (!found) {
                Log.w(TAG, "No chapters found for " + bookName + ", using default");
                // Default to 50 chapters
                for (int i = 1; i <= 50; i++) {
                    chapters.add(i);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting chapters: " + e.getMessage());
            // Default to 50 chapters
            for (int i = 1; i <= 50; i++) {
                chapters.add(i);
            }
        }

        return chapters;
    }

    public List<Integer> getVersesForChapter(String bookName, int chapter) {
        List<Integer> verses = new ArrayList<>();
        if (database == null) {
            Log.w(TAG, "Database not available, using default verses for " + bookName + " " + chapter);
            // Return default verses (most chapters have at least 1-30 verses)
            for (int i = 1; i <= 30; i++) {
                verses.add(i);
            }
            return verses;
        }

        try {
            // Map the book name to KJV database format
            String mappedBookName = mapToKJVBookName(bookName);
            Log.d(TAG, "Mapping book name from '" + bookName + "' to '" + mappedBookName + "' for verses");
            
            // Use the correct KJV database schema: KJV_verses table with book_id, chapter, verse
            String[] possibleQueries = {
                // Primary query using the correct schema
                "SELECT DISTINCT verse FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE name = ?) AND chapter = ? ORDER BY verse",
                // Case-insensitive book name matching
                "SELECT DISTINCT verse FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE LOWER(name) = LOWER(?)) AND chapter = ? ORDER BY verse",
                // Fallback queries
                "SELECT DISTINCT verse FROM kjv_verses WHERE book_id = (SELECT id FROM kjv_books WHERE name = ?) AND chapter = ? ORDER BY verse",
                "SELECT DISTINCT verse FROM verses WHERE book_id = (SELECT id FROM books WHERE name = ?) AND chapter = ? ORDER BY verse"
            };
            
            boolean found = false;
            for (String query : possibleQueries) {
                try {
                    Cursor cursor = database.rawQuery(query, new String[]{mappedBookName, String.valueOf(chapter)});
                    if (cursor.moveToFirst()) {
                        do {
                            verses.add(cursor.getInt(0));
                        } while (cursor.moveToNext());
                    }
                    cursor.close();
                    if (!verses.isEmpty()) {
                        found = true;
                        Log.d(TAG, "Successfully loaded " + verses.size() + " verses for " + bookName + " " + chapter + " using query: " + query);
                        break;
                    }
                } catch (Exception e) {
                    Log.d(TAG, "Query failed for verses: " + query + " - " + e.getMessage());
                }
            }
            
            if (!found) {
                Log.w(TAG, "No verses found for " + bookName + " " + chapter + ", using default");
                // Default to 30 verses
                for (int i = 1; i <= 30; i++) {
                    verses.add(i);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting verses: " + e.getMessage());
            // Default to 30 verses
            for (int i = 1; i <= 30; i++) {
                verses.add(i);
            }
        }

        return verses;
    }

    public List<Verse> getVersesForChapterRange(String bookName, int chapter) {
        List<Verse> verses = new ArrayList<>();
        if (database == null) {
            return verses;
        }

        try {
            // Map the book name to KJV database format
            String mappedBookName = mapToKJVBookName(bookName);
            Log.d(TAG, "Mapping book name from '" + bookName + "' to '" + mappedBookName + "' for chapter range");
            
            // Use the correct KJV database schema: KJV_verses table with book_id, chapter, verse, text columns
            String[] possibleQueries = {
                // Primary query using the correct schema
                "SELECT verse, text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE name = ?) AND chapter = ? ORDER BY verse",
                // Case-insensitive book name matching
                "SELECT verse, text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE LOWER(name) = LOWER(?)) AND chapter = ? ORDER BY verse",
                // Fallback queries
                "SELECT verse, text FROM kjv_verses WHERE book_id = (SELECT id FROM kjv_books WHERE name = ?) AND chapter = ? ORDER BY verse",
                "SELECT verse, text FROM verses WHERE book_id = (SELECT id FROM books WHERE name = ?) AND chapter = ? ORDER BY verse"
            };
            
            boolean found = false;
            for (String query : possibleQueries) {
                try {
                    Cursor cursor = database.rawQuery(query, new String[]{mappedBookName, String.valueOf(chapter)});
                    if (cursor.moveToFirst()) {
                        do {
                            Verse verse = new Verse();
                            verse.setVerseNumber(cursor.getInt(0));
                            verse.setVerseText(cursor.getString(1));
                            verse.setBookName(bookName);
                            verse.setChapterNumber(chapter);
                            verses.add(verse);
                        } while (cursor.moveToNext());
                    }
                    cursor.close();
                    if (!verses.isEmpty()) {
                        found = true;
                        Log.d(TAG, "Successfully loaded " + verses.size() + " verses for " + bookName + " " + chapter);
                        break;
                    }
                } catch (Exception e) {
                    Log.d(TAG, "Query failed for chapter range: " + query + " - " + e.getMessage());
                }
            }
            
            if (!found) {
                Log.w(TAG, "No verses found for chapter range " + bookName + " " + chapter);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting verses for chapter range: " + e.getMessage());
        }

        return verses;
    }

    public String getVerseText(String bookName, int chapter, int verse) {
        if (database == null) {
            return "English verse not available (Database not found)";
        }

        try {
            // Map the book name to KJV database format
            String mappedBookName = mapToKJVBookName(bookName);
            Log.d(TAG, "Mapping book name from '" + bookName + "' to '" + mappedBookName + "'");
            
            // Use the correct KJV database schema: KJV_verses table with book_id, chapter, verse, text
            String[] possibleQueries = {
                // Primary query using the correct schema with mapped book name
                "SELECT text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE name = ?) AND chapter = ? AND verse = ?",
                // Case-insensitive book name matching
                "SELECT text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE LOWER(name) = LOWER(?)) AND chapter = ? AND verse = ?",
                "SELECT text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE UPPER(name) = UPPER(?)) AND chapter = ? AND verse = ?",
                // Fallback: try with trimmed book name
                "SELECT text FROM KJV_verses WHERE book_id = (SELECT id FROM KJV_books WHERE TRIM(name) = TRIM(?)) AND chapter = ? AND verse = ?",
                // Additional fallback queries for different table names
                "SELECT text FROM kjv_verses WHERE book_id = (SELECT id FROM kjv_books WHERE name = ?) AND chapter = ? AND verse = ?",
                "SELECT text FROM verses WHERE book_id = (SELECT id FROM books WHERE name = ?) AND chapter = ? AND verse = ?"
            };
            
            for (String query : possibleQueries) {
                try {
                    Cursor cursor = database.rawQuery(query, new String[]{mappedBookName, String.valueOf(chapter), String.valueOf(verse)});
                    if (cursor.moveToFirst()) {
                        String text = cursor.getString(0);
                        cursor.close();
                        if (text != null && !text.isEmpty()) {
                            Log.d(TAG, "Successfully found verse text using query: " + query);
                            return text;
                        }
                    }
                    cursor.close();
                } catch (Exception e) {
                    Log.d(TAG, "Query failed for verse text: " + query + " - " + e.getMessage());
                }
            }
            
            // If all queries fail, try to get any verse from the database to understand the schema
            Log.w(TAG, "All verse text queries failed for '" + bookName + "', attempting to understand database schema...");
            try {
                // First, log available tables
                Cursor cursor = database.rawQuery("SELECT name FROM sqlite_master WHERE type='table'", null);
                if (cursor.moveToFirst()) {
                    do {
                        String tableName = cursor.getString(0);
                        Log.d(TAG, "Available table: " + tableName);
                    } while (cursor.moveToNext());
                }
                cursor.close();
                
                // Try to find similar book names in the database
                String[] possibleBookQueries = {
                    "SELECT name FROM KJV_books LIMIT 10",
                    "SELECT DISTINCT book FROM KJV_verses LIMIT 10",
                    "SELECT name FROM kjv_books LIMIT 10",
                    "SELECT DISTINCT book FROM kjv_verses LIMIT 10",
                    "SELECT name FROM books LIMIT 10",
                    "SELECT DISTINCT book FROM verses LIMIT 10"
                };
                
                for (String query : possibleBookQueries) {
                    try {
                        cursor = database.rawQuery(query, null);
                        if (cursor.moveToFirst()) {
                            Log.d(TAG, "Sample books from query '" + query + "':");
                            do {
                                String sampleBook = cursor.getString(0);
                                Log.d(TAG, "  - " + sampleBook);
                            } while (cursor.moveToNext());
                            break; // Stop after first successful query
                        }
                        cursor.close();
                    } catch (Exception e) {
                        Log.d(TAG, "Query failed: " + query + " - " + e.getMessage());
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error getting table names: " + e.getMessage());
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error getting verse text: " + e.getMessage());
        }

        return "English verse not available (" + bookName + " " + chapter + ":" + verse + ")";
    }

    public int getBookId(String bookName) {
        if (database == null) {
            return -1;
        }

        try {
            // Use schema: <translation>_books table with id, name columns
            String[] possibleQueries = {
                "SELECT id FROM kjv_books WHERE name = ?",
                "SELECT id FROM books WHERE name = ?"
            };
            
            for (String query : possibleQueries) {
                try {
                    Cursor cursor = database.rawQuery(query, new String[]{bookName});
                    if (cursor.moveToFirst()) {
                        int id = cursor.getInt(0);
                        cursor.close();
                        return id;
                    }
                    cursor.close();
                } catch (Exception e) {
                    Log.d(TAG, "Query failed for book ID: " + query + " - " + e.getMessage());
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting book ID: " + e.getMessage());
        }

        return -1;
    }

    @Override
    public synchronized void close() {
        if (database != null) {
            database.close();
        }
        super.close();
    }

}
