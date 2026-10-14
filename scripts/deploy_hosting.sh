#!/bin/bash
set -e

echo "=========================================================="
echo " Building & Deploying Nexus SaaS to Firebase Hosting      "
echo "=========================================================="

echo "Step 1: Compiling Flutter web release bundle..."
flutter build web --release

echo "Step 2: Deploying to Firebase Hosting & Firestore Security Rules..."
firebase deploy --only hosting,firestore

echo "=========================================================="
echo " Deployment Complete!                                    "
echo " Live URL: https://test-multitenant-6397f.web.app         "
echo "=========================================================="
