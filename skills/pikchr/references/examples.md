# Pikchr Examples Reference

Source: https://pikchr.org/home/doc/trunk/doc/examples.md

## Overview
Pikchr is a diagramming language that generates SVG graphics. Users can click any diagram on the examples page to view its source code.

## Key Examples Documented

### 1. **How To Build Pikchr**
Shows the build pipeline: `pikchr.y` and supporting files flow through a Lemon parser generator and C-Compiler to produce `pikchr.o` or `pikchr.exe`. The diagram illustrates dependencies between source files and compilation stages.

### 2. **SQLite Architecture Diagram**
Inspired by the official SQLite architecture at sqlite.org, this example organizes components into sections:
- Core (Interface through Code Generator)
- Backend (B-Tree through OS Interface)
- SQL Compiler (Tokenizer through Code Generator)
- Accessories (Utilities and Test Code)

### 3. **Syntax Diagrams**
Demonstrates railroad-style syntax notation showing language rules including:
- `element` definitions
- `LABEL: position` assignments
- `VARIABLE = expr` syntax
- `"print" print-args` statements

### 4. **Swimlanes**
Depicts concurrent workflows across multiple participants (Alan, Betty, Charlie, Darlene) showing version control branching, forking, and synchronization patterns.

### 5. **Graphs & Version Control**
Two versions showing commit histories with trunk and feature branches, illustrating rebasing concepts and merge strategies.

### 6. **Impossible Trident**
A geometric optical illusion using ellipses and lines, credited to Kees Nuyt under Creative Commons BY-NC-SA 4.0 license.

### 7. **Classic PIC Examples**
From Brian W. Kernighan's paper, including:
- Hash table visualization with node blocks
- Compiler pipeline (lexical analyzer → parser → semantic checker)
- Hardware diagram (DISK → CPU → CRT with paper rollers)
- Complex directed graph with multiple branches

## Interaction Features
- Click diagrams to toggle source code visibility
- Alt/Meta/Ctrl+Click or class toggle reveals Pikchr source
- Browser session storage can transfer diagrams to `/pikchrshow` editor

For full examples with source code, visit: https://pikchr.org/home/doc/trunk/doc/examples.md
