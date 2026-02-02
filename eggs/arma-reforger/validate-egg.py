#!/usr/bin/env python3
"""
Egg Validation Script for Pterodactyl Arma Reforger
Validates structure, variables, placeholders, and consistency
"""

import json
import re
import sys

def validate_egg():
    errors = []
    warnings = []
    
    # Load egg JSON
    try:
        with open('egg-pterodactyl-arma-reforger.json', 'r', encoding='utf-8') as f:
            egg = json.load(f)
        print("JSON structure is valid")
    except json.JSONDecodeError as e:
        print(f"FATAL: Invalid JSON structure: {e}")
        return False
    except FileNotFoundError:
        print("FATAL: egg-pterodactyl-arma-reforger.json not found")
        return False
    
    # Validate meta version
    if egg.get('meta', {}).get('version') != 'PTDL_v2':
        errors.append("Meta version must be PTDL_v2")
    else:
        print("Meta version: PTDL_v2")
    
    # Validate required fields
    required_fields = ['name', 'author', 'description', 'startup', 'config', 'scripts', 'variables']
    for field in required_fields:
        if field not in egg:
            errors.append(f"Missing required field: {field}")
    
    if errors:
        print(f"Missing required fields: {', '.join(errors)}")
        return False
    else:
        print("All required fields present")
    
    # Validate variables
    variables = egg.get('variables', [])
    print(f"Total variables: {len(variables)}")
    
    required_var_fields = ['name', 'env_variable', 'default_value', 'user_viewable', 'user_editable', 'rules', 'field_type']
    env_vars = set()
    
    for i, var in enumerate(variables):
        for field in required_var_fields:
            if field not in var:
                errors.append(f"Variable #{i+1} ({var.get('name', 'UNKNOWN')}) missing field: {field}")
        
        env_var = var.get('env_variable')
        if env_var:
            if env_var in env_vars:
                errors.append(f"Duplicate env_variable: {env_var}")
            env_vars.add(env_var)
    
    if not errors:
        print(f"All {len(variables)} variables are properly structured")
    
    # Extract placeholders from installation script
    script = egg.get('scripts', {}).get('installation', {}).get('script', '')
    # Use word boundary to avoid false matches like S_ADDRESS from A2S_ADDRESS
    placeholders = set(re.findall(r'\b([A-Z][A-Z0-9_]+)_PLACEHOLDER', script))
    
    print(f"Placeholders in installation script: {len(placeholders)}")
    
    # Check for unused variables
    unused_vars = env_vars - placeholders
    if unused_vars:
        for var in sorted(unused_vars):
            # Some variables are used directly in startup or config, not as placeholders
            if var not in ['SRCDS_APPID', 'INSTALL_LOG', 'STEAM_USER', 'STEAM_PASS', 'STEAM_AUTH', 
                          'AUTO_UPDATE', 'VALIDATE_FILES', 'MAX_FPS', 'LOG_INTERVAL', 'RPL_TIMEOUT',
                          'NDS', 'NWK_RESOLUTION', 'STAGGERING_BUDGET', 'STREAMING_BUDGET', 
                          'STREAMS_DELTA', 'KEEP_NUM_LOGS', 'INSTALL_FLAGS']:
                warnings.append(f"Variable {var} defined but not used as placeholder in installation script")
    
    # Check for missing variables for placeholders
    missing_vars = placeholders - env_vars
    if missing_vars:
        for var in sorted(missing_vars):
            errors.append(f"Placeholder {var}_PLACEHOLDER used but variable {var} not defined")
    else:
        print("All placeholders have corresponding variables")
    
    # Validate config.files structure
    try:
        config_files = json.loads(egg.get('config', {}).get('files', '{}'))
        if 'config.json' in config_files:
            print("config.files defines config.json parser")
        else:
            warnings.append("config.files does not define config.json parser")
    except json.JSONDecodeError:
        errors.append("config.files contains invalid JSON")
    
    # Validate startup command
    startup = egg.get('startup', '')
    if 'armareforger-server.sh' in startup or 'startup.sh' in startup:
        print(f"✅ Startup command: {startup[:60]}{'...' if len(startup) > 60 else ''}")
    else:
        warnings.append(f"Unusual startup command: {startup}")
    
    # Check if installation script generates startup.sh or armareforger-server.sh
    if 'cat > /mnt/server/startup.sh' in script or 'cat > /mnt/server/armareforger-server.sh' in script:
        script_name = 'armareforger-server.sh' if 'armareforger-server.sh' in script else 'startup.sh'
        print(f"✅ Installation script generates {script_name}")
    else:
        errors.append("Installation script does not generate startup script")
    
    # Check for boolean conversion in startup.sh generation
    if "sed -i 's/\"true\"/true/g; s/\"false\"/false/g' config.json" in script:
        print("Boolean conversion pattern found in startup script")
    else:
        warnings.append("Boolean conversion pattern not found in generated startup.sh")
    
    # Validate Docker container
    container = egg.get('scripts', {}).get('installation', {}).get('container', '')
    if 'steamcmd' in container.lower():
        print(f"Installation container: {container}")
    else:
        warnings.append(f"Unusual installation container: {container}")
    
    # Print summary
    print("\n" + "="*60)
    print("VALIDATION SUMMARY")
    print("="*60)
    
    if errors:
        print(f"\nERRORS FOUND: {len(errors)}")
        for error in errors:
            print(f"   - {error}")
    else:
        print("\nNO ERRORS FOUND")
    
    if warnings:
        print(f"\nWARNINGS: {len(warnings)}")
        for warning in warnings:
            print(f"   - {warning}")
    else:
        print("\nNO WARNINGS")
    
    print("\n" + "="*60)
    
    return len(errors) == 0

if __name__ == '__main__':
    success = validate_egg()
    sys.exit(0 if success else 1)
