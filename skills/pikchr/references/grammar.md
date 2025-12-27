# Pikchr Grammar Reference

Source: https://pikchr.org/home/doc/trunk/doc/grammar.md

## Overview
Pikchr is a domain-specific language for creating diagrams. The grammar uses specific notation: **bold** for keywords/operators, *italic* for non-terminals, ALL-CAPS for token classes, "*" for zero-or-more, and "?" for zero-or-one.

## Core Token Classes

**NEWLINE**: Unescaped newline character (U+000A); backslash before newlines treats them as whitespace.

**LABEL**: An object or place label starting with an upper-case ASCII letter and continuing with zero or more ASCII letters, digits, and/or underscores.

**VARIABLE**: A variable name consisting of a lower-case ASCII letter or "$" or "@" and additional alphanumeric characters.

**NUMBER**: Supports decimal integers, floating-point values, and hexadecimal (0x prefix), with optional two-character unit designators (in, cm, px, pt, pc, mm).

**ORDINAL**: A non-zero integer literal followed by one of the suffixes "st", "nd", "rd", or "th"; accepts "first" as alternative.

**STRING**: Double-quoted text with backslash escaping for quotes and backslashes.

**COLORNAME**: One of the 140 official HTML color names, in any mixture of upper and lower cases, plus "None" and "Off".

**CODEBLOCK**: Nested braces containing tokens, used in define statements.

## Key Structural Elements

**Statements**: The basic building blocks; scripts consist of statement lists.

**Objects**: Graphic primitives (arc, arrow, box, circle, cylinder, diamond, dot, ellipse, file, line, move, oval, spline, text).

**Attributes**: Configuration options applied to objects (positioning, styling, path direction).

**Places**: Specific points associated with objects using edge names (north, south, east, west, center, etc.).

**Positions**: Two-dimensional coordinates, specified as expressions, places, or calculated relationships between positions.

**Expressions**: Scalar values using operators and built-in functions (abs, cos, sin, sqrt, min, max, dist, int).

## Direction and Compass Keywords

Four cardinal directions: **right**, **down**, **left**, **up**.

Compass directions: n, north, ne, e, east, se, s, south, sw, w, west, nw.

## Common Syntax Rules

### Backslash Line Continuation
Use backslash `\` at end of line to continue multi-line statements:

```pikchr
box "Label" \
  width 5cm \
  height 2cm \
  fill lightblue
```

### Object Declaration Pattern
```
[LABEL:] object-type ["text"] [attributes]
```

### Position Expressions
- `X right of Y` - Relative positioning
- `X below Y` - Relative positioning
- `Object.anchor` - Anchor point reference
- `Position + (x, y)` - Offset from position
- `between Position1 and Position2` - Midpoint

### Path Direction
- `from Position to Position` - Direct line
- `from Position then Direction Distance then ...` - Multi-segment
- `until even with Object` - Continue until aligned

For complete grammar specification, visit: https://pikchr.org/home/doc/trunk/doc/grammar.md
