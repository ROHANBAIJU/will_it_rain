# 📋 Remaining Screens Update Plan

## Summary
**Total Remaining Files:** 5 screens + 1 widget  
**Total Lines to Update:** ~3,385 lines  
**Status:** 3 screens completed (Dashboard, Plan Ahead, Settings) ✅

---

## 🎯 Priority Order & Details

### **1. ALERTS.DART** 
**Priority:** HIGH  
**File:** `lib/screens/alerts.dart`  
**Lines:** 744 lines  
**Complexity:** Medium-High

#### Current State Analysis:
- Uses old cosmic colors extensively
- Has gradient containers with emerald/teal gradients
- Multiple status indicators with green/red colors
- Threshold sliders for 6 metrics (rain, wind, temp, pollen, AQI, mold)
- Toggle switches with old color scheme
- Badge components with translucent backgrounds

#### What Needs Updating:
1. **Overview Container** (Lines ~47-147)
   - Remove emerald/teal gradient: `Color(0x3310B981)`, `Color(0x330DB4A6)`
   - Change border from `Color(0x4D10B981)` to light purple
   - Update to white background with soft shadow
   - Change status icon colors from green/red to purple theme
   - Update switch colors to purple

2. **Status Icons** (Line ~36-37)
   - Keep alert red `Color(0xFFDC2626)` (accessibility)
   - Change success from `Color(0xFF10B981)` to `Color(0xFF7C6BAD)`

3. **Title Blocks**
   - All white text → dark charcoal `Color(0xFF2D2D2D)`
   - All `Colors.white70` → gray `Color(0xFF6B6B6B)`

4. **Threshold Cards** (Lines ~148-260+)
   - Card backgrounds: white with shadow
   - Icon colors: currently cyan/emerald/yellow → all to purple `Color(0xFF7C6BAD)`
   - Slider active colors: purple
   - Value text: dark charcoal

5. **Active Conditions Section** (Lines ~264-330+)
   - Update badge colors to light purple background
   - Change text colors to purple/gray

6. **Helper Widgets** (_ThresholdCard, _InfoBadge, _ActiveCondCard)
   - Background colors: white or light purple
   - Border colors: light purple `Color(0xFFE8E4F3)`
   - Text colors: dark/gray

---

### **2. COMPARE.DART**
**Priority:** HIGH  
**File:** `lib/screens/compare.dart`  
**Lines:** 875 lines  
**Complexity:** High (most complex remaining)

#### Current State Analysis:
- Side-by-side location comparison
- Has dropdown menus with dark backgrounds
- Multiple gradient containers for location cards
- Data comparison tables
- Expandable forecast sections
- Multiple card types for different metrics

#### What Needs Updating:
1. **Main Panel** (_panel helper, Lines ~75-90)
   - Background: `Color(0x0DFFFFFF)` → white
   - Border: `Color(0x1AFFFFFF)` → `Color(0xFFE8E4F3)`
   - Add box shadow

2. **Dropdown Controls** (Lines ~75-120)
   - Background: `Colors.white.withOpacity(0.05)` → `Color(0xFFF5F3FF)`
   - Dropdown color: `Color(0xFF111827)` → white
   - Text: `Colors.white` → `Color(0xFF2D2D2D)`
   - Border: `Colors.white.withOpacity(0.20)` → `Color(0xFFE8E4F3)`

3. **Location Cards** (Lines ~200-350+)
   - Purple gradients: keep but adjust to match new purple (`#6B5BA6` to `#8B7AB8`)
   - Text colors: white → dark charcoal
   - Card backgrounds: maintain purple gradient or change to white
   - Icon colors: update to match theme

4. **Comparison Button** (Line ~117)
   - Background: `Color(0xFF7C3AED)` → `Color(0xFF7C6BAD)` (our purple)

5. **Metric Comparison Rows**
   - Table text: white → dark
   - Dividers: translucent white → light purple
   - Better/worse indicators: update colors

6. **Forecast Sections**
   - Expandable panels: white background
   - Text colors: dark/gray
   - Dividers: light purple

7. **Helper Widgets** (_CityCard, _MetricRow, _Legend, etc.)
   - All backgrounds to white/light purple
   - All text to dark/gray
   - All borders to light purple

---

### **3. BEST_DAYS.DART**
**Priority:** MEDIUM  
**File:** `lib/screens/best_days.dart`  
**Lines:** 526 lines  
**Complexity:** Medium

#### Current State Analysis:
- Calendar heatmap visualization
- Month/year navigation
- Score-based color coding for days
- Top 5 best days list
- Day detail cards with weather info

#### What Needs Updating:
1. **Header Controls** (Lines ~134-180)
   - Title text: white → dark charcoal
   - Navigation buttons: update styling
   - Badge colors: emerald → purple

2. **Calendar Grid** (Lines ~230-320)
   - Weekday header text: white → dark
   - Day cell backgrounds: keep score colors OR adjust to purple scale
   - Today indicator: update color
   - Score text colors: white → dark on lighter backgrounds

3. **Score Colors** (Lines ~66-73)
   - Currently uses traffic light: green/yellow/orange/red
   - DECISION NEEDED: Keep for clarity OR change to purple scale?
   - Recommend: KEEP traffic light for score clarity (accessibility)

4. **Top 5 Best Days Panel** (Lines ~185-228)
   - Panel background: translucent → white with shadow
   - Text colors: white → dark/gray
   - Score badges: adjust if needed

5. **Day Detail Modal/Card**
   - All backgrounds: white
   - Text: dark/gray
   - Icons: purple

6. **Legend** (Lines ~320-360)
   - Background: white/light purple
   - Text: dark/gray
   - Color squares: keep score colors

---

### **4. MAP.DART**
**Priority:** MEDIUM  
**File:** `lib/screens/map.dart`  
**Lines:** 686 lines  
**Complexity:** Medium-High

#### Current State Analysis:
- Interactive map interface
- Layer selection (temperature, precipitation, wind, pressure)
- Weather station markers
- Satellite toggle
- Legend and controls

#### What Needs Updating:
1. **Header Section** (Lines ~35-120)
   - Title text: `Colors.white` → `Color(0xFF2D2D2D)`
   - Badge component: emerald → purple
   - Satellite toggle switch: green → purple
   - "Add Location" button: purple-600 → our purple `#7C6BAD`

2. **Layer Selection Pills** (Lines ~140-200)
   - Active layer background: adjust to purple
   - Inactive: light purple background
   - Text colors: dark/gray
   - Keep layer icon colors OR change to purple (DECISION NEEDED)

3. **Map Container** (Lines ~210-280)
   - Border: translucent white → light purple
   - Background: adjust if needed
   - Grid lines: adjust opacity

4. **Station Markers/Cards** (Lines ~290-400)
   - Card backgrounds: white with shadow
   - Text colors: dark/gray
   - Active indicator: purple
   - Temperature text: dark with purple icon

5. **Legend Panel** (Lines ~450-550)
   - Background: white
   - Text: dark/gray
   - Color scales: adjust or keep scientific accuracy
   - Border: light purple

6. **Layer Info Cards**
   - Background: white/light purple
   - Text: dark/gray
   - Icons: purple

7. **Helper Widgets** (_Layer, _Station, _Badge, _LayerCard)
   - All colors updated to theme

---

### **5. TRANSPARENCY.DART**
**Priority:** LOW  
**File:** `lib/screens/transparency.dart`  
**Lines:** 531 lines  
**Complexity:** Low-Medium (mostly informational)

#### Current State Analysis:
- Data transparency page
- Similar structure to Settings data tab
- Metrics cards
- Data source cards
- Download format options
- Methodology explanation

#### What Needs Updating:
1. **Header Container** (Lines ~74-106)
   - Purple gradient: adjust to match theme (`#6B5BA6` to `#8B7AB8`)
   - Text: white → white (keep on gradient) OR change card to white with purple accent
   - Icon background: adjust opacity

2. **Metrics Cards** (Lines ~110-150)
   - Same as settings metrics
   - Background: light purple `Color(0xFFF5F3FF)`
   - Text: dark/gray
   - Values: bold dark
   - Change: purple

3. **Data Sources Section** (Lines ~160-340)
   - Panel background: white
   - Source cards: light purple background
   - Text: dark/gray
   - Badges: light purple with purple text
   - Status indicators: keep green OR change to purple
   - Icons: purple

4. **Download Formats** (Lines ~350-420)
   - Card backgrounds: white/light purple
   - Text: dark/gray
   - Download buttons: purple

5. **Methodology Section** (Lines ~425-490)
   - Text: dark/gray
   - Code blocks: light gray background
   - Links: purple

6. **Helper Widgets** (_Metric, _Source, _DownloadFmt, _Badge, _MetricCard, _SourceCard)
   - All updated to theme colors

---

### **6. WIDGETS/FOOTER.DART**
**Priority:** LOW  
**File:** `lib/widgets/footer.dart`  
**Lines:** 132 lines  
**Complexity:** Very Low

#### Current State Analysis:
- Simple footer bar component
- Copyright text
- Status badge
- Last updated timestamp
- Responsive layout

#### What Needs Updating:
1. **Text Colors** (Lines ~26-27, ~36-38, ~70-75)
   - `Colors.white70` → `Color(0xFF6B6B6B)`
   - `Colors.white54` → `Color(0xFF9B9B9B)`
   - `Colors.white38` → `Color(0xFFD1D1D1)` (separator)

2. **Badge Component** (Lines ~42-48, ~102-121)
   - Background: `Color(0x3310B981)` → `Color(0xFFE8E4F3)`
   - Foreground: `Color(0xFF6EE7B7)` → `Color(0xFF7C6BAD)`
   - Border: `Color(0x4D10B981)` → `Color(0xFFD1CBE8)`

3. **Overall**
   - Very simple, should take <5 minutes

---

## 🎨 Color Reference Quick Guide

### Old Colors → New Colors
```dart
// Backgrounds
Color(0x0DFFFFFF)     →  Colors.white  // or Color(0xFFF5F3FF) for tinted
Color(0x1AFFFFFF)     →  Color(0xFFE8E4F3)  // borders
Color(0x33...)        →  Color(0xFFE8E4F3)  // light purple bg

// Text
Colors.white          →  Color(0xFF2D2D2D)  // on white bg
Colors.white70        →  Color(0xFF6B6B6B)  // secondary text
Colors.white60        →  Color(0xFF9B9B9B)  // tertiary text

// Accents
Color(0xFF10B981)     →  Color(0xFF7C6BAD)  // emerald → purple
Color(0xFF06B6D4)     →  Color(0xFF7C6BAD)  // cyan → purple
Color(0xFFFACC15)     →  Keep OR Color(0xFF7C6BAD)  // yellow (case by case)
Color(0xFFA78BFA)     →  Color(0xFF7C6BAD)  // old purple → new purple

// Gradients
Purple gradients      →  Color(0xFF6B5BA6) to Color(0xFF8B7AB8)

// Status (consider keeping for accessibility)
Success green         →  Color(0xFF7C6BAD) OR keep Color(0xFF10B981)
Error red             →  KEEP Color(0xFFDC2626) (accessibility)
Warning yellow        →  KEEP OR adjust (case by case)
```

---

## ⏱️ Estimated Time per File

1. **alerts.dart** - 30-40 minutes (medium-high complexity)
2. **compare.dart** - 45-60 minutes (highest complexity, most lines)
3. **best_days.dart** - 25-35 minutes (calendar logic, color decisions)
4. **map.dart** - 30-40 minutes (many components, layer colors)
5. **transparency.dart** - 20-25 minutes (similar to settings)
6. **footer.dart** - 5 minutes (very simple)

**Total Estimated Time:** 2.5 - 3.5 hours

---

## 🚨 Key Decisions Needed

1. **Score Colors in best_days.dart:**
   - Keep traffic light (green/yellow/orange/red) for score clarity?
   - Or convert to purple gradient scale?
   - **Recommendation:** KEEP for accessibility/clarity

2. **Map Layer Colors:**
   - Keep scientific colors (yellow=temp, blue=precip, etc.)?
   - Or make all purple-themed?
   - **Recommendation:** KEEP scientific colors for data clarity

3. **Status Indicators:**
   - Keep green for success, red for errors?
   - Or make all purple-based?
   - **Recommendation:** KEEP red for errors (accessibility), purple for success

4. **Gradient Usage:**
   - Some purple gradients already exist - keep or replace?
   - **Recommendation:** Update to new purple gradient (`#6B5BA6` to `#8B7AB8`)

---

## 📝 Update Strategy

### For Each File:
1. Update all container backgrounds (translucent → white/light purple)
2. Update all text colors (white → dark charcoal/gray)
3. Update all borders (translucent white → light purple)
4. Update all accent colors (green/cyan/old purple → new purple)
5. Update all interactive elements (buttons, switches, sliders)
6. Update helper widgets at the end
7. Test for errors
8. Verify text visibility

### Testing Checklist per File:
- [ ] No compilation errors
- [ ] All text is readable (sufficient contrast)
- [ ] All interactive elements are visible
- [ ] Cards have proper depth (shadows work)
- [ ] Colors are consistent with theme
- [ ] Responsive layout still works

---

## 📊 Progress Tracking

- ✅ theme/aeronimbus_theme.dart
- ✅ main.dart
- ✅ app.dart
- ✅ screens/auth.dart
- ✅ screens/dashboard.dart (1,226 lines)
- ✅ screens/plan_ahead.dart (244 lines)
- ✅ screens/settings.dart (1,003 lines)
- ⏳ screens/alerts.dart (744 lines) - **NEXT**
- ⏳ screens/compare.dart (875 lines)
- ⏳ screens/best_days.dart (526 lines)
- ⏳ screens/map.dart (686 lines)
- ⏳ screens/transparency.dart (531 lines)
- ⏳ widgets/footer.dart (132 lines)

**Completed:** 3,053 lines  
**Remaining:** 3,494 lines  
**Total Project:** 6,547 lines

---

## 🎯 Recommended Order

1. **footer.dart** (5 min) - Quick win to warm up
2. **transparency.dart** (20-25 min) - Similar to completed settings
3. **alerts.dart** (30-40 min) - High priority, medium complexity
4. **best_days.dart** (25-35 min) - Calendar visualization
5. **map.dart** (30-40 min) - Interactive components
6. **compare.dart** (45-60 min) - Most complex, save for last

**Total Time:** ~2.5-3.5 hours for all remaining files
