# Round-Sync Custom Builder

A streamlined, Docker-based build environment for compiling [Round-Sync](https://github.com/newhinton/Round-Sync) (an Android GUI for Rclone). This tool allows you to easily inject custom or experimental `rclone` forks into the app without cluttering your host machine with Java, Go, or Android NDK dependencies.

## 📦 Prerequisites
* [Docker](https://www.docker.com/) and Docker Compose
* *Note: Works perfectly in WSL2.*

## 🚀 Usage

This project uses a `Makefile` to make compiling effortless. Simply run one of the following commands:

**Build a Custom Fork (e.g., Tofee's kDrive fork):**
`make tofee`

**Build the Official Stable Release:**
`make stable`

**Build the Bleeding-Edge Master Branch:**
`make latest`

### 📂 Output
Once the build says `BUILD SUCCESSFUL`, your compiled Android APKs will automatically appear in the `output/` folder on your host machine, sorted by build name.

### 🧹 Cleanup
To completely delete the container and wipe all cached SDK/NDK/Go dependencies from your hard drive, simply run:
`make clean`

## 🛠️ Testing Other Forks on the Fly
You don't need to edit any scripts to test a new fork. You can pass repository variables directly into `make`:

`make build RCLONE_REPO="https://github.com/YourName/rclone.git" RCLONE_BRANCH="experimental" BUILD_NAME="my-test-build"`
