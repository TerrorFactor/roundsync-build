#!/bin/bash
set -e

# Defaults (in case you run the script directly)
RCLONE_REPO=${RCLONE_REPO:-"https://github.com/rclone/rclone.git"}
RCLONE_BRANCH=${RCLONE_BRANCH:-"master"}
BUILD_NAME=${BUILD_NAME:-"custom-build"}

echo "=== 0. Preparing Workspace ==="
# Clean the container directory to prevent errors on subsequent runs
rm -rf /build_src/* /build_src/.[!.]* 2>/dev/null || true

echo "=== 1. Cloning Round-Sync repository ==="
git clone https://github.com/newhinton/Round-Sync.git .
# git checkout bda00f8d0162acb30a343982c54e3426d2824c15

echo "=== 2. Configuring build for: $BUILD_NAME ==="

if [ "$RCLONE_REPO" = "https://github.com/rclone/rclone.git" ]; then
    echo "--> Official Rclone Repo detected on branch/tag: $RCLONE_BRANCH"
    
    # Overwrite the checkout command to prevent the hardcoded "v" from breaking branch names
    cat << EOF >> rclone/build.gradle

// --- AUTOMATIC INJECTION FOR OFFICIAL REPO ---
tasks.named('checkoutRclone').configure {
    commandLine = ['go', 'get', '-v', 'github.com/rclone/rclone@${RCLONE_BRANCH}']
}
// -------------------------------------------
EOF

    sed -i "s/de.felixnuesse.extract.rCloneVersion=.*/de.felixnuesse.extract.rCloneVersion=${RCLONE_BRANCH}/g" gradle.properties

else
    echo "--> Custom Fork detected: $RCLONE_REPO ($RCLONE_BRANCH)"
    
    # 1. Fetch the exact commit hash
    LATEST_COMMIT=$(git ls-remote $RCLONE_REPO refs/heads/$RCLONE_BRANCH | awk '{print $1}')
    if [ -z "$LATEST_COMMIT" ]; then # Fallback in case it is a tag
        LATEST_COMMIT=$(git ls-remote $RCLONE_REPO refs/tags/$RCLONE_BRANCH | awk '{print $1}')
    fi
    echo "Found commit: $LATEST_COMMIT"

    # 2. Extract expected base version to satisfy go.mod checker
    RAW_VERSION=$(grep 'de.felixnuesse.extract.rCloneVersion' gradle.properties | cut -d'=' -f2 | tr -d '\r')
    if [[ $RAW_VERSION != v* ]]; then EXPECTED_VERSION="v$RAW_VERSION"; else EXPECTED_VERSION="$RAW_VERSION"; fi

    # 3. Strip "https://" and ".git" to format the Go Module properly
    GO_MODULE_URL=$(echo $RCLONE_REPO | sed -e 's|https://||' -e 's|.git$||')

    cat << EOF >> rclone/build.gradle

// --- AUTOMATIC INJECTION FOR CUSTOM FORK ---
tasks.named('checkoutRclone').configure {
    doFirst {
        exec {
            workingDir CACHE_PATH
            commandLine 'go', 'mod', 'edit', '-replace', 'github.com/rclone/rclone=${GO_MODULE_URL}@${LATEST_COMMIT}'
        }
    }
    commandLine = ['go', 'get', '-v', 'github.com/rclone/rclone@${EXPECTED_VERSION}']
}
// -------------------------------------------
EOF

    sed -i "s/de.felixnuesse.extract.rCloneVersion=.*/de.felixnuesse.extract.rCloneVersion=${BUILD_NAME}/g" gradle.properties
fi

echo "=== 3. Modifying Properties to prevent OOM ==="
echo "org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m" >> gradle.properties
echo "org.gradle.daemon=false" >> gradle.properties
echo "org.gradle.parallel=false" >> gradle.properties
echo "org.gradle.workers.max=2" >> gradle.properties

echo "=== 4. Cleaning and Building the APK ==="
./gradlew :rclone:clean --no-daemon
./gradlew assembleDebug --no-daemon

echo "=== 5. Extracting output to Host ==="
# Save into a subfolder named after the build so they don't overwrite each other!
OUTPUT_DIR="/host_mount/output/$BUILD_NAME"
mkdir -p "$OUTPUT_DIR"
find app/build/outputs/apk -type f -name "*.apk" -exec cp {} "$OUTPUT_DIR/" \;
chmod -R 777 /host_mount/output

echo "=== BUILD COMPLETE! ==="
echo "Your APKs are saved in: output/$BUILD_NAME/"
