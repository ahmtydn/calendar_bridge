#!/bin/bash

# Version management script for calendar_bridge
# This script helps with manual version management and changelog generation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current version from pubspec.yaml
get_current_version() {
    grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' '
}

# Get package name from pubspec.yaml
get_package_name() {
    grep '^name:' pubspec.yaml | sed 's/name: //' | tr -d ' '
}

# Check if version exists on pub.dev
check_version_exists() {
    local package_name=$1
    local version=$2
    local status_code
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$package_name/versions/$version")
    
    if [ "$status_code" = "200" ]; then
        return 0  # Version exists
    else
        return 1  # Version doesn't exist
    fi
}

# Get latest version from pub.dev
get_latest_version() {
    local package_name=$1
    curl -s "https://pub.dev/api/packages/$package_name" | jq -r '.latest.version // "0.0.0"'
}

# Increment version
increment_version() {
    local version=$1
    local increment_type=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}
    
    case $increment_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch"|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Update pubspec.yaml version
update_pubspec_version() {
    local new_version=$1
    sed -i.bak "s/^version: .*/version: $new_version/" pubspec.yaml
    rm pubspec.yaml.bak 2>/dev/null || true
}

# Generate changelog entry
generate_changelog_entry() {
    local version=$1
    local latest_version=$2
    local date
    date=$(date +"%Y-%m-%d")
    
    echo "## $version - $date"
    echo ""
    
    # Get commits since last version
    if git tag -l "v$latest_version" | grep -q "v$latest_version"; then
        print_info "Getting commits since v$latest_version"
        git log "v$latest_version"..HEAD --oneline --no-merges | while read -r line; do
            if [ -n "$line" ]; then
                local commit_hash
                local commit_msg
                commit_hash=$(echo "$line" | cut -d' ' -f1)
                commit_msg=$(echo "$line" | cut -d' ' -f2-)
                echo "- $commit_msg (\`$commit_hash\`)"
            fi
        done
    else
        print_warning "No tag found for v$latest_version, showing recent commits"
        git log --oneline --no-merges -n 10 | while read -r line; do
            if [ -n "$line" ]; then
                local commit_hash
                local commit_msg
                commit_hash=$(echo "$line" | cut -d' ' -f1)
                commit_msg=$(echo "$line" | cut -d' ' -f2-)
                echo "- $commit_msg (\`$commit_hash\`)"
            fi
        done
    fi
    
    echo ""
}

# Update CHANGELOG.md
update_changelog() {
    local new_entry="$1"
    
    if [ -f CHANGELOG.md ]; then
        # Create temporary file with new entry
        {
            head -n 1 CHANGELOG.md  # Keep the title
            echo ""
            echo "$new_entry"
            tail -n +2 CHANGELOG.md | tail -n +2  # Skip title and first empty line
        } > temp_changelog.md
        mv temp_changelog.md CHANGELOG.md
    else
        # Create new CHANGELOG.md
        {
            echo "# Changelog"
            echo ""
            echo "$new_entry"
        } > CHANGELOG.md
    fi
}

# Main function
main() {
    local command=${1:-"help"}
    local increment_type=${2:-"patch"}
    
    print_info "Calendar Bridge Version Manager"
    
    case $command in
        "check")
            local current_version
            local package_name
            current_version=$(get_current_version)
            package_name=$(get_package_name)
            
            print_info "Package: $package_name"
            print_info "Current version: $current_version"
            
            if check_version_exists "$package_name" "$current_version"; then
                print_warning "Version $current_version already exists on pub.dev"
                local latest_version
                latest_version=$(get_latest_version "$package_name")
                print_info "Latest published version: $latest_version"
            else
                print_success "Version $current_version is ready to publish"
            fi
            ;;
            
        "increment")
            local current_version
            local package_name
            local new_version
            current_version=$(get_current_version)
            package_name=$(get_package_name)
            
            print_info "Current version: $current_version"
            
            if ! check_version_exists "$package_name" "$current_version"; then
                print_error "Current version $current_version doesn't exist on pub.dev yet. Publish it first or use 'force-increment'."
                exit 1
            fi
            
            new_version=$(increment_version "$current_version" "$increment_type")
            print_info "New version: $new_version"
            
            # Update pubspec.yaml
            update_pubspec_version "$new_version"
            print_success "Updated pubspec.yaml version to $new_version"
            
            # Generate and update changelog
            local latest_version
            latest_version=$(get_latest_version "$package_name")
            local changelog_entry
            changelog_entry=$(generate_changelog_entry "$new_version" "$latest_version")
            update_changelog "$changelog_entry"
            print_success "Updated CHANGELOG.md"
            
            print_info "Don't forget to commit the changes:"
            print_info "git add pubspec.yaml CHANGELOG.md"
            print_info "git commit -m \"chore: bump version to $new_version\""
            print_info "git tag v$new_version"
            ;;
            
        "force-increment")
            local current_version
            local new_version
            current_version=$(get_current_version)
            
            new_version=$(increment_version "$current_version" "$increment_type")
            print_info "Force incrementing version from $current_version to $new_version"
            
            update_pubspec_version "$new_version"
            print_success "Updated pubspec.yaml version to $new_version"
            ;;
            
        "help"|*)
            echo "Usage: $0 <command> [increment_type]"
            echo ""
            echo "Commands:"
            echo "  check           - Check current version status"
            echo "  increment       - Increment version and update changelog"
            echo "  force-increment - Force increment version without checks"
            echo "  help            - Show this help message"
            echo ""
            echo "Increment types:"
            echo "  patch (default) - Increment patch version (x.x.1)"
            echo "  minor           - Increment minor version (x.1.0)"
            echo "  major           - Increment major version (1.0.0)"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 increment patch"
            echo "  $0 increment minor"
            echo "  $0 force-increment major"
            ;;
    esac
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install it first."
    exit 1
fi

if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install it first."
    exit 1
fi

# Run main function
main "$@"