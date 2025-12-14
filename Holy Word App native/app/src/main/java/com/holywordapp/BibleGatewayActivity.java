package com.holywordapp;

import android.annotation.SuppressLint;
import android.app.ProgressDialog;
import android.content.Context;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

public class BibleGatewayActivity extends AppCompatActivity {

    private WebView webView;
    private ProgressDialog progressDialog;
    private LinearLayout errorLayout;
    private TextView errorText;
    private Button retryButton;
    
    private static final String BIBLE_GATEWAY_URL = "https://www.biblegateway.com/";

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bible_gateway);

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Bible Gateway");
        }
        
        initViews();
        setupWebView();
        loadBibleGateway();
    }

    private void initViews() {
        webView = findViewById(R.id.webview);
        errorLayout = findViewById(R.id.error_layout);
        errorText = findViewById(R.id.error_text);
        retryButton = findViewById(R.id.retry_button);

        retryButton.setOnClickListener(v -> loadBibleGateway());
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void setupWebView() {
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);
        webSettings.setBuiltInZoomControls(true);
        webSettings.setDisplayZoomControls(false);
        webSettings.setSupportZoom(true);
        webSettings.setDefaultTextEncodingName("utf-8");
        
        // Basic compatibility settings
        webSettings.setAllowFileAccess(true);
        webSettings.setLoadsImagesAutomatically(true);
        
        // Set renderer priority
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        } else {
            webView.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        }

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
                showLoadingDialog();
                hideErrorLayout();
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                hideLoadingDialog();
                
                // Check if the page loaded successfully
                if (url.contains("biblegateway.com")) {
                    Toast.makeText(BibleGatewayActivity.this, "Bible Gateway loaded successfully!", Toast.LENGTH_SHORT).show();
                }
            }
            
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return true;
            }
            
            @Override
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                hideLoadingDialog();
                String errorMessage = "Failed to load Bible Gateway: " + description;
                showErrorLayout(errorMessage);
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                if (progressDialog != null && progressDialog.isShowing()) {
                    progressDialog.setMessage("Loading Bible Gateway... " + newProgress + "%");
                }
            }
        });
    }

    private void loadBibleGateway() {
        // Simple direct loading of the Bible Gateway URL
        webView.loadUrl(BIBLE_GATEWAY_URL);
    }

    private void showLoadingDialog() {
        if (progressDialog == null) {
            progressDialog = new ProgressDialog(this);
            progressDialog.setMessage("Loading Bible Gateway...");
            progressDialog.setCancelable(false);
        }
        progressDialog.show();
    }

    private void hideLoadingDialog() {
        if (progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    private void showErrorLayout(String errorMessage) {
        errorText.setText(errorMessage);
        errorLayout.setVisibility(View.VISIBLE);
        webView.setVisibility(View.GONE);
    }

    private void hideErrorLayout() {
        errorLayout.setVisibility(View.GONE);
        webView.setVisibility(View.VISIBLE);
    }

    // Handle the back button in the action bar
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // Override back button to navigate WebView history
    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    // Clean up resources when activity is destroyed
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (webView != null) {
            webView.destroy();
        }
        if (progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }
}
