package com.holywordapp;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

public class BibleDBHelper extends SQLiteOpenHelper {

    private static final String DB_NAME = "bsi_te.db";
    private static final int DB_VERSION = 1;
    private final String DB_PATH;
    private final Context context;

    public BibleDBHelper(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
        this.context = context;
        this.DB_PATH = context.getDatabasePath(DB_NAME).getPath();
        copyDatabase();
    }

    private void copyDatabase() {
        try {
            if (!new File(DB_PATH).exists()) {
                this.getReadableDatabase();
                InputStream is = context.getAssets().open(DB_NAME);
                OutputStream os = new FileOutputStream(DB_PATH);

                byte[] buffer = new byte[1024];
                int length;
                while ((length = is.read(buffer)) > 0) os.write(buffer, 0, length);

                os.flush(); os.close(); is.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override public void onCreate(SQLiteDatabase db) {}
    @Override public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {}

    public List<Integer> getChapters(String book) {
        List<Integer> list = new ArrayList<>();
        SQLiteDatabase db = getReadableDatabase();
        Cursor c = db.rawQuery("SELECT DISTINCT c FROM verse WHERE b = ? ORDER BY c", new String[]{book});
        while (c.moveToNext()) list.add(c.getInt(0));
        c.close();
        return list;
    }

    public List<BibleVerse> getVerses(String book, int chapter) {
        List<BibleVerse> list = new ArrayList<>();
        SQLiteDatabase db = getReadableDatabase();
        Cursor c = db.rawQuery("SELECT v, t FROM verse WHERE b = ? AND c = ? ORDER BY v", new String[]{book, String.valueOf(chapter)});
        while (c.moveToNext()) list.add(new BibleVerse(c.getInt(0), c.getString(1)));
        c.close();
        return list;
    }
    
    public int getBookId(String bookName) {
        SQLiteDatabase db = getReadableDatabase();
        Cursor c = db.rawQuery("SELECT DISTINCT b FROM verse WHERE b = ? LIMIT 1", new String[]{bookName});
        if (c.moveToFirst()) {
            // For Telugu database, we need to map book names to numbers
            // This is a simplified approach - you might need to adjust based on your actual data
            String[] teluguBooks = {
                "ఆదికాండము", "నిర్గమకాండము", "లేవీయకాండము", "అరణ్యకాండము", "ద్వితీయోపదేశకాండము",
                "యెహోషువ", "న్యాయాధిపతులు", "రూతు", "1 సమూయేలు", "2 సమూయేలు",
                "1 రాజులు", "2 రాజులు", "1 దినవృత్తాంతములు", "2 దినవృత్తాంతములు",
                "ఎజ్రా", "నెహెమీయా", "ఎస్తేరు", "యోబు", "కీర్తనలు", "సామెతలు",
                "ప్రసంగి", "పరమగీతము", "యెషయా", "యిర్మీయా", "విలాపవాక్యములు",
                "యెహేజ్కేలు", "దానియేలు", "హోషేయ", "యోవేలు", "ఆమోసు",
                "ఒబద్యా", "యోనా", "మీకా", "నహూము", "హబకూకు", "జెఫన్యా",
                "హగ్గయి", "జెకర్యా", "మలాకీ", "మత్తయి", "మార్కు", "లూకా",
                "యోహాను", "అపొస్తలుల కార్యములు", "రోమీయులకు", "1 కొరింథీయులకు",
                "2 కొరింథీయులకు", "గలతీయులకు", "ఎఫెసీయులకు", "ఫిలిప్పీయులకు",
                "కొలొస్సయులకు", "1 థెస్సలొనీకయులకు", "2 థెస్సలొనీకయులకు",
                "1 తిమోతికి", "2 తిమోతికి", "తీతుకు", "ఫిలేమోనుకు", "హెబ్రీయులకు",
                "యాకోబు", "1 పేతురు", "2 పేతురు", "1 యోహాను", "2 యోహాను",
                "3 యోహాను", "యూదా", "ప్రకటన"
            };
            
            for (int i = 0; i < teluguBooks.length; i++) {
                if (teluguBooks[i].equals(bookName)) {
                    c.close();
                    return i + 1; // Return 1-based book number
                }
            }
        }
        c.close();
        return -1;
    }
    
    public List<String> getAllBooks() {
        List<String> books = new ArrayList<>();
        SQLiteDatabase db = getReadableDatabase();
        Cursor c = db.rawQuery("SELECT DISTINCT b FROM verse ORDER BY b", null);
        while (c.moveToNext()) {
            books.add(c.getString(0));
        }
        c.close();
        return books;
    }
}
