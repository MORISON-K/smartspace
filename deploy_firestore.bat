@echo off
echo ========================================
echo   DEPLOYING FIRESTORE INDEXES AND RULES
echo ========================================
echo.

echo Step 1: Logging into Firebase...
firebase login

echo.
echo Step 2: Deploying Firestore rules and indexes...
firebase deploy --only firestore

echo.
echo ========================================
echo   DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo The following have been deployed:
echo - Firestore Security Rules
echo - Firestore Composite Indexes
echo.
echo Wait 2-5 minutes for indexes to build,
echo then your app should work without errors!
echo.
pause
