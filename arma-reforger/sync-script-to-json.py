#!/usr/bin/env python3
"""
Script to sync installation-script.sh into egg-pterodactyl-arma-reforger.json
This ensures the embedded script in the JSON stays in sync with the readable .sh file
"""

import json
import sys

def main():
    # Read the shell script
    try:
        with open('installation-script.sh', 'r', encoding='utf-8') as f:
            script_content = f.read()
    except FileNotFoundError:
        print("❌ Error: installation-script.sh not found!")
        sys.exit(1)
    
    # Convert to JSON-escaped format (newlines to \r\n)
    # First escape backslashes, then quotes, then convert newlines
    escaped_script = script_content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\r\\n')
    
    # Read the egg JSON
    try:
        with open('egg-pterodactyl-arma-reforger.json', 'r', encoding='utf-8') as f:
            egg_data = json.load(f)
    except FileNotFoundError:
        print("❌ Error: egg-pterodactyl-arma-reforger.json not found!")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in egg file: {e}")
        sys.exit(1)
    
    # Update the installation script
    egg_data['scripts']['installation']['script'] = escaped_script
    
    # Write back to JSON with proper formatting
    try:
        with open('egg-pterodactyl-arma-reforger.json', 'w', encoding='utf-8') as f:
            json.dump(egg_data, f, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"❌ Error writing JSON: {e}")
        sys.exit(1)
    
    print("✅ Script sincronizado com sucesso no egg JSON!")
    print(f"   📄 Tamanho do script: {len(script_content)} bytes")
    print(f"   📝 Linhas: {script_content.count(chr(10)) + 1}")
    print(f"   🔧 Arquivo: egg-pterodactyl-arma-reforger.json")

if __name__ == '__main__':
    main()
