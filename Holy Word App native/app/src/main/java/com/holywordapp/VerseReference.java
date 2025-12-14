package com.holywordapp;

public class VerseReference {
    private long id;
    private long noteId;
    private String bookName;
    private int chapter;
    private int verse;
    private String verseText;
    private boolean isEnglishMode; // true for English, false for Telugu

    public VerseReference() {
    }

    public VerseReference(String bookName, int chapter, int verse, String verseText) {
        this.bookName = bookName;
        this.chapter = chapter;
        this.verse = verse;
        this.verseText = verseText;
        this.isEnglishMode = false; // Default to Telugu
    }

    public VerseReference(String bookName, int chapter, int verse, String verseText, boolean isEnglishMode) {
        this.bookName = bookName;
        this.chapter = chapter;
        this.verse = verse;
        this.verseText = verseText;
        this.isEnglishMode = isEnglishMode;
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getNoteId() {
        return noteId;
    }

    public void setNoteId(long noteId) {
        this.noteId = noteId;
    }

    public String getBookName() {
        return bookName;
    }

    public void setBookName(String bookName) {
        this.bookName = bookName;
    }

    public int getChapter() {
        return chapter;
    }

    public void setChapter(int chapter) {
        this.chapter = chapter;
    }

    public int getVerse() {
        return verse;
    }

    public void setVerse(int verse) {
        this.verse = verse;
    }

    public String getVerseText() {
        return verseText;
    }

    public void setVerseText(String verseText) {
        this.verseText = verseText;
    }

    public String getReference() {
        return bookName + " " + chapter + ":" + verse;
    }

    public boolean isEnglishMode() {
        return isEnglishMode;
    }

    public void setEnglishMode(boolean englishMode) {
        isEnglishMode = englishMode;
    }
}