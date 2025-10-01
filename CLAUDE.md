# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Dart implementation of Unicode normalization (NFC, NFD, NFKC, NFKD) supporting Unicode 16.0. This is a Dart port of the JavaScript [walling/unorm](https://github.com/walling/unorm) library.

## Commands

### Testing
```bash
# Run all tests on VM
dart test --platform vm

# Run all tests
dart test

# Run specific test file
dart test test/unorm_dart_test.dart

# Run tests on Chrome (browser testing)
dart pub run test --platform chrome ./test/unorm_dart_test.dart
```

### Static Analysis
```bash
# Analyze project source
dart analyze

# Note: Formatting is intentionally not enforced
# lib/src/unormdata.dart is auto-generated and not formatted
```

### Development
```bash
# Install dependencies
dart pub get

# Dry-run publish (validate package)
dart pub publish --dry-run
```

### Unicode Data Generation

When Unicode version updates are needed:

```bash
# Step 1: Download latest Unicode data files from unicode.org
# Downloads: UnicodeData.txt, CompositionExclusions.txt, NormalizationTest.txt
dart run tools/unicode_data_updater.dart

# Step 2: Generate lib/src/unormdata.dart from downloaded data
dart run tools/normalizer_gen.dart
```

## Architecture

### Core Normalization Pipeline

The normalization process uses a chain of iterators to process Unicode characters:

1. **UCharIterator** - Converts input string to UChar objects (handles surrogate pairs)
2. **RecursiveDecompositeIterator** - Recursively decomposes characters based on mode (canonical/compatibility)
3. **DecompositeIterator** - Sorts decomposed characters by canonical class
4. **CompositeIterator** - Composes character sequences (for NFC/NFKC only)

### Iterator Chain by Mode

- **NFD** (Canonical Decomposition): UCharIterator → RecursiveDecompositeIterator(canonical) → DecompositeIterator
- **NFKD** (Compatibility Decomposition): UCharIterator → RecursiveDecompositeIterator(compatibility) → DecompositeIterator
- **NFC** (Canonical Composition): NFD pipeline → CompositeIterator
- **NFKC** (Compatibility Composition): NFKD pipeline → CompositeIterator

### Key Files

- **lib/src/unorm_dart_base.dart** - Main entry point, exposes `nfd()`, `nfc()`, `nfkd()`, `nfkc()` functions
- **lib/src/uchar.dart** - UChar representation with lazy feature loading (decomposition, canonical class, composition trie). Includes Hangul Jamo composition rules and caching logic
- **lib/src/unormdata.dart** - Auto-generated Unicode data table (256 blocks indexed by codepoint >> 8). Do not manually edit
- **lib/src/*_iterator.dart** - Iterator implementations for each normalization stage
- **tools/normalizer_gen.dart** - Generates unormdata.dart from Unicode data files
- **tools/unicode_data_updater.dart** - Downloads Unicode data from unicode.org

### Unicode Data Structure

The `unormdata` map in lib/src/unormdata.dart stores character features:
- Organized in 256 blocks (indexed by `codepoint >> 8`)
- Each character entry: `[decomposition, flags, composition_trie]`
- Flags encode: canonical class (bits 0-7), compatibility bit (1<<8), exclusion bit (1<<9)
- Composition trie maps `next_codepoint -> composed_codepoint` for canonical composition
- Hangul syllables are computed algorithmically rather than stored in data

### Hangul Processing

Korean Hangul syllables (U+AC00 to U+D7A3) are composed/decomposed using mathematical formulas defined in Unicode Standard Annex #15, not stored in unormdata. Constants in uchar.dart define the Jamo ranges and counts.
