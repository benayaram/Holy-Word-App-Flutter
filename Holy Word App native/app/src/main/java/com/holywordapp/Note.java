package com.holywordapp;

import java.util.ArrayList;
import java.util.List;

public class Note {
    private long id;
    private String title;
    private List<VerseReference> verseReferences;

    public Note() {
        verseReferences = new ArrayList<>();
    }

    public Note(long id, String title) {
        this.id = id;
        this.title = title;
        this.verseReferences = new ArrayList<>();
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public List<VerseReference> getVerseReferences() {
        return verseReferences;
    }

    public void setVerseReferences(List<VerseReference> verseReferences) {
        this.verseReferences = verseReferences;
    }

    public void addVerseReference(VerseReference verseReference) {
        verseReferences.add(verseReference);
    }
}