# Cross References Format Converter
# This script helps convert the current format to the required format

$inputFile = "app/src/main/assets/cross_references.txt"
$outputFile = "app/src/main/assets/cross_references_formatted.txt"

Write-Host "Converting cross references format..." -ForegroundColor Green

# Read the input file
$lines = Get-Content $inputFile -Encoding UTF8

# Skip the header line
$dataLines = $lines | Select-Object -Skip 1

# Initialize output
$output = @()

# Process each line
foreach ($line in $dataLines) {
    if ($line.Trim() -eq "") { continue }
    
    # Parse the line: "Gen.1.1 Prov.16.4 56"
    $parts = $line -split '\s+'
    if ($parts.Length -ge 2) {
        $fromVerse = $parts[0]  # e.g., "Gen.1.1"
        $toVerse = $parts[1]    # e.g., "Prov.16.4"
        
        # Extract chapter and verse
        $fromParts = $fromVerse -split '\.'
        $toParts = $toVerse -split '\.'
        
        if ($fromParts.Length -ge 3 -and $toParts.Length -ge 3) {
            $fromBook = $fromParts[0]
            $fromChapter = $fromParts[1]
            $fromVerseNum = $fromParts[2]
            $toBook = $toParts[0]
            $toChapter = $toParts[1]
            $toVerseNum = $toParts[2]
            
            # Add to output (you'll need to add the actual verse text)
            $output += "SOURCE:$fromBook|$fromChapter|$fromVerseNum|[VERSE_TEXT_HERE]"
            $output += "REF:$toBook|$toChapter|$toVerseNum|[VERSE_TEXT_HERE]|parallel"
            $output += ""
        }
    }
}

# Write to output file
$output | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Conversion completed! Check: $outputFile" -ForegroundColor Green
Write-Host "Note: You need to manually add the verse text where [VERSE_TEXT_HERE] appears" -ForegroundColor Yellow
Write-Host "Also, you need to convert English book names to Telugu names manually" -ForegroundColor Yellow

