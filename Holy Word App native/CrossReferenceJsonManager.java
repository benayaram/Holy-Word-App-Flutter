package com.holywordapp;

import android.content.Context;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Manages cross references loaded from JSON file
 * Optimized for Bible activity navigation
 */
public class CrossReferenceJsonManager {
    private static final String TAG = "CrossReferenceJsonManager";
    private static final String JSON_FILE_NAME = "cross_references.json";
    
    private static CrossReferenceJsonManager instance;
    private Map<String, List<CrossReference.Reference>> crossReferencesMap;
    private boolean isInitialized = false;
    
    private CrossReferenceJsonManager() {
        crossReferencesMap = new HashMap<>();
    }
    
    public static CrossReferenceJsonManager getInstance() {
        if (instance == null) {
            instance = new CrossReferenceJsonManager();
        }
        return instance;
    }
    
    /**
     * Initialize cross references from JSON file
     */
    public void initializeCrossReferences(Context context) {
        if (isInitialized) {
            return;
        }
        
        try {
            String jsonString = loadJsonFromAssets(context, JSON_FILE_NAME);
            parseCrossReferencesJson(jsonString);
            isInitialized = true;
            Log.d(TAG, "Cross references initialized successfully. Total sources: " + crossReferencesMap.size());
        } catch (Exception e) {
            Log.e(TAG, "Error initializing cross references: " + e.getMessage());
        }
    }
    
    /**
     * Load JSON string from assets folder
     */
    private String loadJsonFromAssets(Context context, String fileName) throws IOException {
        InputStream inputStream = context.getAssets().open(fileName);
        int size = inputStream.available();
        byte[] buffer = new byte[size];
        inputStream.read(buffer);
        inputStream.close();
        return new String(buffer, StandardCharsets.UTF_8);
    }
    
    /**
     * Parse cross references from JSON string
     */
    private void parseCrossReferencesJson(String jsonString) throws JSONException {
        JSONObject jsonObject = new JSONObject(jsonString);
        
        // Iterate through all source verses
        for (String sourceKey : JSONObject.getNames(jsonObject)) {
            JSONArray referencesArray = jsonObject.getJSONArray(sourceKey);
            List<CrossReference.Reference> references = new ArrayList<>();
            
            // Parse each reference
            for (int i = 0; i < referencesArray.length(); i++) {
                JSONObject refObject = referencesArray.getJSONObject(i);
                
                CrossReference.Reference reference = new CrossReference.Reference(
                    refObject.getString("book"),
                    refObject.getInt("chapter"),
                    refObject.getInt("verse"),
                    refObject.getString("type")
                );
                
                references.add(reference);
            }
            
            crossReferencesMap.put(sourceKey, references);
        }
    }
    
    /**
     * Get cross references for a specific verse
     * @param book Book name (e.g., "Gen", "Ps", "Matt")
     * @param chapter Chapter number
     * @param verse Verse number
     * @return List of cross references or empty list if none found
     */
    public List<CrossReference.Reference> getCrossReferences(String book, int chapter, int verse) {
        if (!isInitialized) {
            Log.w(TAG, "Cross references not initialized. Call initializeCrossReferences() first.");
            return new ArrayList<>();
        }
        
        String key = book + "|" + chapter + "|" + verse;
        List<CrossReference.Reference> references = crossReferencesMap.get(key);
        
        if (references != null) {
            Log.d(TAG, "Found " + references.size() + " cross references for " + key);
            return references;
        } else {
            Log.d(TAG, "No cross references found for " + key);
            return new ArrayList<>();
        }
    }
    
    /**
     * Get cross references for a specific verse using CrossReference object
     */
    public List<CrossReference.Reference> getCrossReferences(CrossReference crossReference) {
        return getCrossReferences(
            crossReference.getSourceBook(),
            crossReference.getSourceChapter(),
            crossReference.getSourceVerse()
        );
    }
    
    /**
     * Check if a verse has cross references
     */
    public boolean hasCrossReferences(String book, int chapter, int verse) {
        String key = book + "|" + chapter + "|" + verse;
        return crossReferencesMap.containsKey(key) && !crossReferencesMap.get(key).isEmpty();
    }
    
    /**
     * Get total number of source verses with cross references
     */
    public int getTotalSourceVerses() {
        return crossReferencesMap.size();
    }
    
    /**
     * Get total number of cross references
     */
    public int getTotalReferences() {
        int total = 0;
        for (List<CrossReference.Reference> references : crossReferencesMap.values()) {
            total += references.size();
        }
        return total;
    }
    
    /**
     * Clear all cross references (useful for memory management)
     */
    public void clearCrossReferences() {
        crossReferencesMap.clear();
        isInitialized = false;
        Log.d(TAG, "Cross references cleared");
    }
    
    /**
     * Get all available source keys
     */
    public List<String> getAllSourceKeys() {
        return new ArrayList<>(crossReferencesMap.keySet());
    }
    
    /**
     * Debug method to print all cross references
     */
    public void printAllCrossReferences() {
        Log.d(TAG, "=== All Cross References ===");
        for (Map.Entry<String, List<CrossReference.Reference>> entry : crossReferencesMap.entrySet()) {
            Log.d(TAG, "Source: " + entry.getKey());
            for (CrossReference.Reference ref : entry.getValue()) {
                Log.d(TAG, "  -> " + ref.getBook() + " " + ref.getChapter() + ":" + ref.getVerse() + " (" + ref.getType() + ")");
            }
        }
    }
}
