package com.holywordapp.onboarding;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;

import com.holywordapp.R;

public class VideoPopupActivity extends Activity {

    private WebView webView;
    private Button closeButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video_popup);

        initViews();
        setupWebView();
        setupListeners();
    }

    private void initViews() {
        webView = findViewById(R.id.webview);
        closeButton = findViewById(R.id.close_button);
    }

    private void setupWebView() {
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setLoadWithOverviewMode(true);
        webView.getSettings().setUseWideViewPort(true);
        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient());

        // Load YouTube video
        String videoId = "dQw4w9WgXcQ"; // Replace with your actual video ID
        String videoUrl = "https://www.youtube.com/embed/" + videoId + "?autoplay=1&rel=0&showinfo=0";
        
        String html = "<!DOCTYPE html>" +
                "<html>" +
                "<head>" +
                "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
                "<style>" +
                "body { margin: 0; padding: 0; background: #000; }" +
                "iframe { width: 100%; height: 100%; border: none; }" +
                "</style>" +
                "</head>" +
                "<body>" +
                "<iframe src='" + videoUrl + "' " +
                "allowfullscreen allow='autoplay; encrypted-media'>" +
                "</iframe>" +
                "</body>" +
                "</html>";

        webView.loadDataWithBaseURL("https://www.youtube.com", html, "text/html", "utf-8", null);
    }

    private void setupListeners() {
        closeButton.setOnClickListener(v -> finish());
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
