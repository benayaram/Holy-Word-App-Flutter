package com.holywordapp;

import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class NoteDetailActivity extends AppCompatActivity implements VerseReferenceAdapter.VerseReferenceListener {

    private TextView titleTextView;
    private RecyclerView recyclerViewVerses;
    private TextView emptyView;

    private NotesDBHelper dbHelper;
    private Note currentNote;
    private long noteId;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_note_detail);

        titleTextView = findViewById(R.id.textViewNoteTitle);
        recyclerViewVerses = findViewById(R.id.recyclerViewVerseReferences);
        emptyView = findViewById(R.id.textViewEmptyVerses);

        // Set up toolbar/actionbar with null check to prevent NullPointerException
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }

        dbHelper = new NotesDBHelper(this);

        // Get the note ID from intent
        noteId = getIntent().getLongExtra("NOTE_ID", -1);

        if (noteId < 0) {
            Toast.makeText(this, "Invalid note", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        loadNote();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate menu with share option
        getMenuInflater().inflate(R.menu.menu_note_detail, menu);
        return true;
    }

    private void loadNote() {
        currentNote = dbHelper.getNote(noteId);

        if (currentNote == null) {
            Toast.makeText(this, "Note not found", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        titleTextView.setText(currentNote.getTitle());

        // Also add null check here when setting the ActionBar title
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(currentNote.getTitle());
        }

        if (currentNote.getVerseReferences().isEmpty()) {
            recyclerViewVerses.setVisibility(View.GONE);
            emptyView.setVisibility(View.VISIBLE);
        } else {
            recyclerViewVerses.setVisibility(View.VISIBLE);
            emptyView.setVisibility(View.GONE);

            VerseReferenceAdapter adapter = new VerseReferenceAdapter(currentNote.getVerseReferences(), this);
            recyclerViewVerses.setLayoutManager(new LinearLayoutManager(this));
            recyclerViewVerses.setAdapter(adapter);
        }
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        int itemId = item.getItemId();

        if (itemId == android.R.id.home) {
            onBackPressed();
            return true;
        } else if (itemId == R.id.action_share) {
            shareNoteAsImage();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void shareNoteAsImage() {
        if (currentNote == null) {
            Toast.makeText(this, "No note to share", Toast.LENGTH_SHORT).show();
            return;
        }

        List<VerseReference> verseReferences = currentNote.getVerseReferences();
        
        if (verseReferences.isEmpty()) {
            Toast.makeText(this, "No verses to share", Toast.LENGTH_SHORT).show();
            return;
        }

        // Determine if we need multiple images
        int maxVersesPerImage = 3; // Maximum verses per image for clarity
        int totalVerses = verseReferences.size();
        
        if (totalVerses <= maxVersesPerImage) {
            // Single image for few verses
            shareSingleImage(verseReferences);
        } else {
            // Multiple images for many verses
            shareMultipleImages(verseReferences, maxVersesPerImage);
        }
    }

    private void shareSingleImage(List<VerseReference> verseReferences) {
        Bitmap noteBitmap = createNoteBitmap(verseReferences);
        if (noteBitmap == null) {
            Toast.makeText(this, "Failed to create image", Toast.LENGTH_SHORT).show();
            return;
        }

        Uri imageUri = saveBitmapToCache(noteBitmap, "note_single");
        if (imageUri == null) {
            Toast.makeText(this, "Failed to save image", Toast.LENGTH_SHORT).show();
            return;
        }

        Intent shareIntent = new Intent(Intent.ACTION_SEND);
        shareIntent.setType("image/jpeg");
        shareIntent.putExtra(Intent.EXTRA_STREAM, imageUri);
        shareIntent.putExtra(Intent.EXTRA_SUBJECT, currentNote.getTitle() + " - Notes from Holy Word App");
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        startActivity(Intent.createChooser(shareIntent, "Share Note Image"));
    }

    private void shareMultipleImages(List<VerseReference> allVerses, int maxVersesPerImage) {
        List<Uri> imageUris = new ArrayList<>();
        int totalImages = (int) Math.ceil((double) allVerses.size() / maxVersesPerImage);
        
        for (int i = 0; i < totalImages; i++) {
            int startIndex = i * maxVersesPerImage;
            int endIndex = Math.min(startIndex + maxVersesPerImage, allVerses.size());
            List<VerseReference> imageVerses = allVerses.subList(startIndex, endIndex);
            
            Bitmap noteBitmap = createNoteBitmap(imageVerses, i + 1, totalImages);
            if (noteBitmap != null) {
                Uri imageUri = saveBitmapToCache(noteBitmap, "note_part_" + (i + 1));
                if (imageUri != null) {
                    imageUris.add(imageUri);
                }
            }
        }
        
        if (imageUris.isEmpty()) {
            Toast.makeText(this, "Failed to create images", Toast.LENGTH_SHORT).show();
            return;
        }

        // Share multiple images
        Intent shareIntent = new Intent(Intent.ACTION_SEND_MULTIPLE);
        shareIntent.setType("image/jpeg");
        shareIntent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, (ArrayList<Uri>) imageUris);
        shareIntent.putExtra(Intent.EXTRA_SUBJECT, currentNote.getTitle() + " - Notes from Holy Word App (Part 1 of " + totalImages + ")");
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        startActivity(Intent.createChooser(shareIntent, "Share Note Images"));
    }

    private Bitmap createNoteBitmap() {
        return createNoteBitmap(currentNote.getVerseReferences());
    }

    private Bitmap createNoteBitmap(List<VerseReference> verseReferences) {
        return createNoteBitmap(verseReferences, 1, 1);
    }

    private Bitmap createNoteBitmap(List<VerseReference> verseReferences, int currentPart, int totalParts) {

        // Calculate total height needed for the bitmap
        int cardWidth = getResources().getDisplayMetrics().widthPixels - 80; // Bit smaller than screen
        int baseCardHeight = 120; // Base height for each verse card
        int padding = 40;
        int headerHeight = calculateHeaderHeight(verseReferences, totalParts);
        int footerHeight = 140; // Reduced since logo is now horizontal layout
        
        // Calculate dynamic total height based on content
        int totalHeight = headerHeight + padding;
        for (VerseReference verseRef : verseReferences) {
            String actualVerseText = verseRef.getVerseText();
            int textWidth = cardWidth - 60;
            Paint textMeasurePaint = new Paint();
            textMeasurePaint.setTextSize(36);
            textMeasurePaint.setTypeface(Typeface.DEFAULT);
            
            // Measure how many lines the verse text will take
            String[] words = actualVerseText.split(" ");
            StringBuilder currentLine = new StringBuilder();
            int lines = 1;
            
            for (String word : words) {
                String testLine = currentLine.toString() + " " + word;
                if (textMeasurePaint.measureText(testLine) > textWidth) {
                    lines++;
                    currentLine = new StringBuilder(word);
                } else {
                    currentLine.append(" ").append(word);
                }
            }
            
            int dynamicCardHeight = Math.max(baseCardHeight, 80 + (lines * 50));
            totalHeight += dynamicCardHeight + padding;
        }
        totalHeight += footerHeight;

        // Create the bitmap with white background
        Bitmap bitmap = Bitmap.createBitmap(cardWidth + (padding * 2), totalHeight, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        canvas.drawColor(Color.WHITE);

        // We'll draw the logo at the bottom instead of as a watermark

        // Draw title with truncation for long titles
        Paint titlePaint = new Paint();
        titlePaint.setColor(Color.BLACK);
        titlePaint.setTextSize(60);
        titlePaint.setTypeface(Typeface.DEFAULT_BOLD);
        titlePaint.setTextAlign(Paint.Align.CENTER);
        titlePaint.setAntiAlias(true);
        
        String title = currentNote.getTitle();
        int maxTitleWidth = bitmap.getWidth() - 80; // Leave some margin
        
        // Check if title needs to be truncated
        if (titlePaint.measureText(title) > maxTitleWidth) {
            title = truncateText(title, titlePaint, maxTitleWidth);
        }
        
        // If title is still too long, reduce font size
        if (titlePaint.measureText(title) > maxTitleWidth) {
            titlePaint.setTextSize(48);
            if (titlePaint.measureText(title) > maxTitleWidth) {
                titlePaint.setTextSize(36);
                title = truncateText(title, titlePaint, maxTitleWidth);
            }
        }
        
        // Draw title (single line or multi-line)
        drawMultiLineText(canvas, title, titlePaint, bitmap.getWidth() / 2, 100, maxTitleWidth);

        // Calculate dynamic Y positions based on title height
        int titleEndY = calculateTitleEndY(title, titlePaint, maxTitleWidth);
        
        // Draw part information if multiple parts
        if (totalParts > 1) {
            Paint partPaint = new Paint();
            partPaint.setColor(Color.parseColor("#666666"));
            partPaint.setTextSize(40);
            partPaint.setTypeface(Typeface.DEFAULT_BOLD);
            partPaint.setTextAlign(Paint.Align.CENTER);
            partPaint.setAntiAlias(true);
            
            int partTextY = titleEndY + 50; // 50dp below title
            canvas.drawText("Part " + currentPart + " of " + totalParts, bitmap.getWidth() / 2, partTextY, partPaint);
        }

        // Draw app branding (simplified without logo)
        int appTextY = totalParts > 1 ? titleEndY + 90 : titleEndY + 50;
        
        // Draw app name with enhanced styling
        Paint appTextPaint = new Paint();
        appTextPaint.setColor(Color.parseColor("#FF5722")); // Orange color matching logo
        appTextPaint.setTextSize(36);
        appTextPaint.setTextAlign(Paint.Align.CENTER);
        appTextPaint.setAntiAlias(true);
        appTextPaint.setTypeface(Typeface.DEFAULT_BOLD);
        appTextPaint.setShadowLayer(2, 1, 1, Color.parseColor("#40000000")); // Subtle shadow
        
        canvas.drawText("HOLY WORD", bitmap.getWidth() / 2, appTextY + 10, appTextPaint);
        
        // Draw subtitle with gradient effect
        Paint subtitlePaint = new Paint();
        subtitlePaint.setColor(Color.parseColor("#666666"));
        subtitlePaint.setTextSize(26);
        subtitlePaint.setTextAlign(Paint.Align.CENTER);
        subtitlePaint.setAntiAlias(true);
        subtitlePaint.setTypeface(Typeface.DEFAULT);
        
        canvas.drawText("Bible Study & Notes", bitmap.getWidth() / 2, appTextY + 40, subtitlePaint);

        // Draw decorative line separator
        Paint separatorPaint = new Paint();
        separatorPaint.setColor(Color.parseColor("#E0E0E0"));
        separatorPaint.setStrokeWidth(1);
        separatorPaint.setAntiAlias(true);
        canvas.drawLine(padding, appTextY + 60, bitmap.getWidth() - padding, appTextY + 60, separatorPaint);

        // Draw each verse reference as a card with enhanced styling
        Paint cardPaint = new Paint();
        cardPaint.setColor(Color.parseColor("#FFFFFF")); // White background
        cardPaint.setShadowLayer(12, 0, 4, Color.parseColor("#40000000")); // Enhanced shadow
        cardPaint.setAntiAlias(true);

        Paint versePaint = new Paint();
        versePaint.setColor(Color.parseColor("#FF5722")); // Orange color matching logo
        versePaint.setTextSize(44);
        versePaint.setTypeface(Typeface.DEFAULT_BOLD);
        versePaint.setAntiAlias(true);
        versePaint.setShadowLayer(1, 0, 1, Color.parseColor("#20000000")); // Subtle shadow

        Paint textPaint = new Paint();
        textPaint.setColor(Color.parseColor("#424242")); // Dark gray for verse text
        textPaint.setTextSize(34);
        textPaint.setAntiAlias(true);

        // Calculate the actual header end position for verse positioning
        int actualHeaderEndY = calculateTitleEndY(title, titlePaint, maxTitleWidth);
        int partInfoHeight = totalParts > 1 ? 90 : 50;
        int appTextHeight = 50;
        int actualHeaderHeight = actualHeaderEndY + partInfoHeight + appTextHeight + 40; // 40dp bottom padding
        
        int currentY = actualHeaderHeight + padding;

        for (VerseReference verseRef : verseReferences) {
            // Get the actual verse text from the verse reference
            String actualVerseText = verseRef.getVerseText();
            
            // Calculate card height based on content (verse text might be long)
            int textWidth = cardWidth - 60; // Leave some padding
            Paint textMeasurePaint = new Paint();
            textMeasurePaint.setTextSize(36);
            textMeasurePaint.setTypeface(Typeface.DEFAULT);
            
            // Measure how many lines the verse text will take
            String[] words = actualVerseText.split(" ");
            StringBuilder currentLine = new StringBuilder();
            int lines = 1;
            
            for (String word : words) {
                String testLine = currentLine.toString() + " " + word;
                if (textMeasurePaint.measureText(testLine) > textWidth) {
                    lines++;
                    currentLine = new StringBuilder(word);
                } else {
                    currentLine.append(" ").append(word);
                }
            }
            
            // Adjust card height based on content
            int dynamicCardHeight = Math.max(120, 80 + (lines * 50)); // Minimum 120, or 80 + 50 per line
            
            // Draw card background with enhanced styling
            Paint cardRectPaint = new Paint();
            cardRectPaint.setColor(Color.parseColor("#FFFFFF")); // White background
            cardRectPaint.setShadowLayer(12, 0, 4, Color.parseColor("#40000000")); // Enhanced shadow
            cardRectPaint.setAntiAlias(true);

            // Draw rounded rectangle (simulated with multiple rectangles)
            Rect cardRect = new Rect(padding, currentY, padding + cardWidth, currentY + dynamicCardHeight);
            canvas.drawRect(cardRect, cardRectPaint);
            
            // Add subtle border
            Paint borderPaint = new Paint();
            borderPaint.setColor(Color.parseColor("#E0E0E0"));
            borderPaint.setStyle(Paint.Style.STROKE);
            borderPaint.setStrokeWidth(2);
            borderPaint.setAntiAlias(true);
            canvas.drawRect(cardRect, borderPaint);

            // Draw decorative line on the left
            Paint decorPaint = new Paint();
            decorPaint.setColor(Color.parseColor("#FF5722")); // Orange accent line matching logo
            decorPaint.setStrokeWidth(4);
            decorPaint.setAntiAlias(true);
            canvas.drawLine(padding + 10, currentY + 10, padding + 10, currentY + dynamicCardHeight - 10, decorPaint);
            
            // Draw verse reference text
            String verseRefText = verseRef.getBookName() + " " + verseRef.getChapter() + ":" + verseRef.getVerse();
            canvas.drawText(verseRefText, padding + 30, currentY + 50, versePaint);

            // Draw the actual verse text
            Paint verseTextPaint = new Paint();
            verseTextPaint.setColor(Color.DKGRAY);
            verseTextPaint.setTextSize(36);
            verseTextPaint.setTypeface(Typeface.DEFAULT);
            verseTextPaint.setAntiAlias(true);
            
            // Draw verse text with word wrapping
            currentLine = new StringBuilder();
            int lineY = currentY + 90;
            
            for (String word : words) {
                String testLine = currentLine.toString() + " " + word;
                if (textMeasurePaint.measureText(testLine) > textWidth) {
                    // Draw current line
                    canvas.drawText(currentLine.toString().trim(), padding + 30, lineY, verseTextPaint);
                    lineY += 50;
                    currentLine = new StringBuilder(word);
                } else {
                    currentLine.append(" ").append(word);
                }
            }
            // Draw the last line
            if (currentLine.length() > 0) {
                canvas.drawText(currentLine.toString().trim(), padding + 30, lineY, verseTextPaint);
            }

            // Move to next position
            currentY += dynamicCardHeight + padding;
        }

        // Draw logo and branding at the bottom
        drawBottomLogoAndBranding(canvas, bitmap, currentY);

        return bitmap;
    }

    private String truncateText(String text, Paint paint, int maxWidth) {
        // Ensure text fits within card by truncating if necessary
        if (paint.measureText(text) <= maxWidth) {
            return text;
        }

        String ellipsis = "...";
        int textWidth = (int) paint.measureText(text);
        int ellipsisWidth = (int) paint.measureText(ellipsis);

        if (textWidth > maxWidth) {
            // Truncate text to fit with ellipsis
            int charactersToFit = 0;
            String substring = "";

            while (charactersToFit < text.length()) {
                charactersToFit++;
                substring = text.substring(0, charactersToFit);
                if (paint.measureText(substring + ellipsis) > maxWidth) {
                    charactersToFit--;
                    substring = text.substring(0, charactersToFit);
                    break;
                }
            }

            return substring + ellipsis;
        }

        return text;
    }

    private void drawMultiLineText(Canvas canvas, String text, Paint paint, int centerX, int startY, int maxWidth) {
        String[] words = text.split(" ");
        StringBuilder currentLine = new StringBuilder();
        int lineY = startY;
        int lineHeight = (int) (paint.getTextSize() * 1.2); // 20% extra for line spacing

        for (String word : words) {
            String testLine = currentLine.toString() + " " + word;
            if (paint.measureText(testLine) > maxWidth) {
                // Draw current line
                if (currentLine.length() > 0) {
                    canvas.drawText(currentLine.toString().trim(), centerX, lineY, paint);
                    lineY += lineHeight;
                }
                currentLine = new StringBuilder(word);
            } else {
                currentLine.append(" ").append(word);
            }
        }
        
        // Draw the last line
        if (currentLine.length() > 0) {
            canvas.drawText(currentLine.toString().trim(), centerX, lineY, paint);
        }
    }

    private int calculateTitleEndY(String title, Paint paint, int maxWidth) {
        String[] words = title.split(" ");
        StringBuilder currentLine = new StringBuilder();
        int lineY = 100; // Starting Y position
        int lineHeight = (int) (paint.getTextSize() * 1.2); // 20% extra for line spacing

        for (String word : words) {
            String testLine = currentLine.toString() + " " + word;
            if (paint.measureText(testLine) > maxWidth) {
                // Move to next line
                if (currentLine.length() > 0) {
                    lineY += lineHeight;
                }
                currentLine = new StringBuilder(word);
            } else {
                currentLine.append(" ").append(word);
            }
        }
        
        // Add height for the last line
        if (currentLine.length() > 0) {
            lineY += lineHeight;
        }
        
        return lineY;
    }

    private int calculateHeaderHeight(List<VerseReference> verseReferences, int totalParts) {
        int baseHeaderHeight = 200;
        
        // Calculate title height using the same logic as drawing
        String title = currentNote.getTitle();
        Paint titlePaint = new Paint();
        titlePaint.setTextSize(60);
        titlePaint.setTypeface(Typeface.DEFAULT_BOLD);
        titlePaint.setAntiAlias(true);
        
        int maxTitleWidth = getResources().getDisplayMetrics().widthPixels - 160; // Leave margin
        
        // Check if title needs smaller font size
        if (titlePaint.measureText(title) > maxTitleWidth) {
            titlePaint.setTextSize(48);
            if (titlePaint.measureText(title) > maxTitleWidth) {
                titlePaint.setTextSize(36);
            }
        }
        
        // Calculate title end position
        int titleEndY = calculateTitleEndY(title, titlePaint, maxTitleWidth);
        
        // Calculate additional height needed
        int partInfoHeight = totalParts > 1 ? 90 : 50; // 90dp if parts, 50dp if no parts
        int appTextHeight = 80; // Height for app text + subtitle
        int bottomPadding = 40; // Extra padding at bottom
        
        int totalHeaderHeight = titleEndY + partInfoHeight + appTextHeight + bottomPadding;
        
        return Math.max(baseHeaderHeight, totalHeaderHeight);
    }

    private void drawTextBasedLogo(Canvas canvas, int centerX, int centerY) {
        // Fallback logo design when image fails to load
        Paint logoPaint = new Paint();
        logoPaint.setColor(Color.parseColor("#FF5722")); // Orange color
        logoPaint.setAntiAlias(true);
        logoPaint.setStyle(Paint.Style.FILL);
        
        // Draw dove shape (simplified)
        Paint dovePaint = new Paint();
        dovePaint.setColor(Color.WHITE);
        dovePaint.setAntiAlias(true);
        dovePaint.setStyle(Paint.Style.FILL);
        
        // Draw cross
        Paint crossPaint = new Paint();
        crossPaint.setColor(Color.parseColor("#FF9800")); // Orange cross
        crossPaint.setStrokeWidth(6);
        crossPaint.setAntiAlias(true);
        crossPaint.setStyle(Paint.Style.STROKE);
        
        // Draw cross
        canvas.drawLine(centerX, centerY - 20, centerX, centerY + 20, crossPaint);
        canvas.drawLine(centerX - 15, centerY, centerX + 15, centerY, crossPaint);
        
        // Draw "HOLY WORD" text
        Paint textPaint = new Paint();
        textPaint.setColor(Color.parseColor("#FF5722"));
        textPaint.setTextSize(24);
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setAntiAlias(true);
        textPaint.setTypeface(Typeface.DEFAULT_BOLD);
        
        canvas.drawText("HOLY WORD", centerX, centerY + 50, textPaint);
    }

    private void drawBottomLogoAndBranding(Canvas canvas, Bitmap bitmap, int startY) {
        int padding = 40;
        int bottomY = startY + 40; // Add some space after verses
        
        // Draw decorative line separator
        Paint separatorPaint = new Paint();
        separatorPaint.setColor(Color.parseColor("#E0E0E0"));
        separatorPaint.setStrokeWidth(1);
        separatorPaint.setAntiAlias(true);
        canvas.drawLine(padding, bottomY, bitmap.getWidth() - padding, bottomY, separatorPaint);
        
        // Load and draw the actual logo on the left side
        try {
            Drawable logoDrawable = ContextCompat.getDrawable(this, R.drawable.logo);
            if (logoDrawable != null) {
                int logoSize = 80; // Increased from 60 to 80
                int logoX = padding + 20; // Position on the left with some margin
                int logoY = bottomY + 20;
                
                logoDrawable.setBounds(logoX, logoY, logoX + logoSize, logoY + logoSize);
                logoDrawable.draw(canvas);
            }
        } catch (Exception e) {
            // Fallback to text-based logo if image fails to load
            drawTextBasedLogo(canvas, padding + 60, bottomY + 50);
        }
        
        // Draw "HOLY WORD" text to the right of logo
        Paint appTextPaint = new Paint();
        appTextPaint.setColor(Color.parseColor("#FF5722")); // Orange color matching logo
        appTextPaint.setTextSize(32); // Increased from 28 to 32
        appTextPaint.setTextAlign(Paint.Align.LEFT); // Changed to left align
        appTextPaint.setAntiAlias(true);
        appTextPaint.setTypeface(Typeface.DEFAULT_BOLD);
        appTextPaint.setShadowLayer(1, 0, 1, Color.parseColor("#20000000")); // Subtle shadow
        
        canvas.drawText("HOLY WORD", padding + 120, bottomY + 60, appTextPaint);
        
        // Draw subtitle to the right of logo
        Paint subtitlePaint = new Paint();
        subtitlePaint.setColor(Color.parseColor("#999999"));
        subtitlePaint.setTextSize(20); // Increased from 18 to 20
        subtitlePaint.setTextAlign(Paint.Align.LEFT); // Changed to left align
        subtitlePaint.setAntiAlias(true);
        
        canvas.drawText("Bible Study & Notes", padding + 120, bottomY + 85, subtitlePaint);
    }

    private Uri saveBitmapToCache(Bitmap bitmap) {
        return saveBitmapToCache(bitmap, "note_" + currentNote.getId());
    }

    private Uri saveBitmapToCache(Bitmap bitmap, String filename) {
        try {
            // Create file in cache directory
            File cacheDir = new File(getCacheDir(), "images");
            if (!cacheDir.exists()) {
                cacheDir.mkdirs();
            }

            File imageFile = new File(cacheDir, filename + ".jpg");

            // Save bitmap to file
            FileOutputStream fos = new FileOutputStream(imageFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
            fos.flush();
            fos.close();

            // Get content URI using FileProvider
            return FileProvider.getUriForFile(this,
                    "com.holywordapp.provider",
                    imageFile);

        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    @Override
    public void onVerseReferenceClick(VerseReference reference) {
        // Navigate to Bible activity to show this verse with correct language
        Intent intent = new Intent(this, BibleActivity.class);
        intent.putExtra("BOOK_NAME", reference.getBookName());
        intent.putExtra("CHAPTER", reference.getChapter());
        intent.putExtra("VERSE", reference.getVerse());
        intent.putExtra("IS_ENGLISH_MODE", reference.isEnglishMode()); // Pass language information
        startActivity(intent);
    }

    @Override
    public void onDeleteVerseReferenceClick(VerseReference reference) {
        new AlertDialog.Builder(this)
                .setTitle("Remove Verse")
                .setMessage("Are you sure you want to remove this verse from the note?")
                .setPositiveButton("Remove", (dialog, which) -> {
                    if (dbHelper.deleteVerseReference(reference.getId())) {
                        Toast.makeText(this, "Verse removed", Toast.LENGTH_SHORT).show();
                        loadNote(); // Refresh the note
                    } else {
                        Toast.makeText(this, "Failed to remove verse", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }
}