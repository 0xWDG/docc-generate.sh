#/bin/zsh

# This script generates documentation for a Swift package using the Swift-DocC tool.
# It will add the Swift-DocC plugin to the Package.swift file, generate the documentation,
# and open the documentation in a web browser.

# License: MIT
# Author: Wesley de Groot <email+oss@wesleydegroot.nl>
# Website: https://wesleydegroot.nl
# Version: 1.0.0
# GitHub: https://github.com/0xWDG/docc-generate.sh

# if no package.swift file exists, exit
if [ ! -f "Package.swift" ]; then
  echo "No Package.swift file found"
  exit 1
fi

# Did we append the docc plugin to the Package.swift file?
didAppend = false

# Get the product name from the Package.swift file
PRODUCT_NAME=`cat Package.swift | grep -m1 "name" | awk -F'"' '{print $2}'`

# If no product name is found, exit
if [ -z "$PRODUCT_NAME" ]; then
  echo "No product name found in Package.swift"
  exit 1
fi

# Create a temporary directory
mkdir tmpDoccDir 2>/dev/null

# Add the docc plugin to the Package.swift file, if it doesn't already exist
if ! grep -q "https://github.com/apple/swift-docc-plugin" Package.swift; then
    echo "package.dependencies.append(" >> package.swift
    echo "  .package(url: \"https://github.com/apple/swift-docc-plugin\", from: \"1.0.0\")" >> package.swift
    echo ")" >> Package.swift
    didAppend=true
fi

# Generate the documentation
# We do not use the --hosting-base-path, since we are using a local server
swift package --allow-writing-to-directory tmpDoccDir \
    generate-documentation \
    --target "$PRODUCT_NAME" \
    --disable-indexing \
    --output-path tmpDoccDir \
    --transform-for-static-hosting
    # --hosting-base-path `basename ${{ github.repository }}`

# Get the exit code, for later use
doccExitCode=$?

# Undo the changes to the Package.swift file
if [ $didAppend = true ]; then
  git checkout -- Package.swift 2>/dev/null
  git checkout -- Package.resolved 2>/dev/null
fi

# If the documentation generation failed, exit
if [ $doccExitCode -ne 0 ]; then
  echo "Failed to generate documentation?"
  rm -rf tmpDoccDir
  exit 1
fi

# If a documentation file exists, open it
if [ -f "tmpDoccDir/documentation/$PRODUCT_NAME/index.html" ]; then
  echo "Opening documentation (http://localhost:8000/documentation/$PRODUCT_NAME/)"
  open "http://localhost:8000/documentation/$PRODUCT_NAME/"
elif [ -f "tmpDoccDir/documentation/documentation/index.html" ]; then
  echo "Opening documentation (http://localhost:8000/documentation/documentation/)"
  open "http://localhost:8000/documentation/documentation/"
else
  echo "Failed to generate documentation?"
  exit 1
fi

# Open the directory
open .

# Start a local server
python3 -m http.server 8000 --directory tmpDoccDir
