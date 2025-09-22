# Define your GitHub username and the new repository name
$GITHUB_USERNAME = "killo431"
$REPO_NAME = "TEST222"

# 1. Check for Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Please install Git and try again." -ForegroundColor Red
    exit
}

# 2. Check for GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI ('gh') is not installed. Please install it and log in with 'gh auth login'." -ForegroundColor Red
    exit
}

# 3. Initialize a new Git repository in the current directory
Write-Host "Initializing a new Git repository..." -ForegroundColor Green
git init

# 4. Add all files to the staging area
Write-Host "Adding all files in the current directory..." -ForegroundColor Green
git add .

# 5. Commit the files with a message
Write-Host "Committing files with the initial commit message..." -ForegroundColor Green
git commit -m "Initial commit"

# 6. Create the new repository on GitHub using the GitHub CLI
Write-Host "Creating a new GitHub repository: $GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Green
gh repo create "$GITHUB_USERNAME/$REPO_NAME" --public --source=. --remote=origin

# Check if the 'gh' command was successful
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create GitHub repository. Please ensure you are authenticated with 'gh auth login' and the repository name is not taken." -ForegroundColor Red
    exit
}

# 7. Push the committed files to the new GitHub repository
Write-Host "Pushing files to the remote repository..." -ForegroundColor Green
git push -u origin main

Write-Host "All done! Your files have been uploaded to https://github.com/$GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Green