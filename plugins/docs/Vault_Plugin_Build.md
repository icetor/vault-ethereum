# Vault Plugin Build  
  
This document provides instructions for building the Vault Ethereum plugin binary using a Docker-based build process. The provided build script will help you compile the plugin for your desired architecture (either **amd64** or **arm64**) and tag it with the specified version.  
  
---  
  
## How to Use the Build Script  
  
1. **Run the Script:**  
   - Execute the script by running:  
     ```bash  
     bash ./scripts/build_plugin.sh  
     ```  
     Replace `build_plugin.sh` with the actual name of your build script file.  
  
3. **Follow the Prompts:**  
   - **Plugin Name:** When prompted, enter the plugin name matching with it's folder name (e.g., `vault-ethereum`).
   - **Plugin Version:** Enter the desired version (e.g., `v1.0.8`).
   - **Target Architecture:** Enter `amd64` or `arm64` as the target architecture.  
  
4. **Script Execution:**  
   - The script will:  
     - Build the Docker image using the specified architecture.  
     - Create a temporary container to extract the binary and SHA256SUMS.  
     - Copy the built files to the `scripts/out` directory.
     - Clean up the temporary container and Docker image.  
  
5. **Verification:**  
   - Once complete, navigate to the `scripts/out` folder to verify that the plugin binary and SHA256SUMS file have been generated correctly with names formatted as:  
     - `vault-ethereum-<VERSION>-<ARCHITECTURE>`  
     - `SHA256SUMS-vault-ethereum-<VERSION>-<ARCHITECTURE>`  
