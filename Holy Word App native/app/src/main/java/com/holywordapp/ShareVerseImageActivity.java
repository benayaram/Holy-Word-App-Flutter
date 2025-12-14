package com.holywordapp;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.app.AlertDialog;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewParent;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;
import androidx.core.content.res.ResourcesCompat;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;

public class ShareVerseImageActivity extends AppCompatActivity {
    private ImageView imagePreview;
    private TextView verseTextOverlay;
    private Spinner fontSpinner, colorSpinner, bgSpinner;
    private SeekBar textSizeSeekBar;
    private com.google.android.material.button.MaterialButton btnExport;

    private String verseText;
    private int textColor = Color.BLACK;
    private int bgColor = Color.WHITE;
    private int textSize = 32;
    private int textAlign = View.TEXT_ALIGNMENT_CENTER;
    private float dX, dY;
    private int lastAction;
    private static final int PICK_IMAGE = 1001;
    private Uri bgImageUri = null;
    private Spinner ratioSpinner;
    private CheckBox watermarkCheckBox;
    private boolean showWatermark = true;
    private int aspectW = 1, aspectH = 1;
    private com.google.android.material.button.MaterialButton btnChooseGallery, btnTextColor;
    private Typeface[] customFonts;
    private String[] fontPreviews;
    private com.google.android.material.button.MaterialButton btnAlignLeft, btnAlignCenter, btnAlignRight;
    private Spinner refFontSpinner;
    private SeekBar refTextSizeSeekBar;
    private TextView verseRefOverlay;
    private int refTextSize = 18;
    private Typeface[] refFonts;
    private int refTextColor = Color.DKGRAY;
    private com.google.android.material.button.MaterialButton btnRefColor;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_share_verse_image);

        // Set up toolbar
        androidx.appcompat.widget.Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }

        // Initialize views with null checks
        imagePreview = findViewById(R.id.imagePreview);
        verseTextOverlay = findViewById(R.id.verseTextOverlay);
        verseRefOverlay = findViewById(R.id.verseRefOverlay);
        fontSpinner = findViewById(R.id.fontSpinner);
        textSizeSeekBar = findViewById(R.id.textSizeSeekBar);
        btnExport = findViewById(R.id.btnExport);
        ratioSpinner = findViewById(R.id.ratioSpinner);
        btnAlignLeft = findViewById(R.id.btnAlignLeft);
        btnAlignCenter = findViewById(R.id.btnAlignCenter);
        btnAlignRight = findViewById(R.id.btnAlignRight);
        watermarkCheckBox = findViewById(R.id.watermarkCheckBox);
        btnChooseGallery = findViewById(R.id.btnChooseGallery);
        btnTextColor = findViewById(R.id.btnTextColor);
        refFontSpinner = findViewById(R.id.refFontSpinner);
        refTextSizeSeekBar = findViewById(R.id.refTextSizeSeekBar);
        btnRefColor = findViewById(R.id.btnRefColor);
        if (verseRefOverlay != null) {
            verseRefOverlay.setTextColor(refTextColor);
        }


        // Load all custom fonts (updated to match current file names)
        customFonts = new Typeface[] {
                ResourcesCompat.getFont(this, R.font.seelaveerraju),
            ResourcesCompat.getFont(this, R.font.bvsatyamurty),
            ResourcesCompat.getFont(this, R.font.potti_sreeramulu),
            ResourcesCompat.getFont(this, R.font.spbalasubrahmanyam),
            ResourcesCompat.getFont(this, R.font.jims),
            ResourcesCompat.getFont(this, R.font.jims_italic),
            ResourcesCompat.getFont(this, R.font.mandali_regular),
            ResourcesCompat.getFont(this, R.font.mandali_bold),
            ResourcesCompat.getFont(this, R.font.mandali_italic),
            ResourcesCompat.getFont(this, R.font.mandali_bold_italic),
            ResourcesCompat.getFont(this, R.font.ramabhadra_regular),
            ResourcesCompat.getFont(this, R.font.ramabhadra_italic),
            ResourcesCompat.getFont(this, R.font.syamala_ramana),
            ResourcesCompat.getFont(this, R.font.kanakadurga),
            ResourcesCompat.getFont(this, R.font.kanakadurga_italic),
            ResourcesCompat.getFont(this, R.font.purushothamaa),
            ResourcesCompat.getFont(this, R.font.purushothamaa_italic),
            ResourcesCompat.getFont(this, R.font.annamayya),
            ResourcesCompat.getFont(this, R.font.annamayya_bold),
            ResourcesCompat.getFont(this, R.font.annamayya_italic),
            ResourcesCompat.getFont(this, R.font.annamayya_bold_italic),
            ResourcesCompat.getFont(this, R.font.nandakam),
            ResourcesCompat.getFont(this, R.font.nandakam_italic),
            ResourcesCompat.getFont(this, R.font.sree_krushnadevaraya),
            ResourcesCompat.getFont(this, R.font.sree_krushnadevaraya_italic),
            ResourcesCompat.getFont(this, R.font.lakkireddy),
            ResourcesCompat.getFont(this, R.font.raviprakash),
            ResourcesCompat.getFont(this, R.font.suravaram),
            ResourcesCompat.getFont(this, R.font.suravaram_italic),
            ResourcesCompat.getFont(this, R.font.suranna_regular),
            ResourcesCompat.getFont(this, R.font.suranna_bold),
            ResourcesCompat.getFont(this, R.font.suranna_italic),
            ResourcesCompat.getFont(this, R.font.suranna_bold_italic),
            ResourcesCompat.getFont(this, R.font.ntr),
            ResourcesCompat.getFont(this, R.font.ntr_italic),
            ResourcesCompat.getFont(this, R.font.nats),
            ResourcesCompat.getFont(this, R.font.nats_italic),
            ResourcesCompat.getFont(this, R.font.mallanna),
            ResourcesCompat.getFont(this, R.font.mallanna_italic),
            ResourcesCompat.getFont(this, R.font.gurajada),
            ResourcesCompat.getFont(this, R.font.gurajada_italic),
            ResourcesCompat.getFont(this, R.font.gidugu),
            ResourcesCompat.getFont(this, R.font.gidugu_italic),
            ResourcesCompat.getFont(this, R.font.dhurjati),
            ResourcesCompat.getFont(this, R.font.dhurjati_italic),
            ResourcesCompat.getFont(this, R.font.chathura_regular),
            ResourcesCompat.getFont(this, R.font.chathura_bold),
            ResourcesCompat.getFont(this, R.font.chathura_light),
            ResourcesCompat.getFont(this, R.font.chathura_thin),
            ResourcesCompat.getFont(this, R.font.chathura_extrabold),
            ResourcesCompat.getFont(this, R.font.peddana_regular),
            ResourcesCompat.getFont(this, R.font.ramaneeyawin)
        };
        fontPreviews = new String[] {
                "శీల వీరరాజు నమూనా",
                "బి.వి. సత్యమూర్తి నమూనా",
            "పొట్టి శ్రీరాములు నమూనా",
            "ఎస్.పి. బాలసుబ్రహ్మణ్యం నమూనా",
            "జిమ్స్ నమూనా",
            "జిమ్స్ ఇటాలిక్ నమూనా",
            "మండలి రెగ్యులర్ నమూనా",
            "మండలి బోల్డ్ నమూనా",
            "మండలి ఇటాలిక్ నమూనా",
            "మండలి బోల్డ్ ఇటాలిక్ నమూనా",
            "రామభద్ర రెగ్యులర్ నమూనా",
            "రామభద్ర ఇటాలిక్ నమూనా",
            "శ్యామల రమణ నమూనా",
            "కనకదుర్గ నమూనా",
            "కనకదుర్గ ఇటాలిక్ నమూనా",
            "పురుషోత్తమ నమూనా",
            "పురుషోత్తమ ఇటాలిక్ నమూనా",
            "అన్నమయ్య నమూనా",
            "అన్నమయ్య బోల్డ్ నమూనా",
            "అన్నమయ్య ఇటాలిక్ నమూనా",
            "అన్నమయ్య బోల్డ్ ఇటాలిక్ నమూనా",
            "నందకం నమూనా",
            "నందకం ఇటాలిక్ నమూనా",
            "శ్రీ కృష్ణదేవరాయ నమూనా",
            "శ్రీ కృష్ణదేవరాయ ఇటాలిక్ నమూనా",
            "లక్కీరెడ్డి నమూనా",
            "రవిప్రకాశ్ నమూనా",
            "సురవరం నమూనా",
            "సురవరం ఇటాలిక్ నమూనా",
            "సురన్న రెగ్యులర్ నమూనా",
            "సురన్న బోల్డ్ నమూనా",
            "సురన్న ఇటాలిక్ నమూనా",
            "సురన్న బోల్డ్ ఇటాలిక్ నమూనా",
            "ఎన్.టి.ఆర్. నమూనా",
            "ఎన్.టి.ఆర్. ఇటాలిక్ నమూనా",
            "ఎన్.ఎ.టి.ఎస్. నమూనా",
            "ఎన్.ఎ.టి.ఎస్. ఇటాలిక్ నమూనా",
            "మల్లన్న నమూనా",
            "మల్లన్న ఇటాలిక్ నమూనా",
            "గురజాడ నమూనా",
            "గురజాడ ఇటాలిక్ నమూనా",
            "గిడుగు నమూనా",
            "గిడుగు ఇటాలిక్ నమూనా",
            "ధుర్జతి నమూనా",
            "ధుర్జతి ఇటాలిక్ నమూనా",
            "చతుర రెగ్యులర్ నమూనా",
            "చతుర బోల్డ్ నమూనా",
            "చతుర లైట్ నమూనా",
            "చతుర థిన్ నమూనా",
            "చతుర ఎక్స్ట్రా బోల్డ్ నమూనా",
            "పెద్దన రెగ్యులర్ నమూనా",
            "రమణీయ విన్ నమూనా"
        };

        // Set up alignment controls
        if (btnAlignLeft != null) {
            btnAlignLeft.setOnClickListener(v -> {
                if (verseTextOverlay != null) {
                    verseTextOverlay.setTextAlignment(View.TEXT_ALIGNMENT_TEXT_START);
                }
                if (verseRefOverlay != null) {
                    verseRefOverlay.setTextAlignment(View.TEXT_ALIGNMENT_TEXT_START);
                }
            });
        }
        if (btnAlignCenter != null) {
            btnAlignCenter.setOnClickListener(v -> {
                if (verseTextOverlay != null) {
                    verseTextOverlay.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
                }
                if (verseRefOverlay != null) {
                    verseRefOverlay.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
                }
            });
        }
        if (btnAlignRight != null) {
            btnAlignRight.setOnClickListener(v -> {
                if (verseTextOverlay != null) {
                    verseTextOverlay.setTextAlignment(View.TEXT_ALIGNMENT_TEXT_END);
                }
                if (verseRefOverlay != null) {
                    verseRefOverlay.setTextAlignment(View.TEXT_ALIGNMENT_TEXT_END);
                }
            });
        }
        // Default alignment and styling
        if (verseTextOverlay != null) {
            verseTextOverlay.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
            verseTextOverlay.setTextColor(textColor);
            verseTextOverlay.setTextSize(textSize);
        }
        if (verseRefOverlay != null) {
            verseRefOverlay.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
            verseRefOverlay.setTextColor(refTextColor);
            verseRefOverlay.setTextSize(refTextSize);
        }

        // Reference font picker (reuse customFonts)
        refFonts = customFonts;
        if (refFontSpinner != null) {
            ArrayAdapter<String> refFontAdapter = new ArrayAdapter<String>(this, android.R.layout.simple_spinner_item, fontPreviews) {
                @Override
                public View getView(int position, View convertView, ViewGroup parent) {
                    TextView tv = (TextView) super.getView(position, convertView, parent);
                    if (position < refFonts.length && refFonts[position] != null) {
                        tv.setTypeface(refFonts[position]);
                    }
                    return tv;
                }
                @Override
                public View getDropDownView(int position, View convertView, ViewGroup parent) {
                    TextView tv = (TextView) super.getDropDownView(position, convertView, parent);
                    if (position < refFonts.length && refFonts[position] != null) {
                        tv.setTypeface(refFonts[position]);
                    }
                    return tv;
                }
            };
            refFontAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            refFontSpinner.setAdapter(refFontAdapter);
            refFontSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    if (position < refFonts.length && refFonts[position] != null && verseRefOverlay != null) {
                        verseRefOverlay.setTypeface(refFonts[position]);
                    }
                }
                @Override public void onNothingSelected(AdapterView<?> parent) {}
            });
        }
        // Reference text size
        if (refTextSizeSeekBar != null) {
            refTextSizeSeekBar.setMax(40);
            refTextSizeSeekBar.setProgress(refTextSize);
            refTextSizeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    refTextSize = Math.max(10, progress);
                    if (verseRefOverlay != null) {
                        verseRefOverlay.setTextSize(refTextSize);
                    }
                }
                @Override public void onStartTrackingTouch(SeekBar seekBar) {}
                @Override public void onStopTrackingTouch(SeekBar seekBar) {}
            });
        }
        if (verseRefOverlay != null) {
            verseRefOverlay.setTextSize(refTextSize);
            verseRefOverlay.setTextColor(refTextColor);
        }

        // Set verse text and reference from intent
        ArrayList<String> verses = getIntent().getStringArrayListExtra("VERSES");
        if (verses != null && !verses.isEmpty()) {
            StringBuilder sb = new StringBuilder();
            String lastRef = "";
            for (String v : verses) {
                int dashIdx = v.lastIndexOf("-");
                if (dashIdx != -1 && dashIdx + 1 < v.length()) {
                    sb.append(v.substring(dashIdx + 1).trim()).append("\n");
                    lastRef = v.substring(0, dashIdx).trim();
                } else {
                    sb.append(v).append("\n");
                }
            }
            if (verseTextOverlay != null) {
                verseTextOverlay.setText(sb.toString().trim());
            }
            if (verseRefOverlay != null) {
                verseRefOverlay.setText(lastRef);
            }
        } else {
            if (verseTextOverlay != null) {
                verseTextOverlay.setText("");
            }
            if (verseRefOverlay != null) {
                verseRefOverlay.setText("");
            }
        }

        // Initialize the preview with default background color
        if (imagePreview != null) {
            imagePreview.setBackgroundColor(bgColor);
        }

        // Font spinner with preview
        if (fontSpinner != null) {
            ArrayAdapter<String> fontAdapter = new ArrayAdapter<String>(this, android.R.layout.simple_spinner_item, fontPreviews) {
                @Override
                public View getView(int position, View convertView, ViewGroup parent) {
                    TextView tv = (TextView) super.getView(position, convertView, parent);
                    if (position < customFonts.length && customFonts[position] != null) {
                        tv.setTypeface(customFonts[position]);
                    }
                    return tv;
                }
                @Override
                public View getDropDownView(int position, View convertView, ViewGroup parent) {
                    TextView tv = (TextView) super.getDropDownView(position, convertView, parent);
                    if (position < customFonts.length && customFonts[position] != null) {
                        tv.setTypeface(customFonts[position]);
                    }
                    return tv;
                }
            };
            fontAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            fontSpinner.setAdapter(fontAdapter);
            fontSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    if (position < customFonts.length && customFonts[position] != null && verseTextOverlay != null) {
                        verseTextOverlay.setTypeface(customFonts[position]);
                    } else if (verseTextOverlay != null) {
                        verseTextOverlay.setTypeface(Typeface.DEFAULT);
                    }
                }
                @Override public void onNothingSelected(AdapterView<?> parent) {}
            });
        }

        // Color pickers
        if (btnTextColor != null) {
            btnTextColor.setOnClickListener(v -> showColorPicker(true));
        }

        if (btnRefColor != null) {
            btnRefColor.setOnClickListener(v -> showColorPickerForReference());
        }

        // Gallery button
        if (btnChooseGallery != null) {
            btnChooseGallery.setOnClickListener(v -> {
                Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                startActivityForResult(intent, PICK_IMAGE);
            });
        }

        // Aspect ratio options
        if (ratioSpinner != null) {
            final String[] ratios = {"1:1", "4:5", "16:9", "9:16"};
            final int[][] ratioValues = {{1,1},{4,5},{16,9},{9,16}};
            ArrayAdapter<String> ratioAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, ratios);
            ratioAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            ratioSpinner.setAdapter(ratioAdapter);
            ratioSpinner.setSelection(0);
            ratioSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    aspectW = ratioValues[position][0];
                    aspectH = ratioValues[position][1];
                    updatePreviewAspectRatio();
                }
                @Override public void onNothingSelected(AdapterView<?> parent) {}
            });
            
            // Set initial aspect ratio after layout is complete
            imagePreview.post(() -> {
                updatePreviewAspectRatio();
                // Ensure the preview container is visible
                androidx.constraintlayout.widget.ConstraintLayout previewContainer = findViewById(R.id.previewContainer);
                if (previewContainer != null) {
                    previewContainer.setVisibility(View.VISIBLE);
                }
            });
        }

        if (watermarkCheckBox != null) {
            watermarkCheckBox.setOnCheckedChangeListener((buttonView, isChecked) -> showWatermark = isChecked);
        }

        // Text size
        if (textSizeSeekBar != null) {
            textSizeSeekBar.setMax(64);
            textSizeSeekBar.setProgress(textSize);
            textSizeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    textSize = Math.max(12, progress);
                    if (verseTextOverlay != null) {
                        verseTextOverlay.setTextSize(textSize);
                    }
                }
                @Override public void onStartTrackingTouch(SeekBar seekBar) {}
                @Override public void onStopTrackingTouch(SeekBar seekBar) {}
            });
        }



        // Drag/Move text overlay
        if (verseTextOverlay != null) {
            verseTextOverlay.setOnTouchListener((v, event) -> {
                switch (event.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN:
                        dX = v.getX() - event.getRawX();
                        dY = v.getY() - event.getRawY();
                        lastAction = MotionEvent.ACTION_DOWN;
                        // Request parent to not intercept touch events
                        ViewParent parent = v.getParent();
                        if (parent != null) {
                            parent.requestDisallowInterceptTouchEvent(true);
                        }
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        v.setX(event.getRawX() + dX);
                        v.setY(event.getRawY() + dY);
                        lastAction = MotionEvent.ACTION_MOVE;
                        return true;
                    case MotionEvent.ACTION_UP:
                        if (lastAction == MotionEvent.ACTION_DOWN) {
                            // Click
                        }
                        // Allow parent to intercept touch events again
                        ViewParent parentUp = v.getParent();
                        if (parentUp != null) {
                            parentUp.requestDisallowInterceptTouchEvent(false);
                        }
                        return true;
                    default:
                        return false;
                }
            });
        }

        if (verseRefOverlay != null) {
            verseRefOverlay.setOnTouchListener((v, event) -> {
                switch (event.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN:
                        dX = v.getX() - event.getRawX();
                        dY = v.getY() - event.getRawY();
                        lastAction = MotionEvent.ACTION_DOWN;
                        // Request parent to not intercept touch events
                        ViewParent parent = v.getParent();
                        if (parent != null) {
                            parent.requestDisallowInterceptTouchEvent(true);
                        }
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        v.setX(event.getRawX() + dX);
                        v.setY(event.getRawY() + dY);
                        lastAction = MotionEvent.ACTION_MOVE;
                        return true;
                    case MotionEvent.ACTION_UP:
                        if (lastAction == MotionEvent.ACTION_DOWN) {
                            // Click event if needed
                        }
                        // Allow parent to intercept touch events again
                        ViewParent parentUp = v.getParent();
                        if (parentUp != null) {
                            parentUp.requestDisallowInterceptTouchEvent(false);
                        }
                        return true;
                    default:
                        return false;
                }
            });
        }

        // Export/share
        if (btnExport != null) {
            btnExport.setOnClickListener(v -> {
                try {
                    Bitmap bitmap = createBitmapFromView();
                    if (bitmap == null) {
                        Toast.makeText(this, "Failed to create image", Toast.LENGTH_SHORT).show();
                        return;
                    }
                    
                    File cacheDir = getExternalCacheDir();
                    if (cacheDir == null) {
                        cacheDir = getCacheDir();
                    }
                    
                    File file = new File(cacheDir, "Daily_verse.png");
                    FileOutputStream out = new FileOutputStream(file);
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
                    out.flush();
                    out.close();
                    
                    Uri uri = FileProvider.getUriForFile(this, "com.holywordapp.provider", file);
                    Intent shareIntent = new Intent(Intent.ACTION_SEND);
                    shareIntent.setType("image/png");
                    shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
                    shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    startActivity(Intent.createChooser(shareIntent, "Share Verse Image"));
                } catch (IOException e) {
                    Toast.makeText(this, "Failed to export image: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                } catch (Exception e) {
                    Toast.makeText(this, "Failed to share image: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });
        }
    }

    private void updatePreviewAspectRatio() {
        if (imagePreview != null) {
            // Find the previewContainer directly
            androidx.constraintlayout.widget.ConstraintLayout previewContainer = findViewById(R.id.previewContainer);
            if (previewContainer != null) {
                // Get the current layout params
                android.widget.LinearLayout.LayoutParams params = (android.widget.LinearLayout.LayoutParams) previewContainer.getLayoutParams();
                if (params != null) {
                    // Calculate the height based on the aspect ratio
                    int containerWidth = previewContainer.getWidth();
                    if (containerWidth == 0) {
                        // If width is not available yet, use screen width
                        containerWidth = getResources().getDisplayMetrics().widthPixels - 64; // Account for padding
                    }
                    
                    int containerHeight = (containerWidth * aspectH) / aspectW;
                    
                    // Set the height to maintain aspect ratio
                    params.height = containerHeight;
                    previewContainer.setLayoutParams(params);
                    
                    // Request layout update
                    previewContainer.requestLayout();
                    
                    // Force a layout pass to ensure the new ratio is applied
                    previewContainer.post(() -> {
                        previewContainer.requestLayout();
                        previewContainer.invalidate();
                    });
                }
            }
        }
    }

    private Bitmap createBitmapFromView() {
        try {
            // Calculate export size based on aspect ratio
            if (imagePreview == null) {
                return null;
            }
            
            // Use the previewContainer dimensions instead of imagePreview
            androidx.constraintlayout.widget.ConstraintLayout previewContainer = findViewById(R.id.previewContainer);
            int width = 1080; // Default width
            int height = 1080; // Default height
            
            if (previewContainer != null) {
                width = previewContainer.getWidth();
                if (width == 0) width = previewContainer.getMeasuredWidth();
                if (width == 0) width = getResources().getDisplayMetrics().widthPixels - 64; // Account for padding
                if (width <= 0) width = 1080; // Default width if all else fails
                
                height = previewContainer.getHeight();
                if (height == 0) height = previewContainer.getMeasuredHeight();
                if (height == 0) height = width * aspectH / aspectW;
                if (height <= 0) height = 1080; // Default height if calculation fails
            } else {
                // Fallback to aspect ratio calculation
                width = getResources().getDisplayMetrics().widthPixels - 64;
                height = width * aspectH / aspectW;
                if (height <= 0) height = 1080;
            }
            
            Bitmap baseBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            if (baseBitmap == null) {
                return null;
            }
            Canvas canvas = new Canvas(baseBitmap);

        // Draw background (color or gallery image)
        if (bgImageUri != null) {
            try {
                Bitmap bgBitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), bgImageUri);
                Bitmap scaledBg = Bitmap.createScaledBitmap(bgBitmap, width, height, true);
                canvas.drawBitmap(scaledBg, 0, 0, null);
            } catch (Exception e) {
                canvas.drawColor(bgColor);
            }
        } else {
            canvas.drawColor(bgColor);
        }

        // Draw verse text overlay at its current position (scaled to new height)
        if (verseTextOverlay != null && verseTextOverlay.getWidth() > 0 && verseTextOverlay.getHeight() > 0) {
            try {
                verseTextOverlay.setDrawingCacheEnabled(true);
                Bitmap textBitmap = Bitmap.createBitmap(verseTextOverlay.getWidth(), verseTextOverlay.getHeight(), Bitmap.Config.ARGB_8888);
                if (textBitmap != null) {
                    Canvas textCanvas = new Canvas(textBitmap);
                    verseTextOverlay.draw(textCanvas);
                    
                    // Get position relative to the previewContainer
                    float textX = verseTextOverlay.getX();
                    float textY = verseTextOverlay.getY();
                    
                    // Account for container padding
                    int containerPadding = 16; // 16dp padding from layout
                    textX -= containerPadding;
                    textY -= containerPadding;
                    
                    // Scale to match the export dimensions
                    if (previewContainer != null) {
                        float scaleX = (float) width / previewContainer.getWidth();
                        float scaleY = (float) height / previewContainer.getHeight();
                        textX *= scaleX;
                        textY *= scaleY;
                    }
                    
                    canvas.drawBitmap(textBitmap, textX, textY, null);
                }
                verseTextOverlay.setDrawingCacheEnabled(false);
            } catch (Exception e) {
                // Ignore text overlay errors
                if (verseTextOverlay != null) {
                    verseTextOverlay.setDrawingCacheEnabled(false);
                }
            }
        }

        // Draw verse reference overlay below the verse text
        if (verseRefOverlay != null && verseRefOverlay.getWidth() > 0 && verseRefOverlay.getHeight() > 0) {
            try {
                verseRefOverlay.setDrawingCacheEnabled(true);
                Bitmap refBitmap = Bitmap.createBitmap(verseRefOverlay.getWidth(), verseRefOverlay.getHeight(), Bitmap.Config.ARGB_8888);
                if (refBitmap != null) {
                    Canvas refCanvas = new Canvas(refBitmap);
                    verseRefOverlay.draw(refCanvas);
                    
                    // Get position relative to the previewContainer
                    float refX = verseRefOverlay.getX();
                    float refY = verseRefOverlay.getY();
                    
                    // Account for container padding
                    int containerPadding = 16; // 16dp padding from layout
                    refX -= containerPadding;
                    refY -= containerPadding;
                    
                    // Scale to match the export dimensions
                    if (previewContainer != null) {
                        float scaleX = (float) width / previewContainer.getWidth();
                        float scaleY = (float) height / previewContainer.getHeight();
                        refX *= scaleX;
                        refY *= scaleY;
                    }
                    
                    canvas.drawBitmap(refBitmap, refX, refY, null);
                }
                verseRefOverlay.setDrawingCacheEnabled(false);
            } catch (Exception e) {
                // Ignore reference overlay errors
                if (verseRefOverlay != null) {
                    verseRefOverlay.setDrawingCacheEnabled(false);
                }
            }
        }

        // Draw logo watermark (top-right, 70% opacity) if enabled
        if (showWatermark) {
            try {
                Bitmap logo = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
                if (logo != null) {
                    // Calculate logo size based on image dimensions (proportional)
                    int maxLogoSize = Math.min(width, height) / 6; // 1/6th of the smaller dimension
                    int logoW = Math.min(logo.getWidth(), maxLogoSize);
                    int logoH = (logoW * logo.getHeight()) / logo.getWidth(); // maintain aspect ratio
                    
                    Bitmap scaledLogo = Bitmap.createScaledBitmap(logo, logoW, logoH, true);
                    Paint paint = new Paint();
                    paint.setAlpha(180); // 70% opacity
                    float x = baseBitmap.getWidth() - logoW - 20; // 20px from corner
                    float y = 20; // 20px from top
                    canvas.drawBitmap(scaledLogo, x, y, paint);
                }
            } catch (Exception e) {
                // Ignore logo loading errors
            }
        }

        imagePreview.setDrawingCacheEnabled(false);
        return baseBitmap;
        } catch (Exception e) {
            // Log the error for debugging
            e.printStackTrace();
            return null;
        }
    }

    private void showColorPicker(boolean isText) {
        final int[] colors = {Color.BLACK, Color.WHITE, Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.CYAN, Color.MAGENTA, Color.DKGRAY, Color.LTGRAY};
        final String[] colorNames = {"Black", "White", "Red", "Blue", "Green", "Yellow", "Cyan", "Magenta", "Dark Gray", "Light Gray"};
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(isText ? "Pick Text Color" : "Pick Background Color");

        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.select_dialog_item, colorNames) {
            @Override
            public View getView(int position, View convertView, ViewGroup parent) {
                View view = super.getView(position, convertView, parent);
                TextView tv = (TextView) view.findViewById(android.R.id.text1);
                tv.setText(colorNames[position]);
                tv.setCompoundDrawablesWithIntrinsicBounds(colorBox(colors[position]), null, null, null);
                tv.setCompoundDrawablePadding(24);
                return view;
            }
        };

        builder.setAdapter(adapter, (dialog, which) -> {
            if (isText) {
                textColor = colors[which];
                verseTextOverlay.setTextColor(textColor);
            } else {
                bgColor = colors[which];
                imagePreview.setImageDrawable(null); // Remove gallery image if any
                imagePreview.setBackgroundColor(bgColor);
                bgImageUri = null;
            }
        });
        builder.show();
    }

    private void showColorPickerForReference() {
        final int[] colors = {Color.BLACK, Color.WHITE, Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.CYAN, Color.MAGENTA, Color.DKGRAY, Color.LTGRAY};
        final String[] colorNames = {"Black", "White", "Red", "Blue", "Green", "Yellow", "Cyan", "Magenta", "Dark Gray", "Light Gray"};
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Pick Reference Color");

        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.select_dialog_item, colorNames) {
            @Override
            public View getView(int position, View convertView, ViewGroup parent) {
                View view = super.getView(position, convertView, parent);
                TextView tv = (TextView) view.findViewById(android.R.id.text1);
                tv.setText(colorNames[position]);
                tv.setCompoundDrawablesWithIntrinsicBounds(colorBox(colors[position]), null, null, null);
                tv.setCompoundDrawablePadding(24);
                return view;
            }
        };

        builder.setAdapter(adapter, (dialog, which) -> {
            refTextColor = colors[which];
            verseRefOverlay.setTextColor(refTextColor);
        });
        builder.show();
    }

    private android.graphics.drawable.Drawable colorBox(int color) {
        int size = (int) (32 * getResources().getDisplayMetrics().density);
        android.graphics.drawable.ShapeDrawable d = new android.graphics.drawable.ShapeDrawable(new android.graphics.drawable.shapes.RectShape());
        d.getPaint().setColor(color);
        d.setIntrinsicWidth(size);
        d.setIntrinsicHeight(size);
        d.getPaint().setStyle(Paint.Style.FILL);
        d.getPaint().setStrokeWidth(2);
        d.getPaint().setAntiAlias(true);
        return d;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE && resultCode == RESULT_OK && data != null) {
            try {
                bgImageUri = data.getData();
                if (bgImageUri != null) {
                    imagePreview.setBackgroundColor(Color.TRANSPARENT); // Remove color if any
                    imagePreview.setImageURI(bgImageUri);
                } else {
                    Toast.makeText(this, "No image selected", Toast.LENGTH_SHORT).show();
                }
            } catch (Exception e) {
                Toast.makeText(this, "Failed to load image", Toast.LENGTH_SHORT).show();
            }
        }
    }

    @Override
    public boolean onOptionsItemSelected(android.view.MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
} 