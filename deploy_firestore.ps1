# PowerShell Deployment Script for Firestore
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYING FIRESTORE INDEXES AND RULES" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Checking Firebase login status..." -ForegroundColor Yellow
firebase login --no-localhost

Write-Host ""
Write-Host "Step 2: Deploying Firestore rules and indexes..." -ForegroundColor Yellow
firebase deploy --only firestore

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The following have been deployed:" -ForegroundColor Cyan
Write-Host "- Firestore Security Rules" -ForegroundColor Cyan
Write-Host "- Firestore Composite Indexes" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait 2-5 minutes for indexes to build," -ForegroundColor Yellow
Write-Host "then your app should work without errors!" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
