package com.holywordapp;

import java.util.ArrayList;
import java.util.List;

public class CrossReference {
    private String sourceBook;
    private int sourceChapter;
    private int sourceVerse;
    private String sourceText;
    private List<Reference> references;
    private String category;
    private String description;

    public CrossReference(String sourceBook, int sourceChapter, int sourceVerse, String sourceText) {
        this.sourceBook = sourceBook;
        this.sourceChapter = sourceChapter;
        this.sourceVerse = sourceVerse;
        this.sourceText = sourceText;
        this.references = new ArrayList<>();
        this.category = "";
        this.description = "";
    }

    // Getters and Setters
    public String getSourceBook() { return sourceBook; }
    public void setSourceBook(String sourceBook) { this.sourceBook = sourceBook; }

    public int getSourceChapter() { return sourceChapter; }
    public void setSourceChapter(int sourceChapter) { this.sourceChapter = sourceChapter; }

    public int getSourceVerse() { return sourceVerse; }
    public void setSourceVerse(int sourceVerse) { this.sourceVerse = sourceVerse; }

    public String getSourceText() { return sourceText; }
    public void setSourceText(String sourceText) { this.sourceText = sourceText; }

    public List<Reference> getReferences() { return references; }
    public void setReferences(List<Reference> references) { this.references = references; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public void addReference(String book, int chapter, int verse, String text, String type) {
        references.add(new Reference(book, chapter, verse, text, type));
    }

    public String getFormattedReference() {
        return sourceBook + " " + sourceChapter + ":" + sourceVerse;
    }

    // Inner class for individual references
    public static class Reference {
        private String book;
        private int chapter;
        private int verse;
        private String text;
        private String type; // "parallel", "quotation", "allusion", "theme", "prophecy", "fulfillment"

        public Reference(String book, int chapter, int verse, String text, String type) {
            this.book = book;
            this.chapter = chapter;
            this.verse = verse;
            this.text = text;
            this.type = type;
        }

        // Getters and Setters
        public String getBook() { return book; }
        public void setBook(String book) { this.book = book; }

        public int getChapter() { return chapter; }
        public void setChapter(int chapter) { this.chapter = chapter; }

        public int getVerse() { return verse; }
        public void setVerse(int verse) { this.verse = verse; }

        public String getText() { return text; }
        public void setText(String text) { this.text = text; }

        public String getType() { return type; }
        public void setType(String type) { this.type = type; }

        public String getFormattedReference() {
            return book + " " + chapter + ":" + verse;
        }

        public String getTypeDisplayName() {
            switch (type) {
                case "parallel": return "Parallel";
                case "quotation": return "Quotation";
                case "allusion": return "Allusion";
                case "theme": return "Theme";
                case "prophecy": return "Prophecy";
                case "fulfillment": return "Fulfillment";
                default: return "Reference";
            }
        }
    }
}

