.PHONY: tofee latest stable clean build

# --- DOCKER EXECUTION COMMAND ---
# We use `docker compose run --rm` instead of `up`. 
# This runs the container ephemerally, passing our variables, and deletes the container 
# (but keeps the cache volumes) when it finishes, keeping Docker entirely clutter-free.
DOCKER_CMD = docker compose run --rm \
	-e RCLONE_REPO=$(RCLONE_REPO) \
	-e RCLONE_BRANCH=$(RCLONE_BRANCH) \
	-e BUILD_NAME=$(BUILD_NAME) \
	apk-builder

# --- PRE-CONFIGURED BUILD TARGETS ---

tofee:
	@$(MAKE) build \
		RCLONE_REPO="https://github.com/Tofee/rclone.git" \
		RCLONE_BRANCH="tofee/kdrive" \
		BUILD_NAME="tofee-kdrive"

latest:
	@$(MAKE) build \
		RCLONE_REPO="https://github.com/rclone/rclone.git" \
		RCLONE_BRANCH="master" \
		BUILD_NAME="official-master"

stable:
	@$(MAKE) build \
		RCLONE_REPO="https://github.com/rclone/rclone.git" \
		RCLONE_BRANCH="v1.74-stable" \
		BUILD_NAME="v1.74-stable"

# --- CORE LOGIC ---

build:
	@echo "Starting build for $(BUILD_NAME)..."
	docker compose build
	$(DOCKER_CMD)

# Deletes all NDK/Go/Java cache volumes to free up disk space
clean:
	docker compose down -v
