#!/usr/bin/env bash
# Skill and agent activation prompt hook - checks if skills/agents should be activated based on user prompt

set -e

# Read input from stdin
input=$(cat)

# Parse JSON input (for hook input format)
prompt=$(echo "$input" | grep -oP '"prompt"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

if [[ -z "$prompt" ]]; then
    exit 0
fi

# Get project directory
project_dir="${CLAUDE_PROJECT_DIR}"
if [[ -z "$project_dir" ]]; then
    project_dir=$(echo "$input" | grep -oP '"cwd"\s*:\s*"\K[^"]+' 2>/dev/null || pwd)
fi

# Check if intent-classifier is available on PATH
if command -v intent-classifier &> /dev/null; then
    # Use semantic intent classifier
    intent-classifier \
        --prompt "$prompt" \
        --embed "$project_dir/.claude"
    exit 0
fi

# Fallback to keyword/regex matching
prompt=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# Arrays to hold matched items by priority
declare -a critical_skills=()
declare -a high_skills=()
declare -a medium_skills=()
declare -a low_skills=()

declare -a critical_agents=()
declare -a high_agents=()
declare -a medium_agents=()
declare -a low_agents=()

# Function to process metadata files (SKILL.md or agent .md files)
process_metadata_file() {
    local file="$1"
    local type="$2"  # "skill" or "agent"

    # Extract frontmatter (everything between first --- and second ---)
    frontmatter=$(awk '/^---$/{flag=!flag; next} flag' "$file")

    if [[ -z "$frontmatter" ]]; then
        return
    fi

    # Parse frontmatter fields
    item_name=$(echo "$frontmatter" | grep "^name:" | sed 's/^name:[[:space:]]*//' | tr -d '\r')
    priority=$(echo "$frontmatter" | grep "^priority:" | sed 's/^priority:[[:space:]]*//' | tr -d '\r')
    keywords=$(echo "$frontmatter" | grep "^keywords:" | sed 's/^keywords:[[:space:]]*//' | tr -d '\r')
    patterns=$(echo "$frontmatter" | grep "^patterns:" | sed 's/^patterns:[[:space:]]*//' | tr -d '\r')

    # Skip if no activation metadata
    if [[ -z "$priority" && -z "$keywords" && -z "$patterns" ]]; then
        return
    fi

    # Default priority
    priority="${priority:-medium}"

    # Check keyword triggers (comma-delimited)
    keyword_match=false
    if [[ -n "$keywords" ]]; then
        IFS=',' read -ra keyword_array <<< "$keywords"
        for keyword in "${keyword_array[@]}"; do
            keyword=$(echo "$keyword" | xargs)  # trim whitespace
            keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
            if [[ "$prompt" == *"$keyword_lower"* ]]; then
                keyword_match=true
                break
            fi
        done
    fi

    # Check intent pattern triggers (comma-delimited)
    intent_match=false
    if [[ -n "$patterns" ]]; then
        IFS=',' read -ra pattern_array <<< "$patterns"
        for pattern in "${pattern_array[@]}"; do
            pattern=$(echo "$pattern" | xargs)  # trim whitespace
            if echo "$prompt" | grep -qiE "$pattern"; then
                intent_match=true
                break
            fi
        done
    fi

    # Add to appropriate priority list if matched
    if [[ "$keyword_match" == true ]] || [[ "$intent_match" == true ]]; then
        if [[ "$type" == "skill" ]]; then
            case "$priority" in
                critical) critical_skills+=("$item_name") ;;
                high) high_skills+=("$item_name") ;;
                medium) medium_skills+=("$item_name") ;;
                low) low_skills+=("$item_name") ;;
            esac
        else
            case "$priority" in
                critical) critical_agents+=("$item_name") ;;
                high) high_agents+=("$item_name") ;;
                medium) medium_agents+=("$item_name") ;;
                low) low_agents+=("$item_name") ;;
            esac
        fi
    fi
}

# Process skill files
while IFS= read -r skill_file; do
    process_metadata_file "$skill_file" "skill"
done < <(find "$project_dir/.claude/skills" -name "SKILL.md" 2>/dev/null || true)

# Process agent files
while IFS= read -r agent_file; do
    process_metadata_file "$agent_file" "agent"
done < <(find "$project_dir/.claude/agents" -name "*.md" ! -name "README.md" 2>/dev/null || true)

# Generate output if matches found
total_skill_matches=$((${#critical_skills[@]} + ${#high_skills[@]} + ${#medium_skills[@]} + ${#low_skills[@]}))
total_agent_matches=$((${#critical_agents[@]} + ${#high_agents[@]} + ${#medium_agents[@]} + ${#low_agents[@]}))
total_matches=$((total_skill_matches + total_agent_matches))

if [[ $total_matches -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 SKILLS & AGENTS ACTIVATION CHECK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Skills section
    if [[ $total_skill_matches -gt 0 ]]; then
        if [[ ${#critical_skills[@]} -gt 0 ]]; then
            echo "⚠️  CRITICAL SKILLS (REQUIRED):"
            for skill in "${critical_skills[@]}"; do
                echo "  → $skill"
            done
            echo ""
        fi

        if [[ ${#high_skills[@]} -gt 0 ]]; then
            echo "📚 RECOMMENDED SKILLS:"
            for skill in "${high_skills[@]}"; do
                echo "  → $skill"
            done
            echo ""
        fi

        if [[ ${#medium_skills[@]} -gt 0 ]]; then
            echo "💡 SUGGESTED SKILLS:"
            for skill in "${medium_skills[@]}"; do
                echo "  → $skill"
            done
            echo ""
        fi

        if [[ ${#low_skills[@]} -gt 0 ]]; then
            echo "📌 OPTIONAL SKILLS:"
            for skill in "${low_skills[@]}"; do
                echo "  → $skill"
            done
            echo ""
        fi
    fi

    # Agents section
    if [[ $total_agent_matches -gt 0 ]]; then
        if [[ ${#critical_agents[@]} -gt 0 ]]; then
            echo "⚠️  CRITICAL AGENTS (REQUIRED):"
            for agent in "${critical_agents[@]}"; do
                echo "  → @$agent"
            done
            echo ""
        fi

        if [[ ${#high_agents[@]} -gt 0 ]]; then
            echo "📚 RECOMMENDED AGENTS:"
            for agent in "${high_agents[@]}"; do
                echo "  → @$agent"
            done
            echo ""
        fi

        if [[ ${#medium_agents[@]} -gt 0 ]]; then
            echo "💡 SUGGESTED AGENTS:"
            for agent in "${medium_agents[@]}"; do
                echo "  → @$agent"
            done
            echo ""
        fi

        if [[ ${#low_agents[@]} -gt 0 ]]; then
            echo "📌 OPTIONAL AGENTS:"
            for agent in "${low_agents[@]}"; do
                echo "  → @$agent"
            done
            echo ""
        fi
    fi

    # Generate action text
    actions=()
    [[ $total_skill_matches -gt 0 ]] && actions+=("Use Skill tool")

    # Build agent action text
    if [[ $total_agent_matches -gt 0 ]]; then
        all_agents=("${critical_agents[@]}" "${high_agents[@]}" "${medium_agents[@]}" "${low_agents[@]}")
        agent_list=$(IFS=', '; echo "${all_agents[*]/#/@}")
        actions+=("Use $agent_list")
    fi

    echo "ACTION: $(IFS=' and '; echo "${actions[*]}")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit 0
