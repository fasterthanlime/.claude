---
name: pikchr
description: Work with Pikchr diagram syntax in markdown files. Use this skill when editing or creating Pikchr diagrams (```pikchr blocks), fixing Pikchr syntax errors, or when users ask to create technical diagrams in documentation.
---

# Pikchr Diagram Syntax

Comprehensive guide to pikchr, a PIC-like diagram language that renders to SVG. Use for technical diagrams in documentation.

## Overview

Pikchr is a domain-specific language for creating technical diagrams that compile to SVG. It's particularly useful for:
- System architecture diagrams
- Protocol flows and state machines
- Memory layouts and data structures
- Network diagrams
- Flowcharts and decision trees

## Quick Start

Basic pikchr diagram structure:

```pikchr
# Set defaults (optional)
boxwid = 2cm
boxht = 1cm

# Create objects
A: box "First"
B: box "Second" at 2cm right of A

# Connect them
arrow from A to B "label" above
```

## Common Syntax Errors to Avoid

### 1. Invalid Text Positioning Keywords

**Wrong:**
```pikchr
text "Label" at Box.w ljust
```

**Correct:**
```pikchr
text "Label" at Box.w + (0.2cm, 0cm)
# or use separate lines:
text "Label" at Box.w
```

**Note:** Keywords like `ljust`, `rjust`, `above`, `below` work with the `text` command itself, but not after `at` positioning with offsets. Use them separately or use offset positioning.

### 2. Line Continuation

**Wrong:**
```pikchr
box "Long"
  width 5cm
  height 2cm
```

**Correct:**
```pikchr
box "Long" \
  width 5cm \
  height 2cm
```

### 3. Direction Persistence

Direction changes persist! Always reset explicitly:

```pikchr
right
box "A"
box "B"  # Still going right

down
box "C"  # Below B

# Direction is STILL down here!
box "D"  # Below C

right  # Must explicitly change
box "E"  # Right of D
```

## Object Types Reference

### Block Objects

All block objects support: width, height, radius, fill, color, thickness, text

```pikchr
box "Box"
circle "Circle"
ellipse "Ellipse"
oval "Oval"
cylinder "Cylinder"
file "File"
diamond "Diamond"
```

**Visual appearance:**
- `box` - Rectangle with optional rounded corners (via `radius`)
- `circle` - Perfect circle (use `radius` or `diameter`)
- `ellipse` - Tall oval
- `oval` - Wide oval
- `cylinder` - 3D cylinder shape
- `file` - Document/file icon with folded corner
- `diamond` - Diamond/rhombus shape

### Line Objects

```pikchr
line "Line"
arrow "Arrow"
spline "Curved"
```

**Characteristics:**
- `line` - Straight line, no arrowheads
- `arrow` - Line with arrowhead at end (use `<->` for both ends)
- `spline` - Smooth curved line through points

**Arrow variants:**
```pikchr
arrow right 2cm "→"
arrow <- left 2cm "←"
arrow <-> right 2cm "↔"
```

### Special Objects

```pikchr
dot "Dot" - Small filled circle for markers
arc "Arc" - Circular arc segment
text "Text" - Text without box
move right 1cm - Invisible movement (changes position without drawing)
```

## Positioning and Layout

### Automatic Layout (Stacking)

Objects stack in the current direction. Default is `right`:

```pikchr
# Default: horizontal stacking
box "A"
circle "B"
cylinder "C"
# Result: A B C arranged left-to-right
```

**Change direction:**

```pikchr
right  # Stack horizontally (default)
box "1"; box "2"; box "3"  # → → →

down   # Stack vertically downward
box "4"; box "5"; box "6"  # ↓ ↓ ↓

left   # Stack horizontally leftward
box "7"; box "8"; box "9"  # ← ← ←

up     # Stack vertically upward
box "A"; box "B"; box "C"  # ↑ ↑ ↑
```

### Explicit Positioning with `at`

Position objects relative to other objects or absolute coordinates:

```pikchr
A: box "A"

# Relative positioning
circle "B" at 2cm right of A
oval "C" at 1cm below A
diamond "D" at A.se + (0.5cm, -0.5cm)

# Absolute from anchor points
box "E" at A.e + (1cm, 0)
box "F" at A.s + (0, -1cm)
```

**Expression syntax:**
- `2cm right of A` - 2cm to the right of A's center
- `1cm below A` - 1cm below A's center
- `A.se + (0.5cm, -0.5cm)` - Southeast corner plus offset
- Numbers can be: `1cm`, `0.5in`, `2mm`, `10px`, etc.

### Anchor Points

Every object has 9 anchor points:

```pikchr
boxwid = 2cm
boxht = 1.5cm

B: box "Object"

# Show all anchors
dot at B.n "n" above
dot at B.ne "ne" above
dot at B.e "e"
dot at B.se "se" below
dot at B.s "s" below
dot at B.sw "sw" below
dot at B.w "w"
dot at B.nw "nw" above
dot at B.c "c"
```

**Anchor reference:**
- `.n` (north), `.s` (south), `.e` (east), `.w` (west)
- `.ne`, `.se`, `.sw`, `.nw` (corners)
- `.c` (center)

**Layout-aware anchors:**
- `.start` - Leftmost point when direction is `right`, topmost when `down`, etc.
- `.end` - Opposite of `.start`

### Line Paths

Multi-segment paths use directional commands:

```pikchr
A: box "Start"
B: box "End" at 4cm right of A.e + (0, -2cm)

# Complex path
arrow from A.s \
  down 1cm \
  then right 2cm \
  then down 0.5cm \
  then right until even with B \
  then to B.w

# Path with waypoints
C: box "C" at 2cm below A
arrow from A.s to C.n then to C.e then to B.w
```

**Path keywords:**
- `go` - Move in direction
- `then` - Continue path from current point
- `heading` - Set angle (e.g., `heading 45deg`)
- `until even with` - Continue until aligned with object
- `to` - Line to specific point

## Size and Dimensions

### Explicit Sizing

```pikchr
box "Small" width 1cm height 0.5cm

box "Wide" width 4cm height 0.8cm

box "Tall" width 1cm height 3cm

circle "Circle" radius 1cm
# or: circle "Circle" diameter 2cm

ellipse "Ellipse" width 3cm height 1.5cm
```

### Auto-Fit to Text

```pikchr
# Automatic sizing based on text
box "This text determines size" fit

# Mix of fixed and auto
box "Fixed width" width 5cm fit  # Width fixed, height fits text
box "Fixed height" height 2cm fit  # Height fixed, width fits text
```

### Default Sizes via Variables

```pikchr
# Set defaults for all subsequent objects
boxwid = 2cm
boxht = 1cm
circlerad = 0.8cm

box "Uses default 2cm × 1cm"
box "Also 2cm × 1cm"
circle "0.8cm radius"

# Override for specific object
box "Wider" width 3cm  # Height still 1cm
```

### Scaling

```pikchr
scale = 0.8  # Scale entire diagram to 80%

# Or scale specific dimension
box "Normal"
box "Wider" width 150%  # 150% of boxwid
circle "Bigger" radius 200%  # 200% of circlerad
```

## Styling Attributes

### Colors

```pikchr
# Named colors
box "Red" fill red
box "Blue" color blue fill lightblue
box "Green" fill green color darkgreen

# Hex colors
box "Custom" fill #FF6B6B color #C92A2A

# Common color names
box "Aqua" fill aqua
box "Coral" fill coral
box "Gold" fill gold
box "Lavender" fill lavender
box "Lime" fill lime
box "Navy" fill navy color white  # White text on navy
box "Orange" fill orange
box "Pink" fill pink
box "Silver" fill silver
box "Teal" fill teal color white
box "Violet" fill violet
box "Yellow" fill yellow
```

### Line Thickness

```pikchr
box "Thin" thin
box "Normal"
box "Thick" thick
box "Custom" thickness 3px

# For lines/arrows
arrow thin right 2cm
arrow right 2cm
arrow thick right 2cm
arrow thickness 4px right 2cm
```

### Corner Radius

```pikchr
box "Sharp corners"
box "Rounded" radius 5px
box "Very round" radius 15px
box "Circle-ish" radius 50%
```

### Combined Styling

```pikchr
box "Styled" \
  width 3cm \
  height 1.5cm \
  radius 8px \
  fill lightblue \
  color navy \
  thick
```

## Text and Labels

### Multi-Line Text in Objects

Objects accept multiple text lines as separate string arguments:

```pikchr
box "Line 1" "Line 2" "Line 3"

cylinder "Header" "Body line 1" "Body line 2"

diamond "Decision" "Point"
```

### Text Positioning

```pikchr
A: box "Anchor"

# Text with positioning keywords
text "Above" at A.n above
text "Below" at A.s below

# Offset positioning without keywords
text "NE corner" at A.ne + (0.2cm, 0.2cm)
text "SW corner" at A.sw + (-0.2cm, -0.2cm)
```

**Positioning keywords (use without offsets):**
- `above` - Place text above the point
- `below` - Place text below the point
- `ljust` - Left-justify (text extends right from point)
- `rjust` - Right-justify (text extends left from point)
- `center` - Center text on point (default)

### Text on Lines

```pikchr
A: box "A"
B: box "B" at 3cm right of A

arrow from A to B "Label on arrow" above
arrow from A.s to B.s "Below arrow" below
```

### Text Styling

```pikchr
box "Bold" bold
box "Italic" italic
box "Bold Italic" bold italic

box "Monospace" mono
box "Code" monospace  # Same as mono

box "Big" big
box "Small" small
box "Very Big" big big  # Can stack
box "Very Small" small small

# Combinations
box "Big Bold" big bold
box "Small Italic" small italic
box "Mono Small" mono small
```

## Object References and Labels

### Symbolic Labels

Assign names to objects for reliable references:

```pikchr
Start: box "Start"
Process: cylinder "Process" at 2cm right of Start
Decision: diamond "Check" at 2cm right of Process
End: box "End" at 2cm right of Decision

arrow from Start to Process
arrow from Process to Decision
arrow from Decision to End "yes" above
arrow from Decision.s down 1cm then left until even with Start \
  then to Start.s "no"
```

**Naming conventions:**
- Use descriptive names: `StartButton`, `DataFlow`, `ErrorPath`
- CamelCase or snake_case both work
- Names are case-sensitive

### Ordinal References

Reference objects by their order within a class:

```pikchr
box "1st Box"
circle "1st Circle"
box "2nd Box"
circle "2nd Circle"
box "3rd Box"

# Reference by class and number
arrow from 1st box to 2nd box
arrow from 1st circle to 2nd circle
arrow from 2nd box to 3rd box

# Special ordinals
arrow from first box.n up 0.5cm
arrow from last box.s down 0.5cm
arrow from previous.e right 0.5cm  # previous = last object created
```

### The `previous` Keyword

Refers to the most recently created object:

```pikchr
box "A"
arrow from previous.e right 1cm  # from A.e

box "B"
arrow from previous.e right 1cm  # from B.e

circle "C"
arrow from previous.s down 1cm   # from C.s
```

## Containers and Grouping

Containers group objects into a single composite object:

```pikchr
Group: [
  box "First"
  arrow right 1cm
  circle "Second"
  arrow right 1cm
  cylinder "Third"
]

# Now Group acts as a single object with anchors
box "Outside" at Group.s + (0, -1cm)
arrow from Group.s to previous.n
```

**Container properties:**
- Has all 9 anchor points (`.n`, `.s`, `.e`, `.w`, etc.)
- `.width` and `.height` span the entire group
- Changes inside container don't affect outside layout
- Can nest containers

**Direction changes in containers:**

```pikchr
A: [
  right  # Set direction for container
  box "1"
  box "2"
  box "3"
]

# Direction persists after container!
# Must reset if needed:
down
box "Below" at A.s + (0, -1cm)
```

## Units and Measurements

### Supported Units

```pikchr
box width 2cm "Centimeters"
box width 20mm "Millimeters"
box width 0.5in "Inches"
box width 36pt "Points"
box width 3pc "Picas"
box width 100px "Pixels"
```

**Unit reference:**
- `cm` - Centimeters
- `mm` - Millimeters
- `in` - Inches (default if no unit specified)
- `pt` - Points (1/72 inch)
- `pc` - Picas (12 points)
- `px` - Pixels

### Arithmetic Expressions

```pikchr
A: box "A" width 2cm

# Addition/subtraction
box "Wider" width A.width + 1cm
box "Narrower" width A.width - 0.5cm

# Multiplication/division
box "Double" width A.width * 2
box "Half" width A.width / 2

# Percentages
box "125%" width 125%  # 125% of default boxwid
box "75%" width 75%

# Complex expressions
box "Complex" width (A.width + 1cm) * 1.5
```

## Common Patterns

### Sequence of Steps

```pikchr
right
boxwid = 1.5cm

Step1: box "Step 1"
arrow right 0.8cm from previous.e
Step2: box "Step 2"
arrow right 0.8cm from previous.e
Step3: box "Step 3"
arrow right 0.8cm from previous.e
Step4: box "Step 4"
```

### Conditional Flow

```pikchr
Start: box "Start"
Check: diamond "Condition" at 2cm below Start
Yes: box "Yes Path" at 2cm right of Check + (0, -1cm)
No: box "No Path" at 2cm left of Check + (0, -1cm)
End: box "End" at 2cm below Check + (0, -1cm)

arrow from Start to Check
arrow from Check.e to Yes.n "yes" above
arrow from Check.w to No.n "no" above
arrow from Yes.s then down 0.5cm then left until even with End \
  then to End.e
arrow from No.s then down 0.5cm then right until even with End \
  then to End.w
```

### Layered Architecture

```pikchr
boxwid = 3.5cm
boxht = 0.6cm

UI: box "UI Layer" fill #E3F2FD color #1976D2 thick
API: box "API Layer" fill #F3E5F5 color #7B1FA2 thick \
  at 0.7cm below UI
Business: box "Business Logic" fill #FFF3E0 color #E65100 thick \
  at 0.7cm below API
Data: box "Data Access" fill #E8F5E9 color #2E7D32 thick \
  at 0.7cm below Business
DB: box "Database" fill #EEEEEE color #424242 thick \
  at 0.7cm below Data

# Arrows showing flow
arrow from UI.s to API.n
arrow from API.s to Business.n
arrow from Business.s to Data.n
arrow from Data.s to DB.n
```

## Best Practices

### Use Named References

```pikchr
# Good - clear references
Start: box "Start"
Process: box "Process" at 2cm right of Start
arrow from Start to Process

# Avoid - hard to maintain
box "Start"
box "Process" at 2cm right of previous
arrow from 1st box to 2nd box
```

### Set Defaults Early

```pikchr
# Set all defaults at top
scale = 0.9
boxwid = 2cm
boxht = 1cm
circlerad = 0.5cm

# Then use them consistently
box "A"
box "B"
circle "C"
```

### Use Containers for Grouping

```pikchr
# Good - logical grouping
Header: [
  box "Title"
  box "Meta"
]

Body: [
  down
  box "Para 1"
  box "Para 2"
] at 1cm below Header

# Creates clean structure with named components
```

### Consistent Spacing

```pikchr
# Define spacing constant
spacing = 1.5cm

A: box "A"
B: box "B" at spacing right of A
C: box "C" at spacing right of B
D: box "D" at spacing below A
```

## Resources

For detailed syntax and more examples, see:
- `references/examples.md` - Official Pikchr examples from pikchr.org
- `references/grammar.md` - Complete grammar specification

## Quick Reference

**Objects**: `box circle ellipse oval cylinder file diamond line arrow spline dot arc text move`

**Directions**: `right down left up`

**Anchors**: `.n .ne .e .se .s .sw .w .nw .c .start .end`

**Positioning**: `at X right of Y below between until even with`

**Sizes**: `width height radius diameter fit`

**Styles**: `fill color thick thin thickness invisible solid`

**Text**: `above below ljust rjust center aligned bold italic mono big small`

**Units**: `cm mm in pt pc px`

**Keywords**: `from to then go heading previous first last 1st 2nd 3rd`
