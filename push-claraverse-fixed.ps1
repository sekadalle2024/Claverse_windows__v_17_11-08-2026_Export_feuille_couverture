# ================================================================
# Script de Push ClaraVerse avec Gestion Taille > 140 MB
# Date: 27 Août 2026
# Repository: https://github.com/sekadalle2024/Claverse_windows__v_18_27-08-2026_Wide_sceren.git
# ================================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   SAUVEGARDE CLARAVERSE - COMMITS MULTIPLES" -ForegroundColor Cyan
Write-Host "   Repository: Claverse_windows__v_18_27-08-2026_Wide_sceren" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ================================================================
# Étape 1: Vérification de l'état Git
# ================================================================

Write-Host "Étape 1: Vérification de l'état Git..." -ForegroundColor Yellow

# Vérifier si on est dans un dépôt Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ ERREUR: Pas de dépôt Git trouvé" -ForegroundColor Red
    Write-Host "Exécutez: git init" -ForegroundColor Yellow
    exit 1
}

# Afficher l'état actuel
Write-Host "`nÉtat actuel du dépôt:" -ForegroundColor Cyan
git status

Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer..."

# ================================================================
# Étape 2: Configuration Git Optimale
# ================================================================

Write-Host "`nÉtape 2: Configuration Git pour gros fichiers..." -ForegroundColor Yellow

# Configuration optimale pour projets volumineux
git config core.compression 0
git config http.postBuffer 1048576000
git config http.lowSpeedTime 999999
git config http.lowSpeedLimit 0
git config pack.windowMemory "100m"
git config pack.packSizeLimit "100m"
git config pack.threads "1"

Write-Host "✅ Configuration Git appliquée" -ForegroundColor Green

# ================================================================
# Étape 3: Vérification du Remote
# ================================================================

Write-Host "`nÉtape 3: Vérification du repository distant..." -ForegroundColor Yellow

$repoUrl = "https://github.com/sekadalle2024/Claverse_windows__v_18_27-08-2026_Wide_sceren.git"

# Vérifier si le remote existe
$currentRemote = git remote get-url origin 2>$null

if ($currentRemote) {
    Write-Host "Remote actuel: $currentRemote" -ForegroundColor Cyan
    if ($currentRemote -ne $repoUrl) {
        Write-Host "⚠️  Le remote ne correspond pas au repository cible" -ForegroundColor Yellow
        $response = Read-Host "Voulez-vous le changer pour $repoUrl ? (O/N)"
        if ($response -eq "O" -or $response -eq "o") {
            git remote set-url origin $repoUrl
            Write-Host "✅ Remote mis à jour" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Aucun remote configuré. Configuration..." -ForegroundColor Yellow
    git remote add origin $repoUrl
    Write-Host "✅ Remote ajouté: $repoUrl" -ForegroundColor Green
}

# Vérifier la connexion
Write-Host "`nVérification de la connexion au repository..." -ForegroundColor Cyan
git ls-remote origin

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: Impossible de se connecter au repository" -ForegroundColor Red
    Write-Host "Vérifiez vos credentials GitHub" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Connexion au repository réussie" -ForegroundColor Green
Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer..."

# ================================================================
# Étape 4: Création des Commits Multiples
# ================================================================

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "   CRÉATION DES COMMITS MULTIPLES (6 PARTIES)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Fonction pour créer un commit et pusher avec retry
function Push-WithRetry {
    param(
        [string]$CommitMessage,
        [int]$MaxRetries = 3
    )
    
    Write-Host "`nCréation du commit: $CommitMessage" -ForegroundColor Yellow
    git commit -m $CommitMessage
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Aucun changement à commiter" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "✅ Commit créé" -ForegroundColor Green
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        Write-Host "`nTentative de push $i/$MaxRetries..." -ForegroundColor Cyan
        git push -u origin master
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push réussi!" -ForegroundColor Green
            return $true
        }
        
        if ($i -lt $MaxRetries) {
            Write-Host "⚠️  Échec. Nouvelle tentative dans 5 secondes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    Write-Host "❌ Push échoué après $MaxRetries tentatives" -ForegroundColor Red
    return $false
}

# ================================================================
# PARTIE 1: Code Source React/TypeScript (src/)
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 1/6: Code Source React/TypeScript (src/)" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add src/
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 1: Code Source React/TypeScript"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 1" -ForegroundColor Red
    exit 1
}

# ================================================================
# PARTIE 2: Backend Python (py_backend/)
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 2/6: Backend Python (py_backend/)" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add py_backend/
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 2: Backend Python"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 2" -ForegroundColor Red
    exit 1
}

# ================================================================
# PARTIE 3: Fichiers Publics (public/)
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 3/6: Fichiers Publics (public/)" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add public/
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 3: Fichiers Publics"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 3" -ForegroundColor Red
    exit 1
}

# ================================================================
# PARTIE 4: Documentation Principale
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 4/6: Documentation Principale" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add "Doc menu demarrer/" "Doc export rapport/" "Doc_Etat_Fin/" "Doc_Lead_Balance/" "Doc_Heatmap_Risque/" "Doc papier de travail javascript/" "Doc cross ref documentaire menu/"
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 4: Documentation Principale"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 4" -ForegroundColor Red
    exit 1
}

# ================================================================
# PARTIE 5: Autres Documentations et Fichiers Markdown
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 5/6: Autres Documentations et Fichiers Markdown" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add "Doc_Github_Issue/" "Doc backend switch/" "Doc backend github/" "Doc zeabur docker/" "Doc menu contextuel menu.js update/" "*.md" "*.txt" --force
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 5: Documentation et Fichiers Markdown"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 5" -ForegroundColor Red
    exit 1
}

# ================================================================
# PARTIE 6: Fichiers Restants et Configuration
# ================================================================

Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PARTIE 6/6: Fichiers Restants et Configuration" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan

git add .
$result = Push-WithRetry -CommitMessage "V18 Wide Screen - Partie 6: Configuration et Fichiers Restants"

if (-not $result -and $LASTEXITCODE -ne 0) {
    Write-Host "❌ Arrêt: échec du push partie 6" -ForegroundColor Red
    exit 1
}

# ================================================================
# VÉRIFICATION FINALE
# ================================================================

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host "   ✅ SAUVEGARDE TERMINÉE AVEC SUCCÈS!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

Write-Host "`nVérification finale..." -ForegroundColor Cyan
git status

Write-Host "`n📍 Repository GitHub:" -ForegroundColor Cyan
Write-Host "   $repoUrl" -ForegroundColor Yellow

Write-Host "`n[OK] Tous vos fichiers sont maintenant sauvegardes sur GitHub!" -ForegroundColor Green
Write-Host ""
