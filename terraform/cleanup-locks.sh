#!/bin/bash

# Terraform Lock Cleanup Script
# This script helps clean up Terraform state locks

set -e

echo "🔧 Terraform Lock Cleanup Utility"
echo "================================="

# Function to check if we're in a terraform directory
check_terraform_dir() {
    if [ ! -f "terraform.tf" ] && [ ! -f "main.tf" ] && [ ! -d ".terraform" ]; then
        echo "❌ Not in a Terraform directory. Please run from a directory with .tf files"
        exit 1
    fi
}

# Function to list current locks
list_locks() {
    echo "📋 Checking for active locks..."
    if terraform plan -lock=false >/dev/null 2>&1; then
        echo "✅ No active locks found"
    else
        echo "🔒 Active lock detected. Run 'terraform plan' to see lock details"
    fi
}

# Function to force unlock with confirmation
force_unlock_interactive() {
    echo "🔓 Interactive force unlock"
    echo "Enter the lock ID (or press Enter to skip):"
    read -r lock_id
    if [ -n "$lock_id" ]; then
        echo "Unlocking lock ID: $lock_id"
        terraform force-unlock "$lock_id"
        echo "✅ Lock unlocked successfully"
    else
        echo "⏭️  Skipped unlock"
    fi
}

# Function to check for stale locks
check_stale_locks() {
    echo "🔍 Checking for stale locks..."
    
    # Try to get lock info
    if ! terraform plan >/dev/null 2>&1; then
        echo "⚠️  Lock detected. Checking if it's stale..."
        
        # Extract lock ID from error output
        lock_output=$(terraform plan 2>&1 | grep -o 'ID: [a-f0-9-]*' | head -1)
        if [ -n "$lock_output" ]; then
            lock_id=$(echo "$lock_output" | cut -d' ' -f2)
            echo "🔒 Found lock ID: $lock_id"
            echo "⚠️  This lock might be stale if no other terraform process is running"
            echo "💡 To unlock: terraform force-unlock -force $lock_id"
        fi
    else
        echo "✅ No locks found"
    fi
}

# Function to clean all workspaces
clean_all_workspaces() {
    echo "🧹 Cleaning all workspaces..."
    
    # Get list of workspaces
    workspaces=$(terraform workspace list | grep -v '^[[:space:]]*\*' | sed 's/^[[:space:]]*//')
    
    if [ -z "$workspaces" ]; then
        echo "ℹ️  Only default workspace found"
        check_stale_locks
        return
    fi
    
    echo "Found workspaces: $workspaces"
    
    for workspace in $workspaces; do
        echo "🔄 Checking workspace: $workspace"
        terraform workspace select "$workspace"
        check_stale_locks
    done
    
    # Return to default
    terraform workspace select default
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1) Check for locks in current workspace"
    echo "2) Interactive force unlock"
    echo "3) Check all workspaces for locks"
    echo "4) Nuclear option: Force unlock all (use with caution)"
    echo "5) Show lock management commands"
    echo "6) Exit"
    echo ""
    read -p "Enter choice [1-6]: " choice
}

# Nuclear option - use with extreme caution
nuclear_unlock() {
    echo "⚠️  NUCLEAR OPTION: Force unlock all"
    echo "This will attempt to unlock any detected locks without confirmation"
    echo "Use this only if you're sure no other terraform processes are running"
    echo ""
    read -p "Are you sure? Type 'YES' to continue: " confirm
    
    if [ "$confirm" = "YES" ]; then
        # Try to get lock ID and force unlock
        if ! terraform plan >/dev/null 2>&1; then
            lock_output=$(terraform plan 2>&1 | grep -o 'ID: [a-f0-9-]*' | head -1)
            if [ -n "$lock_output" ]; then
                lock_id=$(echo "$lock_output" | cut -d' ' -f2)
                echo "🔓 Force unlocking: $lock_id"
                terraform force-unlock -force "$lock_id"
                echo "✅ Force unlock completed"
            fi
        else
            echo "✅ No locks to unlock"
        fi
    else
        echo "❌ Cancelled"
    fi
}

# Show helpful commands
show_commands() {
    echo ""
    echo "📚 Useful Terraform Lock Commands:"
    echo "=================================="
    echo ""
    echo "Check for locks:"
    echo "  terraform plan"
    echo ""
    echo "Force unlock specific lock:"
    echo "  terraform force-unlock -force <LOCK_ID>"
    echo ""
    echo "Check all workspaces:"
    echo "  terraform workspace list"
    echo "  terraform workspace select <workspace>"
    echo ""
    echo "Check lock status without acquiring:"
    echo "  terraform plan -lock=false"
    echo ""
    echo "View current state:"
    echo "  terraform state list"
    echo ""
    echo "Refresh state:"
    echo "  terraform refresh"
    echo ""
    echo "Emergency: Remove .terraform.lock.hcl (local only):"
    echo "  rm -f .terraform.lock.hcl"
    echo ""
}

# Main execution
main() {
    check_terraform_dir
    
    while true; do
        show_menu
        case $choice in
            1)
                list_locks
                ;;
            2)
                force_unlock_interactive
                ;;
            3)
                clean_all_workspaces
                ;;
            4)
                nuclear_unlock
                ;;
            5)
                show_commands
                ;;
            6)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please choose 1-6"
                ;;
        esac
    done
}

# Run main function
main "$@"
