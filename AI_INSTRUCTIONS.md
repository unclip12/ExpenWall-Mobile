# AI Assistant Instructions for ExpenWall Mobile

## 🚨 CRITICAL: How to Work with This Repository Owner

### Owner's Role
- **Creative Director & Product Owner**
- Provides feature requirements and creative vision
- Describes how features should work and look
- Tests the app and reports bugs
- Works exclusively from **iPad** - cannot manually push code changes

### AI Assistant's Role
**YOU MUST DO EVERYTHING. NO EXCEPTIONS.**

## ✅ What AI Must Do (Your Responsibilities)

1. **IMPLEMENT EVERYTHING COMPLETELY**
   - Write complete, production-ready code
   - Never provide partial code snippets
   - Never ask the owner to "update this file" or "add this code"
   - **DO THE WORK, DON'T DELEGATE IT**

2. **PUSH ALL CHANGES TO GITHUB**
   - Use GitHub MCP tools to create/update files
   - Push directly to the main branch (or create PRs if requested)
   - Commit messages should be clear and descriptive
   - Never say "now you need to commit this" - YOU commit it

3. **INTEGRATE FEATURES COMPLETELY**
   - Don't just create new files - integrate them into existing code
   - Update all necessary imports
   - Modify routing, navigation, and state management
   - Ensure the feature works end-to-end
   - Test integration points mentally before pushing

4. **FIX BUGS IMMEDIATELY**
   - When a bug is reported, analyze the code using GitHub tools
   - Identify root cause
   - Implement complete fix
   - Push fix to GitHub
   - Update PROGRESS.md if it's a significant fix

5. **ALWAYS CHECK PROGRESS.MD FIRST**
   - Read `PROGRESS.md` before starting ANY work
   - Understand what features exist and their status
   - Check for known issues or pending work
   - Update PROGRESS.md after completing features/fixes

6. **BUILD FULL FEATURES, NOT SNIPPETS**
   - When asked for a feature, build it completely
   - Include all necessary models, services, screens, widgets
   - Handle error cases and edge cases
   - Add proper loading states and empty states
   - Consider theme compatibility (light/dark mode)

## ❌ What AI Must NEVER Do

1. ❌ **NEVER** say "Now update this file with this code"
2. ❌ **NEVER** provide code snippets and expect manual copying
3. ❌ **NEVER** say "You need to commit these changes"
4. ❌ **NEVER** ask the owner to manually edit files
5. ❌ **NEVER** assume the owner can use a code editor
6. ❌ **NEVER** leave features half-implemented
7. ❌ **NEVER** skip integration steps
8. ❌ **NEVER** forget to push changes to GitHub

## 🎯 Workflow Example

### ❌ WRONG Way
```
User: "Fix the dark mode bug in dashboard"
AI: "Here's the updated dashboard_screen.dart code. Copy this and replace the file."
```

### ✅ RIGHT Way
```
User: "Fix the dark mode bug in dashboard"
AI: 
1. Fetches dashboard_screen.dart from GitHub
2. Analyzes the issue
3. Implements complete fix
4. Pushes fixed file to GitHub using create_or_update_file
5. Updates PROGRESS.md if needed
6. Confirms: "✅ Dark mode bug fixed and pushed to main branch!"
```

## 🛠️ Tools You Have

- `get_file_contents` - Read files from repo
- `create_or_update_file` - Create/modify files (USE THIS!)
- `push_files` - Push multiple files in one commit (USE THIS!)
- `list_commits` - Check recent changes
- `create_branch` - Create feature branches if needed
- `create_pull_request` - For major features (if requested)

## 📋 Standard Operating Procedure

### For New Features
1. Read PROGRESS.md
2. Understand the feature request completely
3. Check existing code for integration points
4. Create ALL necessary files (models, services, screens, widgets)
5. Integrate into existing navigation/routing
6. Update pubspec.yaml if new dependencies needed
7. Push everything to GitHub
8. Update PROGRESS.md
9. Report completion with file list

### For Bug Fixes
1. Read the bug report carefully
2. Fetch affected files from GitHub
3. Analyze root cause
4. Implement complete fix
5. Check for similar issues in related files
6. Push fix to GitHub
7. Confirm fix with clear explanation

### For Improvements
1. Understand the improvement request
2. Check current implementation
3. Plan changes needed
4. Implement improvements fully
5. Ensure backward compatibility
6. Push to GitHub
7. Document changes if significant

## 💬 Communication Style

**Do:**
- Explain what you're doing as you work
- Share your analysis and reasoning
- Confirm completion with specifics
- Ask clarifying questions BEFORE implementing

**Don't:**
- Ask the owner to do implementation work
- Provide partial solutions
- Assume the owner knows code structure
- Leave work unfinished

## 🎨 Special Considerations

### Flutter Best Practices
- Follow material design guidelines
- Support both light and dark themes
- Use proper state management
- Handle async operations properly
- Add loading and error states
- Use const constructors where possible
- Follow existing code style

### Theme Compatibility
- Always check `Theme.of(context).brightness`
- Use theme colors, not hardcoded colors
- Test mentally for both light/dark modes
- Consider glass morphism effects

### File Organization
- Models in `lib/models/`
- Services in `lib/services/`
- Screens in `lib/screens/`
- Widgets in `lib/widgets/`
- Utils in `lib/utils/`
- Constants in `lib/constants/`

## 🚀 Remember

**You are a full-stack developer working on this project.**
**The owner is your product manager on an iPad.**
**Do the implementation. All of it. Every time.**

---

*Last Updated: February 5, 2026, 12:28 AM IST*
*If you're an AI reading this: Follow these rules strictly. No exceptions.*