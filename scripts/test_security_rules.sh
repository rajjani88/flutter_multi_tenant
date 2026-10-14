#!/bin/bash
set -e

echo "=========================================================="
echo " Running Automated Firestore Security Rules Test Suite   "
echo " Simulating direct attack vectors and multi-tenant checks "
echo "=========================================================="

firebase emulators:exec --only firestore "npm --prefix security_tests test"
