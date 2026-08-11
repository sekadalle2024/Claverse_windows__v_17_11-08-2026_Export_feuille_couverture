$ErrorActionPreference = "Continue"

$repoUrl = "https://github.com/sekadalle2024/Claverse_windows__v_17_11-08-2026_Export_feuille_couverture.git"
$branch = "main"

Write-Host "Configuring git for large repo..."
git config core.compression 0
git config http.postBuffer 1048576000
git config http.lowSpeedTime 999999
git config http.lowSpeedLimit 0

Write-Host "Setting remote URL..."
git remote set-url origin $repoUrl
git remote -v

Write-Host "Switching to branch $branch..."
git checkout -B $branch

function Safe-CommitAndPush {
    param([string]$message)
    $hasChanges = git status --porcelain
    if ($hasChanges) {
        git commit -m $message
        git push -u origin $branch
    } else {
        Write-Host "No changes to commit for $message"
    }
}

Write-Host "Part 1: src/"
git add src/
Safe-CommitAndPush "Backup - Part 1: src"

Write-Host "Part 2: py_backend/"
git add py_backend/
Safe-CommitAndPush "Backup - Part 2: py_backend"

Write-Host "Part 3: public/"
git add public/
Safe-CommitAndPush "Backup - Part 3: public"

Write-Host "Part 4: documentation"
git add *.md *.txt "Doc*"
Safe-CommitAndPush "Backup - Part 4: documentation"

Write-Host "Part 5: remaining files"
git add .
Safe-CommitAndPush "Backup - Part 5: remaining"

Write-Host "Backup process completed."
