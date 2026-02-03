# UI Fixes Required - February 3, 2026

## Issues Reported by User

### 1. ✅ Bottom Navigation Bar - FIXED
**Issue**: Only selected icon shows label below it  
**Expected**: All 5 icons should constantly show their labels below them, with only the selected one having different styling (bold/colored)  
**Status**: ✅ FIXED in commit 4dd8313

---

### 2. ⏳ Transaction Form Field Order - IN PROGRESS
**Issue**: Fields are in wrong order  
**Current Order**:
1. Merchant
2. Amount
3. Type (Spent/Received)
4. Category
5. Subcategory
6. Date
7. Items (button)
8. Notes

**Expected Order**:
1. **Items** (should be at top - first priority)
2. Merchant / Shop / Person
3. Payment Method (Cash/Card/UPI) - NEEDS TO BE ADDED
4. Type (Spent or Received)
5. Category
6. Date and Time (in one row - date left, time right)
7. Subcategory
8. Notes
9. Save Transaction button

**Status**: ⏳ NEEDS IMPLEMENTATION

---

### 3. ⏳ Category Duplicate Icon Issue - IN PROGRESS
**Issue**: Two icons showing - one from selected category and one in the prefix  
**Expected**: Only ONE icon should be shown  
**Status**: ⏳ NEEDS FIX

---

### 4. ⏳ Date & Time Picker - IN PROGRESS
**Issue**: Only date picker exists  
**Expected**: Date on left side in one box, Time on right side in another box (same row)  
**Status**: ⏳ NEEDS IMPLEMENTATION

---

### 5. ⏳ Receipt Scanning Low Confidence - IN PROGRESS
**Issue**: OCR shows 53% confidence even for clear receipts  
**Expected**: Improved confidence scoring for easily readable receipts  
**Current Algorithm**: Simple field averaging  
**Needed**: Smart confidence calculation based on:
- Text clarity
- Field completeness
- Pattern matching quality
- Amount validation

**Status**: ⏳ NEEDS IMPROVEMENT

---

### 6. ⏳ Items Autocomplete/Suggestions - IN PROGRESS
**Issue**: When typing in Items field (e.g., "C-H-I"), no suggestions appear  
**Expected**: Real-time suggestions showing "chicken" and related items as user types  
**Implementation Needed**:
- Use ItemRecognitionService.searchItems()
- Show dropdown with top 10 matches
- Display with fuzzy search
- Auto-suggest categories

**Status**: ⏳ NEEDS IMPLEMENTATION

---

## Implementation Plan

### Priority 1: Transaction Form Reordering
- [ ] Move Items field to top
- [ ] Add Payment Method field (Cash/Card/UPI/Wallet)
- [ ] Reorder all fields as specified
- [ ] Fix category duplicate icon
- [ ] Add time picker alongside date

### Priority 2: Items Autocomplete
- [ ] Add TextEditingController for item name field
- [ ] Implement real-time search using ItemRecognitionService
- [ ] Show suggestions dropdown
- [ ] Auto-select category on item selection

### Priority 3: OCR Confidence Improvement
- [ ] Implement smart confidence scoring
- [ ] Add field validation checks
- [ ] Weight important fields higher (total, merchant)
- [ ] Bonus for pattern matches
- [ ] Penalty for missing critical fields

---

## Files to Update

1. ✅ `lib/screens/home_screen.dart` - Bottom nav fixed
2. ⏳ `lib/screens/add_transaction_screen_v2.dart` - Form reordering, time picker, items autocomplete
3. ⏳ `lib/services/receipt_ocr_service.dart` - Improve confidence calculation
4. ⏳ `lib/models/transaction.dart` - Add payment method field (if needed)

---

## Timeline

**Target Completion**: February 3, 2026 (same day)
**Estimated Time**: 2-3 hours

---

*Created: February 3, 2026, 6:34 PM IST*
