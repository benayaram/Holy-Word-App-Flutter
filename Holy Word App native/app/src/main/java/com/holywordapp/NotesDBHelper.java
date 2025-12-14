package com.holywordapp;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.ArrayList;
import java.util.List;

public class NotesDBHelper extends SQLiteOpenHelper {

    private static final String DATABASE_NAME = "bible_notes.db";
    private static final int DATABASE_VERSION = 3;

    // Tables
    private static final String TABLE_NOTES = "notes";
    private static final String TABLE_VERSE_REFERENCES = "verse_references";
    private static final String TABLE_VERSE_HIGHLIGHTS = "verse_highlights";

    // Notes Table Columns
    private static final String KEY_NOTE_ID = "id";
    private static final String KEY_NOTE_TITLE = "title";

    // Verse References Table Columns
    private static final String KEY_VERSE_REF_ID = "id";
    private static final String KEY_VERSE_REF_NOTE_ID = "note_id";
    private static final String KEY_VERSE_REF_BOOK = "book_name";
    private static final String KEY_VERSE_REF_CHAPTER = "chapter";
    private static final String KEY_VERSE_REF_VERSE = "verse";
    private static final String KEY_VERSE_REF_TEXT = "verse_text";
    private static final String KEY_VERSE_REF_LANGUAGE = "is_english_mode";

    // Verse Highlights Table Columns
    private static final String KEY_HIGHLIGHT_ID = "id";
    private static final String KEY_HIGHLIGHT_BOOK = "book_name";
    private static final String KEY_HIGHLIGHT_CHAPTER = "chapter";
    private static final String KEY_HIGHLIGHT_VERSE = "verse";
    private static final String KEY_HIGHLIGHT_COLOR = "color";

    // Table creation SQL statements
    private static final String CREATE_TABLE_NOTES =
            "CREATE TABLE " + TABLE_NOTES + "(" +
                    KEY_NOTE_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    KEY_NOTE_TITLE + " TEXT NOT NULL);";

    private static final String CREATE_TABLE_VERSE_REFERENCES =
            "CREATE TABLE " + TABLE_VERSE_REFERENCES + "(" +
                    KEY_VERSE_REF_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    KEY_VERSE_REF_NOTE_ID + " INTEGER, " +
                    KEY_VERSE_REF_BOOK + " TEXT NOT NULL, " +
                    KEY_VERSE_REF_CHAPTER + " INTEGER NOT NULL, " +
                    KEY_VERSE_REF_VERSE + " INTEGER NOT NULL, " +
                    KEY_VERSE_REF_TEXT + " TEXT NOT NULL, " +
                    KEY_VERSE_REF_LANGUAGE + " INTEGER DEFAULT 0, " +
                    "FOREIGN KEY(" + KEY_VERSE_REF_NOTE_ID + ") REFERENCES " +
                    TABLE_NOTES + "(" + KEY_NOTE_ID + ") ON DELETE CASCADE);";

    private static final String CREATE_TABLE_VERSE_HIGHLIGHTS =
            "CREATE TABLE " + TABLE_VERSE_HIGHLIGHTS + "(" +
                    KEY_HIGHLIGHT_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    KEY_HIGHLIGHT_BOOK + " TEXT NOT NULL, " +
                    KEY_HIGHLIGHT_CHAPTER + " INTEGER NOT NULL, " +
                    KEY_HIGHLIGHT_VERSE + " INTEGER NOT NULL, " +
                    KEY_HIGHLIGHT_COLOR + " INTEGER NOT NULL);";

    public NotesDBHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(CREATE_TABLE_NOTES);
        db.execSQL(CREATE_TABLE_VERSE_REFERENCES);
        db.execSQL(CREATE_TABLE_VERSE_HIGHLIGHTS);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        if (oldVersion < 3) {
            // Add language column to existing table
            try {
                db.execSQL("ALTER TABLE " + TABLE_VERSE_REFERENCES + " ADD COLUMN " + KEY_VERSE_REF_LANGUAGE + " INTEGER DEFAULT 0");
            } catch (Exception e) {
                // If column already exists, recreate table
                db.execSQL("DROP TABLE IF EXISTS " + TABLE_VERSE_REFERENCES);
                db.execSQL("DROP TABLE IF EXISTS " + TABLE_NOTES);
                db.execSQL("DROP TABLE IF EXISTS " + TABLE_VERSE_HIGHLIGHTS);
                onCreate(db);
            }
        }
    }

    @Override
    public void onConfigure(SQLiteDatabase db) {
        super.onConfigure(db);
        db.setForeignKeyConstraintsEnabled(true);
    }

    // Note operations
    public long createNote(Note note) {
        SQLiteDatabase db = this.getWritableDatabase();

        ContentValues values = new ContentValues();
        values.put(KEY_NOTE_TITLE, note.getTitle());

        long noteId = db.insert(TABLE_NOTES, null, values);
        note.setId(noteId);

        for (VerseReference reference : note.getVerseReferences()) {
            addVerseReferenceToNote(noteId, reference);
        }

        return noteId;
    }

    public long addVerseReferenceToNote(long noteId, VerseReference reference) {
        SQLiteDatabase db = this.getWritableDatabase();

        ContentValues values = new ContentValues();
        values.put(KEY_VERSE_REF_NOTE_ID, noteId);
        values.put(KEY_VERSE_REF_BOOK, reference.getBookName());
        values.put(KEY_VERSE_REF_CHAPTER, reference.getChapter());
        values.put(KEY_VERSE_REF_VERSE, reference.getVerse());
        values.put(KEY_VERSE_REF_TEXT, reference.getVerseText());
        values.put(KEY_VERSE_REF_LANGUAGE, reference.isEnglishMode() ? 1 : 0);

        long id = db.insert(TABLE_VERSE_REFERENCES, null, values);
        reference.setId(id);
        reference.setNoteId(noteId);

        return id;
    }

    public List<Note> getAllNotes() {
        List<Note> notes = new ArrayList<>();
        String selectQuery = "SELECT * FROM " + TABLE_NOTES + " ORDER BY " + KEY_NOTE_ID + " DESC";

        SQLiteDatabase db = this.getReadableDatabase();
        Cursor c = db.rawQuery(selectQuery, null);

        if (c.moveToFirst()) {
            do {
                Note note = new Note();
                note.setId(c.getLong(c.getColumnIndex(KEY_NOTE_ID)));
                note.setTitle(c.getString(c.getColumnIndex(KEY_NOTE_TITLE)));

                // Get all verse references for this note
                note.setVerseReferences(getVerseReferencesForNote(note.getId()));

                notes.add(note);
            } while (c.moveToNext());
        }

        c.close();
        return notes;
    }

    public Note getNote(long noteId) {
        SQLiteDatabase db = this.getReadableDatabase();
        String selectQuery = "SELECT * FROM " + TABLE_NOTES + " WHERE " + KEY_NOTE_ID + " = " + noteId;

        Cursor c = db.rawQuery(selectQuery, null);

        if (c != null && c.moveToFirst()) {
            Note note = new Note();
            note.setId(c.getLong(c.getColumnIndex(KEY_NOTE_ID)));
            note.setTitle(c.getString(c.getColumnIndex(KEY_NOTE_TITLE)));

            // Get all verse references for this note
            note.setVerseReferences(getVerseReferencesForNote(note.getId()));

            c.close();
            return note;
        }

        if (c != null) {
            c.close();
        }

        return null;
    }

    private List<VerseReference> getVerseReferencesForNote(long noteId) {
        List<VerseReference> references = new ArrayList<>();
        String selectQuery = "SELECT * FROM " + TABLE_VERSE_REFERENCES +
                " WHERE " + KEY_VERSE_REF_NOTE_ID + " = " + noteId;

        SQLiteDatabase db = this.getReadableDatabase();
        Cursor c = db.rawQuery(selectQuery, null);

        if (c.moveToFirst()) {
            do {
                VerseReference reference = new VerseReference();
                reference.setId(c.getLong(c.getColumnIndex(KEY_VERSE_REF_ID)));
                reference.setNoteId(c.getLong(c.getColumnIndex(KEY_VERSE_REF_NOTE_ID)));
                reference.setBookName(c.getString(c.getColumnIndex(KEY_VERSE_REF_BOOK)));
                reference.setChapter(c.getInt(c.getColumnIndex(KEY_VERSE_REF_CHAPTER)));
                reference.setVerse(c.getInt(c.getColumnIndex(KEY_VERSE_REF_VERSE)));
                reference.setVerseText(c.getString(c.getColumnIndex(KEY_VERSE_REF_TEXT)));
                
                // Handle language column (may not exist in old database)
                try {
                    int languageColumn = c.getColumnIndex(KEY_VERSE_REF_LANGUAGE);
                    if (languageColumn >= 0) {
                        reference.setEnglishMode(c.getInt(languageColumn) == 1);
                    } else {
                        reference.setEnglishMode(false); // Default to Telugu for old records
                    }
                } catch (Exception e) {
                    reference.setEnglishMode(false); // Default to Telugu for old records
                }

                references.add(reference);
            } while (c.moveToNext());
        }

        c.close();
        return references;
    }

    public boolean deleteNote(long noteId) {
        SQLiteDatabase db = this.getWritableDatabase();
        return db.delete(TABLE_NOTES, KEY_NOTE_ID + " = ?", new String[] { String.valueOf(noteId) }) > 0;
    }

    public boolean deleteVerseReference(long verseRefId) {
        SQLiteDatabase db = this.getWritableDatabase();
        return db.delete(TABLE_VERSE_REFERENCES, KEY_VERSE_REF_ID + " = ?",
                new String[] { String.valueOf(verseRefId) }) > 0;
    }

    public int updateNoteTitle(Note note) {
        SQLiteDatabase db = this.getWritableDatabase();

        ContentValues values = new ContentValues();
        values.put(KEY_NOTE_TITLE, note.getTitle());

        return db.update(TABLE_NOTES, values, KEY_NOTE_ID + " = ?",
                new String[] { String.valueOf(note.getId()) });
    }

    // --- Highlight Color Operations ---
    public void setVerseHighlightColor(String book, int chapter, int verse, int color) {
        SQLiteDatabase db = this.getWritableDatabase();
        // Check if exists
        Cursor c = db.query(TABLE_VERSE_HIGHLIGHTS, null,
                KEY_HIGHLIGHT_BOOK + "=? AND " + KEY_HIGHLIGHT_CHAPTER + "=? AND " + KEY_HIGHLIGHT_VERSE + "=?",
                new String[]{book, String.valueOf(chapter), String.valueOf(verse)}, null, null, null);
        ContentValues values = new ContentValues();
        values.put(KEY_HIGHLIGHT_BOOK, book);
        values.put(KEY_HIGHLIGHT_CHAPTER, chapter);
        values.put(KEY_HIGHLIGHT_VERSE, verse);
        values.put(KEY_HIGHLIGHT_COLOR, color);
        if (c.moveToFirst()) {
            db.update(TABLE_VERSE_HIGHLIGHTS, values,
                    KEY_HIGHLIGHT_BOOK + "=? AND " + KEY_HIGHLIGHT_CHAPTER + "=? AND " + KEY_HIGHLIGHT_VERSE + "=?",
                    new String[]{book, String.valueOf(chapter), String.valueOf(verse)});
        } else {
            db.insert(TABLE_VERSE_HIGHLIGHTS, null, values);
        }
        c.close();
    }

    public int getVerseHighlightColor(String book, int chapter, int verse) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor c = db.query(TABLE_VERSE_HIGHLIGHTS, new String[]{KEY_HIGHLIGHT_COLOR},
                KEY_HIGHLIGHT_BOOK + "=? AND " + KEY_HIGHLIGHT_CHAPTER + "=? AND " + KEY_HIGHLIGHT_VERSE + "=?",
                new String[]{book, String.valueOf(chapter), String.valueOf(verse)}, null, null, null);
        int color = 0xFFFFFFFF; // Default: no highlight
        if (c.moveToFirst()) {
            color = c.getInt(c.getColumnIndex(KEY_HIGHLIGHT_COLOR));
        }
        c.close();
        return color;
    }
}