#!/usr/bin/env node

'use strict';

import fs from "fs";
import path from "path";
import peggy from "peggy";
import tspegjs from "ts-pegjs";
const grammarPath = path.resolve('./src/grammars/latex.pegjs');
var parserCode = fs.readFile(grammarPath, 'utf8', function (err, data) {

   let TSparser = peggy.generate(data, {
       output: 'source',
       cache: true,
       //trace: true,
       plugins: [tspegjs],
       allowedStartRules: ["Root"],
       tspegjs: {
         customHeader: "import {MPNode, MPOperation, MPAtom, MPConstant, MPInteger, MPFloat, MPString, MPBoolean, MPIdentifier, MPAssignment, MPComment, MPFunctionCall, MPFunction, MPGroup, MPSet, MPList, MPPrefixOp, MPPostfixOp, MPIndexing, MPIf, MPLoop, MPLoopBit, MPEvaluationFlag, MPStatement, MPRoot, MPAnnotation, MPMacro, MPFraction, MPLimit, MPLogarithm, MPBinomial, MPSum, MPIntegral, MPTrigonometric, MPDifferential, MPArgument, MPMatrix, MPNthRoot} from \'./MP_classes.js\';" +
                       "import {CONSTANTS} from\'./constants.js\';"
       }
   });

   const outputPath = path.resolve('./src/parser.ts');
   fs.writeFile(outputPath, TSparser, 'utf8', (err) => {console.log(err);});

});

