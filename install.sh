#!/bin/bash
set -e

INSTALL_PATH="${1:-/usr/local/bin}"
REPO="codingarchitect-wq/xsops"
SCRIPT_NAME="xsops"

# Verify supported OS
case "$(uname | tr '[:upper:]' '[:lower:]')" in
  linux*|darwin*)
    ;;
  *)
    echo "Error: Unsupported OS: $(uname)"
    echo "xsops requires Linux or macOS with bash."
    exit 1
    ;;
esac

# Verify install path exists
if [[ ! -d "$INSTALL_PATH" ]]; then
  echo "Error: $INSTALL_PATH does not exist."
  exit 1
fi

# Check for download tool
download() {
  local url="$1"
  local dest="$2"
  if command -v curl &> /dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &> /dev/null; then
    wget -qO "$dest" "$url"
  else
    echo "Error: curl or wget required."
    exit 1
  fi
}

echo "Downloading xsops..."
DOWNLOAD_URL="https://raw.githubusercontent.com/${REPO}/main/${SCRIPT_NAME}"
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

download "$DOWNLOAD_URL" "$TEMP_FILE"

echo "Installing to ${INSTALL_PATH}/${SCRIPT_NAME}..."
if mv "$TEMP_FILE" "${INSTALL_PATH}/${SCRIPT_NAME}" && chmod 755 "${INSTALL_PATH}/${SCRIPT_NAME}"; then
  echo "Successfully installed xsops to ${INSTALL_PATH}/${SCRIPT_NAME}"
else
  echo "Failed to install. Try running with sudo:"
  echo "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sudo bash"
  exit 1
fi
