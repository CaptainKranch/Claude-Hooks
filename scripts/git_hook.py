#!/usr/bin/env python3
"""
Git Practice Enforcement Hook for Claude Code

This hook encourages better git practices by:
1. Suggesting git operations before file modifications
2. Checking if changes should be in a new branch
3. Reminding to check git log and status regularly
4. Blocking certain operations if git practices aren't followed
"""

import json
import sys
import subprocess
import os
from pathlib import Path


def run_git_command(command):
    """Run a git command and return the output."""
    try:
        result = subprocess.run(
            f"git {command}",
            shell=True,
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, "", str(e)


def is_git_repo():
    """Check if current directory is a git repository."""
    success, _, _ = run_git_command("rev-parse --git-dir")
    return success


def get_current_branch():
    """Get the current git branch."""
    success, output, _ = run_git_command("branch --show-current")
    return output if success else None


def has_uncommitted_changes():
    """Check if there are uncommitted changes."""
    success, output, _ = run_git_command("status --porcelain")
    return success and len(output.strip()) > 0


def get_recent_commits(count=5):
    """Get recent commit messages."""
    success, output, _ = run_git_command(f"log --oneline -n {count}")
    return output.split('\n') if success and output else []


def should_suggest_new_branch(tool_input):
    """Determine if changes warrant a new branch."""
    # Check if we're adding new files or making substantial changes
    if "file_path" in tool_input:
        file_path = tool_input["file_path"]
        
        # New files often warrant new branches
        if not os.path.exists(file_path):
            return True
            
        # Check if this looks like a new feature based on file content
        content = tool_input.get("content", "")
        feature_keywords = [
            "class ", "def ", "function ", "TODO", "FIXME", 
            "feature", "implement", "add", "new"
        ]
        
        if any(keyword in content.lower() for keyword in feature_keywords):
            return True
    
    return False


def generate_git_suggestions(tool_name, tool_input):
    """Generate git-related suggestions based on the tool being used."""
    suggestions = []
    
    if not is_git_repo():
        if tool_name in ["Write", "Edit", "MultiEdit"]:
            suggestions.append("Consider initializing a git repository with 'git init' to track your changes.")
        return suggestions
    
    current_branch = get_current_branch()
    has_changes = has_uncommitted_changes()
    
    # Suggestions for file modification tools
    if tool_name in ["Write", "Edit", "MultiEdit"]:
        # Check if we should suggest a new branch
        if should_suggest_new_branch(tool_input):
            if current_branch == "main" or current_branch == "master":
                suggestions.append(
                    f"Consider creating a new feature branch before implementing this change. "
                    f"Current branch: {current_branch}. "
                    f"Suggested: 'git checkout -b feature/your-feature-name'"
                )
        
        # Suggest checking git status before major changes
        if not has_changes:
            suggestions.append(
                "Good practice: Run 'git status' to see the current state before making changes."
            )
        
        # Suggest reviewing recent changes
        recent_commits = get_recent_commits(3)
        if recent_commits:
            suggestions.append(
                f"Recent commits: {'; '.join(recent_commits[:2])}. "
                f"Consider reviewing with 'git log --oneline' to understand recent changes."
            )
    
    # Suggestions for task-related operations
    elif tool_name == "Task":
        suggestions.append(
            "For any new feature or significant change, consider:\n"
            "1. Create a new branch: 'git checkout -b feature/descriptive-name'\n"
            "2. Make small, focused commits\n"
            "3. Check git log regularly: 'git log --oneline'\n"
            "4. Review changes before committing: 'git diff'"
        )
    
    # General git hygiene reminders
    if has_changes and len(suggestions) == 0:
        suggestions.append(
            f"You have uncommitted changes on branch '{current_branch}'. "
            f"Consider reviewing with 'git status' and 'git diff'."
        )
    
    return suggestions


def main():
    try:
        # Read input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    hook_event = input_data.get("hook_event_name", "")
    
    # Only process certain tools that involve code/file changes
    relevant_tools = ["Write", "Edit", "MultiEdit", "Task", "Bash"]
    
    if tool_name not in relevant_tools:
        sys.exit(0)  # Exit quietly for irrelevant tools
    
    # Generate git suggestions
    suggestions = generate_git_suggestions(tool_name, tool_input)
    
    if suggestions:
        if hook_event == "PreToolUse":
            # For PreToolUse, we provide guidance but don't block
            feedback = "\n🔧 Git Best Practices Reminder:\n"
            for i, suggestion in enumerate(suggestions, 1):
                feedback += f"{i}. {suggestion}\n"
            
            feedback += "\nContinuing with your requested operation..."
            
            # Return JSON with decision to continue but provide feedback
            response = {
                "decision": "approve",
                "reason": feedback,
                "suppressOutput": False
            }
            print(json.dumps(response))
            sys.exit(0)
        
        elif hook_event == "PostToolUse":
            # For PostToolUse, remind about git actions to take next
            feedback = "\n📝 Next Git Actions to Consider:\n"
            
            if is_git_repo():
                if has_uncommitted_changes():
                    feedback += "• Review changes: 'git diff'\n"
                    feedback += "• Stage changes: 'git add .'\n"
                    feedback += "• Commit changes: 'git commit -m \"descriptive message\"'\n"
                
                feedback += "• Check status: 'git status'\n"
                feedback += "• View recent history: 'git log --oneline'\n"
            
            # Don't block, just provide helpful reminders
            response = {
                "suppressOutput": False
            }
            print(json.dumps(response))
            print(feedback, file=sys.stderr)  # Show to user
            sys.exit(0)
    
    # If no suggestions, exit successfully
    sys.exit(0)


if __name__ == "__main__":
    main()
