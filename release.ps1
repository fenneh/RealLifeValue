# This script automates the git workflow for releasing new versions

# 1. Add all files to git
Write-Host "Adding all files to git..." -ForegroundColor Cyan
git add .

# 2. Prompt for commit message with default
$commitMessage = Read-Host "Enter commit message (press Enter for default 'updates')"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "updates"
}

# 3. Commit with the message
Write-Host "Committing with message: '$commitMessage'" -ForegroundColor Cyan
git commit -m $commitMessage

# 4. Extract version from .toc file
$tocContent = Get-Content -Path "*.toc" -Raw
$versionMatch = [regex]::Match($tocContent, '## Version: ([\d\.]+)')
if ($versionMatch.Success) {
    $version = $versionMatch.Groups[1].Value
    Write-Host "Detected version: $version" -ForegroundColor Green
} else {
    Write-Host "Could not detect version from .toc file. Aborting." -ForegroundColor Red
    exit 1
}

# 5. Check if tag exists for this version
$tagExists = git tag -l "v$version"
if ([string]::IsNullOrWhiteSpace($tagExists)) {
    # Tag doesn't exist, create it
    Write-Host "Creating tag v$version..." -ForegroundColor Cyan
    git tag "v$version"
    Write-Host "Tag v$version created successfully" -ForegroundColor Green
} else {
    Write-Host "Tag v$version already exists" -ForegroundColor Yellow
}

# 6. Ask for confirmation before pushing
$confirmation = Read-Host "Do you want to push to origin main with tags? (y/n)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    Write-Host "Pushing to origin main with tags..." -ForegroundColor Cyan
    git push origin main --tags
    Write-Host "Push completed successfully" -ForegroundColor Green
    Write-Host "Release process completed" -ForegroundColor Green
} else {
    Write-Host "Push cancelled. Undoing commit..." -ForegroundColor Yellow
    
    # Undo the commit we just made
    git reset --soft HEAD~1
    
    # If we created a new tag, delete it
    if ([string]::IsNullOrWhiteSpace($tagExists)) {
        Write-Host "Removing tag v$version..." -ForegroundColor Yellow
        git tag -d "v$version"
        Write-Host "Tag v$version removed" -ForegroundColor Green
    }
    
    Write-Host "Commit has been undone. Changes are back in the staging area." -ForegroundColor Green
    Write-Host "Release process aborted" -ForegroundColor Yellow
} 