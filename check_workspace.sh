#!/bin/bash

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No color (resets to default)


# Capture the command type (e.g., plan or apply) from the argument. 
command_type="$1"

# Get the current active workspace and store it in a variable for later statements. 
current_workspace=$(terraform workspace show)
marker_file=".applied_${current_workspace}"

# Set string value to empty for custom messages and/or outputs: 
custom_output=""
warning_message=""


# Define variables for custom output messages
  skip_validation="\n\n ~ \nWorkspace Status: N/A \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃ INFO: Skipping workspace validation due to command. ┃\n\n ┃    Used command type is: (${command_type}).                    ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"

  inactive_workspace="\n\n ~ \nWorkspace Status: ✅ - Ready to be configured.  \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃      INFO: Workspace has no active config. 📋       ┃\n\n ┃            Current Workspace: '${current_workspace}'             ┃\n\n ┃      Please proceed with: <terraform apply>         ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"

  apply_marker_created="\n\n ~ \nWorkspace Status: ✅ - Infrastructure configured successfully.  \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃      INFO: Created marker file for workspace. 🖋️     ┃\n\n ┃            Current Workspace: '${current_workspace}'             ┃\n\n ┃   To apply changes in active environments, type:    ┃\n\n ┃        < UPDATE_CONFIG=1 terraform apply >          ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"

  apply_update_warning="\n\n ~ \nWorkspace Status: ❌ - In configured state. \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃ ⚠️  WARNING: You are now in an active workspace!     ┃\n\n ┃            Current Workspace: '${current_workspace}'             ┃\n\n ┃ Carefully review changes for future updates.        ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"

  debug_plan_active="\n\n ~ \nWorkspace Status: ❌ - In configured state. \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃ ⚠️  WARNING: You are in an active workspace!         ┃\n\n ┃            Current Workspace: '${current_workspace}'             ┃\n\n ┃ Carefully review changes and proceed with apply.    ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"

  destroy_marker_removed="\n\n ~ \nWorkspace Status: ❌ - In configured state.  \n\n ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n\n ┃      INFO: Deleted marker file for workspace. 📃🗑️   ┃\n\n ┃            Current Workspace: '${current_workspace}'             ┃\n\n ┃      Please proceed with: <terraform destroy>       ┃\n\n ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \n\n"
# --- Variable definitions end ---


# Skip workspace validation if command is 'skip' or 'destroy'
if [ "$command_type" == "skip" ] || [ "$command_type" == "ignore" ]; then
  custom_output="$skip_validation"
  echo '{"valid_workspace": "true", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'
  exit 0
fi

# Check if a marker file exists for this workspace (indicating active configuration)
if [ -f "$marker_file" ]; then
  workspace_status="active"
else
  workspace_status="inactive"
fi

# For `apply`, create a marker file if the workspace is inactive
if [ "$command_type" == "apply" ] && [ "$workspace_status" == "inactive" ]; then
  touch "$marker_file" && chmod u+wx "$marker_file"
  # If all resources are complete and infrastructure is deployed, then 'manage marker-file' section in terraform will keep this state clean.
  custom_output="$apply_marker_created"
  echo '{"valid_workspace": "true", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'


# For `destroy`, remove the marker file if it exists
elif [ "$command_type" == "destroy" ] && [ "$workspace_status" == "active" ]; then
  rm -f "$marker_file"
  custom_output="$destroy_marker_removed"
  echo '{"valid_workspace": "true", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'
  exit 0

# For `apply`, prevent execution if the workspace is already active unless UPDATE_CONFIG is set
elif [ "$command_type" == "apply" ] && [ "$workspace_status" == "active" ] && [ -z "$UPDATE_CONFIG" ]; then
  echo -e "" >&2
  echo -e "" >&2
  echo -e "${RED}${BOLD}WARNING:${NC} The '${current_workspace}' workspace already has an active network configuration." >&2
  echo -e "Switching to a different workspace is recommended to avoid conflicts or unintended changes." >&2
  echo -e "" >&2
  echo -e "* To create a new workspace, run: '${GREEN}terraform workspace new <name>${NC}'" >&2
  echo -e "* List all available workspaces with: '${GREEN}terraform workspace list${NC}'" >&2 
  echo -e "" >&2
  echo -e "If you exited terraform execution or typed 'no' when prompted to confirm action, then ignore the warning above and follow instructions below:"
  echo -e "* ${GREEN}NOTE${NC}: To override warning and continue, please set <${GREEN}UPDATE_CONFIG=1 terraform apply${NC}>" >&2
  echo '{"valid_workspace": "false"}'
  exit 1

# For `apply` with UPDATE_CONFIG set, bypass the active check
elif [ "$command_type" == "apply" ] && [ "$workspace_status" == "active" ] && [ "$UPDATE_CONFIG" == "1" ]; then
  warning_message="$apply_update_warning"
  echo '{"valid_workspace": "true", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'
  exit 0

# For `plan`, print a debug message if the workspace is active, but allow it to proceed
elif [ "$command_type" == "plan" ] && [ "$workspace_status" == "active" ]; then
  warning_message="$debug_plan_active"
  echo '{"valid_workspace": "false", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'
  exit 0

# If none of the conditions matched, confirm the workspace is valid
elif [ "$command_type" == "plan" ] && [ "$workspace_status" == "inactive" ]; then
  custom_output="$inactive_workspace"
  echo '{"valid_workspace": "true", "custom_output": "'"$custom_output"'", "warning_message": "'"$warning_message"'"}'
  exit 0
fi