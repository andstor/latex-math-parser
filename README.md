# latex-math-parser

> A parser for LaTeX math expressions.

This parser converts LaTeX math syntax into an abstract syntax tree (AST) representation. It is built using PEG.js and supports a mostly complete set of standard LaTeX math expressions.

## Installation

```bash
npm install @andstor/latex-math-parser
```

## Usage

```js
const { parse } = require('@andstor/latex-math-parser');

const latex = '\\frac{a}{b} + \\sqrt{x}';
const ast = parse(latex);

console.log(JSON.stringify(ast, null, 2));
```

## Generators

This parser can be used with various code generators to convert the AST into different programming languages or formats. Currently supported generators include:
- **[maxima-codegen](https://github.com/andstor/maxima-codegen)**: Maxima is a computer algebra system that can manipulate symbolic expressions.

## Features
The complete grammar for this parser can be found at [src/grammars/latex.pegjs](src/grammars/latex.pegjs). Following are some of the key features supported by the parser:

- **Arithmetic operations**: Addition, subtraction, multiplication, division, modulo, exponentiation, and implied multiplication.
- **Logical and bitwise operations**: Logical AND/OR, bitwise AND/OR/XOR, relational and equality operators.
- **Assignment expressions**: Standard and compound assignments (e.g., `=`, `+=`, `*=`, etc.).
- **Function calls**: Built-in and user-defined functions, including support for argument lists and nested calls.
- **Fractions**: Parsing of LaTeX `\frac` expressions.
- **Limits**: Parsing of limit expressions (e.g., `\lim`).
- **Logarithms**: Parsing of logarithms with arbitrary bases, including `\log`, `\ln`, and `\lg`.
- **Binomial coefficients**: Parsing of `\binom`.
- **Summations**: Parsing of `\sum` with lower and upper bounds.
- **Integrals**: Parsing of definite and indefinite integrals (`\int`).
- **Differentials**: Parsing of differential expressions.
- **Trigonometric functions**: Parsing of all standard and inverse trigonometric functions.
- **Roots**: Parsing of square roots and nth roots (`\sqrt`).
- **Absolute value**: Parsing of absolute value expressions.
- **Grouping**: Parentheses and LaTeX groupings (`\left(...\right)`).
- **Indexing**: Array and matrix indexing.
- **Lists and sets**: Parsing of lists (`[1,2,3]`) and sets (`\{1,2,3\}`).
- **Identifiers and constants**: Unicode and ASCII identifiers, mathematical constants (e.g., `\pi`, `e`, `\infty`).
- **Numbers**: Integer and floating-point literals.
- **Booleans and strings**: Parsing of boolean (`true`, `false`) and string literals.
- **Matrix environments**: Parsing of LaTeX matrix environments (e.g., `matrix`, `pmatrix`, etc.).
