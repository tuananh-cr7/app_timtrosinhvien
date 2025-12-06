@echo off
echo Deploying Firestore indexes...
call firebase deploy --only firestore:indexes
pause

