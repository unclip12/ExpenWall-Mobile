# 🤖 Instructions for AI Assistants

## ⚠️ CRITICAL: READ THIS FIRST

If you are an AI assistant (Claude, ChatGPT, Copilot, etc.) helping with this project:

### MANDATORY STEPS FOR EVERY SESSION:

1. **📖 ALWAYS READ `PROGRESS.md` FIRST**
   - Before suggesting any changes
   - Before writing any code
   - Before answering any questions
   - This file contains the complete project context

2. **✏️ ALWAYS UPDATE `PROGRESS.md` AFTER CHANGES**
   - Add completed features to the "Completed" section
   - Update "Current Status" section
   - Add new planned features if discovered
   - Update "Known Issues" if any found
   - Update "Last Updated" timestamp
   - Move items from "Planned" to "Completed" when done

3. **🔍 CHECK EXISTING CODE BEFORE SUGGESTING**
   - Review the current architecture in PROGRESS.md
   - Check what's already implemented
   - Don't suggest re-implementing existing features
   - Build upon what exists

4. **📝 MAINTAIN CONTINUITY**
   - Reference previous decisions from PROGRESS.md
   - Keep consistent code style
   - Follow established patterns
   - Don't contradict previous architectural decisions

5. **🎯 FOLLOW THE ROADMAP**
   - Check "Planned Features" section
   - Prioritize based on High/Medium/Low priority
   - Implement features in logical order
   - Update roadmap as you go

---

## 🛠️ DEVELOPMENT GUIDELINES

### Code Style:
- Use Dart conventions
- Follow Flutter best practices
- Add comments for complex logic
- Keep functions small and focused
- Use meaningful variable names

### File Organization:
- Models in `lib/models/`
- Screens in `lib/screens/`
- Services in `lib/services/`
- Follow existing naming conventions

### Firebase:
- Never hardcode credentials
- Use GitHub Secrets for sensitive data
- Always test Firestore rules
- Handle errors gracefully

### UI/UX:
- Follow Material 3 guidelines
- Maintain glassmorphism style
- Keep animations smooth (60fps)
- Test on both light and dark themes

---

## ✅ QUALITY CHECKLIST

Before completing any task:

- [ ] Code compiles without errors
- [ ] No runtime exceptions
- [ ] Tested on Android emulator/device
- [ ] Works in both light and dark mode
- [ ] Firebase integration works
- [ ] Updated PROGRESS.md
- [ ] Updated README.md if needed
- [ ] Committed with meaningful message

---

## 🚫 DON'T:

- ❌ Skip reading PROGRESS.md
- ❌ Forget to update PROGRESS.md after changes
- ❌ Hardcode Firebase credentials
- ❌ Break existing functionality
- ❌ Ignore user's preferences in PROGRESS.md
- ❌ Suggest features already implemented
- ❌ Make breaking changes without discussion

---

## ✅ DO:

- ✅ Read PROGRESS.md at the start of every session
- ✅ Update PROGRESS.md after every significant change
- ✅ Follow established patterns
- ✅ Test your changes
- ✅ Keep security in mind
- ✅ Maintain code quality
- ✅ Document new features

---

## 📞 WHEN IN DOUBT:

1. Check PROGRESS.md
2. Review existing code
3. Ask the user for clarification
4. Don't make assumptions

---

**This file exists to ensure continuity across AI sessions.**  
**Following these guidelines will provide the best experience for the user.**

---

*Last Updated: February 2, 2026*
