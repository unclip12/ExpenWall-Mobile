# PDF Reports - Integration Helper

**Quick Reference for Integrating PDF Reports into ExpenWall Mobile**

---

## 📝 Already Complete (Phases 1-3)

✅ **Models:** ReportConfig  
✅ **Services:** PDFReportService  
✅ **Screens:** ReportBuilderScreen, ReportPreviewScreen, ReportHistoryScreen  
✅ **Dependencies:** pdf, printing packages

---

## 🔗 Phase 5: Navigation Integration

### Step 1: Add Menu Items

**Location:** Your main menu drawer or AppBar actions

#### Option A: Drawer Menu Item

```dart
import 'package:expenwall_mobile/screens/reports/report_builder_screen.dart';
import 'package:expenwall_mobile/screens/reports/report_history_screen.dart';

// Inside your Drawer widget:
ListTile(
  leading: Icon(Icons.description, color: Colors.purple),
  title: Text('Generate Report'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportBuilderScreen(),
      ),
    );
  },
),
ListTile(
  leading: Icon(Icons.history, color: Colors.purple),
  title: Text('Report History'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportHistoryScreen(),
      ),
    );
  },
),
```

#### Option B: AppBar Action Button

```dart
import 'package:expenwall_mobile/screens/reports/report_builder_screen.dart';

// Inside your AppBar actions:
IconButton(
  icon: Icon(Icons.picture_as_pdf),
  tooltip: 'Generate Report',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportBuilderScreen(),
      ),
    );
  },
),
```

#### Option C: Dashboard Quick Action Card

```dart
import 'package:expenwall_mobile/screens/reports/report_builder_screen.dart';

// Inside your Dashboard grid:
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportBuilderScreen(),
      ),
    );
  },
  child: Card(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.description, size: 48, color: Colors.purple),
        SizedBox(height: 8),
        Text('PDF Reports', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  ),
),
```

---

### Step 2: Named Routes (Optional)

**If using named routes, add to your MaterialApp:**

```dart
import 'package:expenwall_mobile/screens/reports/report_builder_screen.dart';
import 'package:expenwall_mobile/screens/reports/report_preview_screen.dart';
import 'package:expenwall_mobile/screens/reports/report_history_screen.dart';

MaterialApp(
  routes: {
    '/reports/builder': (context) => ReportBuilderScreen(),
    '/reports/history': (context) => ReportHistoryScreen(),
    // Note: ReportPreviewScreen is navigated to directly with arguments
  },
  // ... other config
)

// Then navigate using:
Navigator.pushNamed(context, '/reports/builder');
```

---

### Step 3: Tab Bar Integration (If applicable)

**If you want Reports as a tab in your Planning section:**

```dart
import 'package:expenwall_mobile/screens/reports/report_history_screen.dart';

TabBarView(
  children: [
    BuyingListScreen(),
    CravingsScreen(),
    RecurringBillsScreen(),
    SplitBillsScreen(),
    ReportHistoryScreen(), // Add as new tab
  ],
)

TabBar(
  tabs: [
    Tab(text: 'Buying List'),
    Tab(text: 'Cravings'),
    Tab(text: 'Bills'),
    Tab(text: 'Split'),
    Tab(text: 'Reports'), // Add tab
  ],
)
```

---

## 📦 Import Statements Needed

**Where you integrate the screens:**

```dart
// For Report Builder (main entry point)
import 'package:expenwall_mobile/screens/reports/report_builder_screen.dart';

// For Report History (view past reports)
import 'package:expenwall_mobile/screens/reports/report_history_screen.dart';

// Note: ReportPreviewScreen is navigated to internally by ReportBuilderScreen
// You typically won't import it directly
```

---

## 🧑‍💻 User ID Integration

**Current Status:** Services use placeholder user ID

**To Fix:** Update PDFReportService to use real user authentication

```dart
// In lib/services/pdf_report_service.dart
// Find this line (around line 50):
final String userId = 'user_123'; // TODO: Get from auth service

// Replace with:
final String userId = await AuthService().getCurrentUserId();
// Or however your auth service works
```

**If you don't have auth yet:**
- Reports work fine with placeholder ID
- All users share same reports
- Fix when you add authentication

---

## ✅ Testing Checklist

### Navigation Testing

- [ ] Menu item appears correctly
- [ ] Tapping menu item opens Report Builder
- [ ] Back button returns to previous screen
- [ ] Report History accessible from menu

### Report Generation Testing

- [ ] Simple Summary template works
- [ ] Detailed Professional template works
- [ ] Budget Analysis template works
- [ ] This Month preset works
- [ ] Last Month preset works
- [ ] Custom date range works
- [ ] Category filter works
- [ ] Generate button shows loading state
- [ ] PDF preview opens after generation

### Preview & Sharing Testing

- [ ] PDF displays correctly in preview
- [ ] Zoom works (pinch gesture)
- [ ] Share button opens system share sheet
- [ ] Can share to WhatsApp
- [ ] Can share to email
- [ ] Can save to Drive/Files
- [ ] Print button works (if printer available)
- [ ] Done button returns to builder

### History Testing

- [ ] Generated reports appear in history
- [ ] Sorted by date (newest first)
- [ ] File size displays correctly
- [ ] Tap report to view works
- [ ] Share from history works
- [ ] Delete from history works
- [ ] Empty state shows when no reports

---

## 🔧 Phase 4: Chart Integration (Remaining Work)

**Status:** Not yet implemented

### Tasks:

1. **Convert fl_chart to Images**
   - Use RepaintBoundary to capture chart widgets
   - Convert to PNG/JPEG bytes
   - Embed in PDF using PdfImage

2. **Add Category Pie Chart**
   - Show spending by category
   - Color-coded segments
   - Percentage labels

3. **Add Spending Trend Chart**
   - Line chart of spending over time
   - Daily/weekly/monthly aggregation
   - Visual trend analysis

4. **Add Budget Bar Charts**
   - Horizontal bars for budget vs actual
   - Color coding (green/yellow/red)
   - Percentage indicators

5. **Receipt Image Embedding**
   - Load receipt images from storage
   - Resize and compress for PDF
   - Add to transaction details

**Estimated Time:** 3-4 hours

---

## 🎨 Phase 5: Polish & Testing (Remaining Work)

### UI/UX Improvements

- [ ] Add loading progress indicator with percentage
- [ ] Better error messages with recovery suggestions
- [ ] Empty state illustrations
- [ ] Onboarding tutorial for first use
- [ ] Sample report preview before generation

### Performance Optimization

- [ ] Background PDF generation (compute isolate)
- [ ] Caching for faster regeneration
- [ ] Lazy loading for report history
- [ ] Compression for large reports

### Error Handling

- [ ] Handle no transactions gracefully
- [ ] Handle invalid date ranges
- [ ] Handle storage permission denied
- [ ] Handle low storage space
- [ ] Network error for future cloud features

### Testing

- [ ] Unit tests for PDFReportService
- [ ] Widget tests for screens
- [ ] Integration tests for full flow
- [ ] Performance tests for large datasets
- [ ] Real device testing (Android + iOS)

**Estimated Time:** 2-3 hours

---

## 🚨 Known Issues & Limitations

### Current Limitations

1. **No Charts Yet** - Phase 4 work pending
2. **No Receipt Images** - Phase 4 work pending
3. **Placeholder User ID** - Need auth integration
4. **No Background Generation** - Blocks UI during generation
5. **No Email Direct Send** - Use share sheet for now

### Workarounds

- Charts: Tables provide same data in text format
- Receipts: Open receipt from transaction details separately
- User ID: Works fine for single-user testing
- Background: Generation is fast (2-5s) so acceptable
- Email: Share sheet includes email apps

---

## 📝 Quick Start Commands

### Test in Development

```bash
# Ensure dependencies installed
flutter pub get

# Run on device/emulator
flutter run

# Navigate to Reports from menu
# Generate a test report
```

### Build for Testing

```bash
# Android APK
flutter build apk --release

# iOS (requires Mac)
flutter build ios --release
```

---

## 📚 Documentation

**User Guide:** [PDF_REPORTS_GUIDE.md](./PDF_REPORTS_GUIDE.md)  
**Progress Tracking:** [PROGRESS.md](./PROGRESS.md)  
**Repository:** [github.com/unclip12/ExpenWall-Mobile](https://github.com/unclip12/ExpenWall-Mobile)

---

## ❓ FAQ

**Q: Can I customize report templates?**  
A: Not yet - Phase 5 will add template customization

**Q: Why no charts in my report?**  
A: Chart integration is Phase 4 (coming next)

**Q: Reports not showing in history?**  
A: Check app has storage permissions granted

**Q: Can I schedule automatic reports?**  
A: Not yet - planned for v3.0.0

**Q: How to share report via WhatsApp?**  
A: Tap Share button → Select WhatsApp → Choose contact

**Q: Can I edit report after generation?**  
A: No - regenerate with different settings instead

**Q: Maximum date range?**  
A: No limit - can report on all transaction history

**Q: File size too large?**  
A: Toggle off receipts and charts (when implemented)

---

## 👥 Support

**Issues:** [GitHub Issues](https://github.com/unclip12/ExpenWall-Mobile/issues)  
**Questions:** Create a discussion on GitHub  
**Feedback:** Open an issue with enhancement tag

---

## ✅ Summary

**To Integrate Reports:**

1. Add menu item (3 lines of code)
2. Import screen (1 line)
3. Navigator.push on tap (5 lines)
4. Update user ID in service (1 line) - optional
5. Test and enjoy!

**Total Integration Time:** 10-15 minutes

**Remaining Work:**
- Phase 4: Charts (3-4 hours)
- Phase 5: Polish (2-3 hours)
- **Total:** ~6 hours to 100% complete

---

**Version:** 2.5.0 (Phases 1-3 Complete)  
**Updated:** February 3, 2026, 4:57 PM IST  
**Status:** Ready for Integration & Testing

---