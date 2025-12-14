package com.holywordapp;

import android.content.Context;
import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class CrossReferenceFileReader {
    private static final String TAG = "CrossReferenceFileReader";
    private static final String CROSS_REFERENCES_FILE = "cross_references.txt";

    public static List<CrossReference> loadCrossReferencesFromFile(Context context) {
        List<CrossReference> crossReferences = new ArrayList<>();
        
        try {
            InputStream inputStream = context.getAssets().open(CROSS_REFERENCES_FILE);
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String line;
            
            CrossReference currentCrossRef = null;
            
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                
                if (line.isEmpty()) {
                    continue;
                }
                
                // Check if this is a new cross reference entry
                if (line.startsWith("SOURCE:")) {
                    // Save previous cross reference if exists
                    if (currentCrossRef != null) {
                        crossReferences.add(currentCrossRef);
                    }
                    
                    // Parse source verse
                    String sourceInfo = line.substring(7).trim(); // Remove "SOURCE:"
                    String[] parts = sourceInfo.split("\\|");
                    if (parts.length >= 4) {
                        String book = parts[0].trim();
                        int chapter = Integer.parseInt(parts[1].trim());
                        int verse = Integer.parseInt(parts[2].trim());
                        String text = parts[3].trim();
                        
                        currentCrossRef = new CrossReference(book, chapter, verse, text);
                    }
                } else if (line.startsWith("REF:") && currentCrossRef != null) {
                    // Parse reference
                    String refInfo = line.substring(4).trim(); // Remove "REF:"
                    String[] parts = refInfo.split("\\|");
                    if (parts.length >= 5) {
                        String book = parts[0].trim();
                        int chapter = Integer.parseInt(parts[1].trim());
                        int verse = Integer.parseInt(parts[2].trim());
                        String text = parts[3].trim();
                        String type = parts[4].trim();
                        
                        currentCrossRef.addReference(book, chapter, verse, text, type);
                    }
                }
            }
            
            // Add the last cross reference
            if (currentCrossRef != null) {
                crossReferences.add(currentCrossRef);
            }
            
            reader.close();
            inputStream.close();
            
            Log.d(TAG, "Loaded " + crossReferences.size() + " cross references from file");
            
        } catch (IOException e) {
            Log.e(TAG, "Error reading cross references file", e);
        }
        
        return crossReferences;
    }

    public static void updateCrossReferenceManager(Context context) {
        List<CrossReference> crossReferences = loadCrossReferencesFromFile(context);
        CrossReferenceManager manager = CrossReferenceManager.getInstance();
        manager.updateCrossReferences(crossReferences);
    }
}


