#!/bin/bash

# JDI Installation Test Cycle
# This script helps you test the installation/uninstallation cycle

echo "🔄 JDI INSTALLATION TEST CYCLE"
echo "=============================="
echo ""
echo "This script will help you test the installation cycle:"
echo ""
echo "1. Check current installation status"
echo "2. Uninstall everything (if installed)"
echo "3. Verify clean state"
echo "4. Reinstall with JDI_INSTALLER_COMPLETE.sh"
echo "5. Verify installation"
echo ""

echo "Step 1: Checking current installation..."
./check_jdi_installation.sh

echo ""
echo "Do you want to proceed with uninstallation? (y/N): "
read proceed

if [[ $proceed =~ ^[Yy]$ ]]; then
    echo ""
    echo "Step 2: Running uninstaller..."
    ./JDI_UNINSTALLER.sh
    
    echo ""
    echo "Would you like to check clean state? (y/N): "
    read check_clean
    
    if [[ $check_clean =~ ^[Yy]$ ]]; then
        echo ""
        echo "Step 3: Verifying clean state..."
        ./check_jdi_installation.sh
        
        echo ""
        echo "Would you like to reinstall now? (y/N): "
        read reinstall
        
        if [[ $reinstall =~ ^[Yy]$ ]]; then
            echo ""
            echo "Step 4: Running installer..."
            ./JDI_INSTALLER_COMPLETE.sh
        else
            echo "You can run ./JDI_INSTALLER_COMPLETE.sh manually when ready"
        fi
    fi
else
    echo "Test cycle cancelled"
fi
