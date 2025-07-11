/* tslint:disable:no-use-before-declare */

export class MPNode {
 type: string;
 parent: MPNode;
 position: any;
 constructor() {
  this.type = 'node';
  this.parent = null;
  this.position = null;
 }
 getChildren(): MPNode[] {
  return [];
 }
 asAList(): MPNode[] {
   // This one recursively goes through the whole tree and returns a list of
   // all the nodes found, it also populates the parent details as those might
   // be handy. You can act more efficiently with that list if you need to go
   // through it multiple times than if you were to recurse the tree multiple
   // times. Especially, when the tree is deep.
   let r: MPNode[] = [this];
   for (const child of this.getChildren()) {
     child.parent = this;
     r = r.concat(child.asAList());
   }
   return r;
 }
 // Simplified ASCII graph presentation of the expression.
 // Needs to be given the source for position matching.
 // Does not work with segments that have line changes.
 debugPrint(code: string): string {
   const offset = this.position['start']['offset'];
   let out = code.substring(offset, this.position['end']['offset']) + '\n';
   const len = this.position['end']['offset'] - offset;

   for (const item of this.asAList()) {
     let line = ' '.repeat(item.position['start']['offset'] - offset);
     line += '-'.repeat(item.position['end']['offset'] - item.position['start']['offset']);
     line += ' '.repeat(len - line.length + 1);
     line += item.constructor.name;
     if (item instanceof MPIdentifier || item instanceof MPInteger) {
       line += ' ' + item.value;
     } else if (item instanceof MPOperation || item instanceof MPPrefixOp || item instanceof MPPostfixOp) {
       line += ' ' + item.op;
     } else if (item instanceof MPLoopBit) {
       line += ' ' + item.mode;
     }
     out += line + '\n';
   }

   return out;
 }
}

export class MPList extends MPNode {
 items: MPNode[];
 constructor(items: MPNode[]) {
  super();
  this.type = 'list';
  this.items = items;
 }
 getChildren(): MPNode[] {
  return this.items;
 }
}

export class MPOperation extends MPNode {
 op: string;
 lhs: MPNode;
 rhs: MPNode;
 constructor(op: string, lhs: MPNode, rhs: MPNode) {
  super();
  this.type = 'operation';
  this.op = op;
  this.lhs = lhs;
  this.rhs = rhs;
 }
 getChildren(): MPNode[] {
  return [this.lhs, this.rhs];
 }
}

export class MPAtom extends MPNode {
 constructor() {
  super();
  this.type = 'atom';
 }
}

export class MPInteger extends MPAtom {
 value: number;
 constructor(value: number) {
  super();
  this.type = 'integer';
  this.value = value;
 }
}

export class MPFloat extends MPAtom {
 value: number;
 raw: string;
 constructor(value: number, raw: string) {
  super();
  this.type = 'float';
  this.value = value;
  this.raw = raw;
 }
}

export class MPString extends MPAtom {
 value: string;
 constructor(value: string) {
  super();
  this.type = 'string';
  this.value = value;
 }
}

export class MPBoolean extends MPAtom {
 value: boolean;
 constructor(value: boolean) {
  super();
  this.type = 'boolean';
  this.value = value;
 }
}

export class MPConstant extends MPAtom {
 value: string;
 description: string;
 constructor(value: string, description: string = '') {
  super();
  this.type = 'constant';
  this.value = value;
  this.description = description;
 }
}

export class MPIdentifier extends MPAtom {
 value: string;
 constructor(value: string) {
  super();
  this.type = 'identifier';
  this.value = value;
 }
 is_function_name(): boolean {
  return this.parent != null && this.parent instanceof MPFunctionCall && this.parent.name === this;
 }
 is_variable_name(): boolean {
  return !this.is_function_name();
 }
 is_being_written_to(): boolean {
   // TODO::: TIE INTO SECURITY-MAP like in the PHP-side.
  if (this.is_function_name()) {
   return (this.parent as MPFunctionCall).is_definition();
  } else {
   // Direct assignment
   if (this.parent != null && this.parent instanceof MPOperation && this.parent.op === ':' && this.parent.lhs === this) {
    return true;
   } else if (this.parent != null && this.parent instanceof MPList) {
    // multi assignment
    if (this.parent.parent != null && this.parent.parent instanceof MPOperation && this.parent.parent.lhs === this.parent) {
     return this.parent.parent.op === ':';
    }
   }
   return false;
  }
 }
 is_global(): boolean {
  // This is expensive as we need to travel the whole parent-chain and do some paraller checks.
  let i = this.parent;
  while (i != null) {
   if (i instanceof MPFunctionCall) {
     if (i.is_definition()) {
      return false; // the arguments of a function definition are scoped to that function.
    } else if ((i.name instanceof MPIdentifier && (i.name.value === 'block' || i.name.value === 'lambda')) ||
               (i.name instanceof MPString && (i.name.value === 'block' || i.name.value === 'lambda'))) {
      // If this is wrapped to a block/lambda then we check the first arguments contents.
      if (i.arguments[0] instanceof MPList) {
       for (const v of i.arguments[0].getChildren()) {
        if (v instanceof MPIdentifier && v.value === this.value) {
         return false;
        }
       }
      }
     }
   } else if (i instanceof MPOperation && (i.op === ':=' || i.op === '::=')) {
    // The case where we exist on the rhs of function definition.
    if (i.lhs instanceof MPFunctionCall) {
     for (const v of i.lhs.arguments) {
      if (v instanceof MPIdentifier && v.value === this.value) {
       return false;
      }
     }
    }
   }
   i = i.parent;
  }
  return true;
 }
}

export class MPAnnotation extends MPNode {
  annotationType: string;
  params: MPNode[];
  constructor(annotationType: string, params: MPNode[]) {
   super();
   this.type = 'annotation';
   this.annotationType = annotationType;
   this.params = params;
  }
  getChildren(): MPNode[] {
   return this.params;
  }
  // Is this annotation only active for the next statement.
  is_local(): boolean {
    if (this.annotationType === 'ignore' || this.annotationType === 'assume') {
      return true;
    }
    return false;
  }
}

export class MPComment extends MPNode {
 value: string;
 annotations: MPAnnotation[];
 constructor(value: string, annotations: MPAnnotation[]) {
  super();
  this.type = 'comment';
  this.value = value;
  this.annotations = annotations;
 }
 getChildren(): MPNode[] {
  return this.annotations;
 }
}

// Custom userdefined functions.
export class MPFunctionCall extends MPNode {
 name: MPNode;  // This could be anything.
 arguments: MPNode[];
 constructor(name: MPNode, args: MPNode[]) {
  super();
  this.type = 'functioncall';
  this.name = name;
  this.arguments = args;
 }
 getChildren(): MPNode[] {
  // Is the identifier a child or not is a question for others...
  return [].concat([this.name], this.arguments);
 }
 // Covenience functions that work only after $parent has been filled in.
 is_definition(): boolean {
  return this.parent != null && this.parent instanceof MPOperation &&
         (this.parent.op === '=') && this.parent.lhs === this;
 }
 is_call(): boolean {
  return !this.is_definition();
 }
}

// Standard builtin functions.
export class MPFunction extends MPNode {
 name: MPNode;  // The name of the function.
 arguments: MPNode[];
 constructor(name: MPNode, args: MPNode[]) {
  super();
  this.type = 'function';
  this.name = name;
  this.arguments = args;
 }
 getChildren(): MPNode[] {
  // Is the identifier a child or not is a question for others...
  return [].concat([this.name], this.arguments);
 }
}

export class MPFraction extends MPNode {
 numerator: MPNode;
 denominator: MPNode;
 constructor(numerator: MPNode, denominator: MPNode) {
  super();
  this.type = 'fraction';
  this.numerator = numerator;
  this.denominator = denominator;
 }
 getChildren(): MPNode[] {
  return [this.numerator, this.denominator];
 }
}

export class MPMatrix extends MPNode {
 name: MPNode;  // The name of the environment.
 items: MPNode[][];
 constructor(name: MPNode, items: MPNode[][]) {
  super();
  this.type = 'matrix';
  this.name = name;
  this.items = items;
 }
 getChildren(): MPNode[] {
  // Is the identifier a child or not is a question for others...
  return [].concat([this.name], this.items);
 }
}

export class MPArgument extends MPNode {
  value: MPNode;  // This could be anything.
  constructor(value: MPNode) {
   super();
   this.type = 'argument';
   this.value = value;
  }
  getChildren(): MPNode[] {
    return [this.value];
  }
}

export class MPDifferential extends MPNode {
  variable: MPNode;
  constructor(variable: MPNode) {
    super();
    this.type = 'differential';
    this.variable = variable;
  }
  getChildren(): MPNode[] {
    return [this.variable];
  }
}

export class MPNthRoot extends MPNode {
  argument: MPNode;
  n: MPNode;
  constructor(argument: MPNode, n: MPNode) {
    super();
    this.type = 'nthroot';
    this.argument = argument;
    this.n = n;
  }
  getChildren(): MPNode[] {
    return [this.argument, this.n];
  }
}

export class MPTrigonometric extends MPNode { //MPFunction {
  name: MPNode;
  argument: MPNode;
  inverse: boolean;
  constructor(name: MPNode, argument: MPNode, inverse: boolean = false) {
    super();
    //super(name, [argument]);
    this.type = 'trigonometric';
    this.name = name;
    this.argument = argument;
    this.inverse = inverse;
  }
  getChildren(): MPNode[] {
    return [this.name, this.argument];
  }
}

export class MPIntegral extends MPNode { //MPFunction {
  integrand: MPNode;
  differential: MPDifferential;
  upperBound: MPNode;
  lowerBound: MPNode;
  definite: boolean;
  constructor(integrand: MPNode, differential: MPDifferential, upperBound: MPNode, lowerBound: MPNode, definite: boolean = false) {
    super();
    //super(new MPIdentifier('integral'), [integrand]);
    this.type = 'integral';
    this.integrand = integrand;
    this.differential = differential;
    this.upperBound = upperBound;
    this.lowerBound = lowerBound;
    this.definite = definite;
  }
  getChildren(): MPNode[] {
    return [this.upperBound, this.lowerBound, this.integrand, this.differential];
  }
}

export class MPSum extends MPNode { //MPFunction {
  upperBound: MPNode;
  lowerBound: MPNode;
  index: MPNode;
  sum: MPNode;
  constructor(upperBound: MPNode, lowerBound: MPNode, index: MPNode, sum: MPNode) {
    super();
    //super(new MPIdentifier('sum'), [sum]);
   this.type = 'sum';
   this.upperBound = upperBound;
   this.lowerBound = lowerBound;
   this.index = index; // Index of summation
   this.sum = sum;
  }
  getChildren(): MPNode[] {
    return [this.upperBound, this.lowerBound, this.index, this.sum];
  }
}

export class MPBinomial extends MPNode { //MPFunction {
  upperIndex: MPNode;
  lowerIndex: MPNode;
  constructor(upperIndex: MPNode, lowerIndex: MPNode) {
    super();
    //super(new MPIdentifier('binomial'), [upperIndex, lowerIndex]);
   this.type = 'binomial';
   this.upperIndex = upperIndex;
   this.lowerIndex = lowerIndex;
  }
  getChildren(): MPNode[] {
    return [this.upperIndex, this.lowerIndex];
  }
}

export class MPLimit extends MPNode { //MPFunction {
  from: MPNode;
  to: MPNode;
  value: MPNode;
  constructor(from: MPNode, to: MPNode, value: MPNode) {
    super();
    //super(new MPIdentifier('limit'), [value]);
   this.type = 'limit';
   this.from = from;
   this.to = to;
   this.value = value;
  }
  getChildren(): MPNode[] {
    return [this.from, this.to, this.value];
  }
}
export class MPLogarithm extends MPNode { //MPFunction {
  value: MPNode;
  base: MPNode;
  constructor(value: MPNode, base: MPNode) {
   super();
    //super(new MPIdentifier('logarithm'), [value]);
   this.type = 'logarithm';
   this.value = value;
   this.base = base;
  }
  getChildren(): MPNode[] {
    return [this.value, this.base];
  }
}

export class MPMacro extends MPNode {
  value: MPNode;  // This could be anything.
  arguments: MPNode[];
  constructor(value: MPNode, args: MPNode[]) {
   super();
   this.type = 'macro';
   this.value = value;
   this.arguments = args;
  }
  getChildren(): MPNode[] {
    return [].concat([this.value], this.arguments);
  }
}

export class MPGroup extends MPNode {
 items: MPNode[];
 constructor(items: MPNode[]) {
  super();
  this.type = 'group';
  this.items = items;
 }
 getChildren(): MPNode[] {
  return this.items;
 }
}

export class MPSet extends MPNode {
 items: MPNode[];
 constructor(items: MPNode[]) {
  super();
  this.type = 'set';
  this.items = items;
 }
 getChildren(): MPNode[] {
  return this.items;
 }
}

// TODO: rename this to unary
export class MPPrefixOp extends MPNode {
  op: string;
  rhs: MPNode;
  constructor(op: string, rhs: MPNode) {
   super();
   this.type = 'prefixop';
   this.op = op;
   this.rhs = rhs;
  }
  getChildren(): MPNode[] {
   return [this.rhs];
  }
}

export class MPPostfixOp extends MPNode {
  op: string;
  lhs: MPNode;
  constructor(op: string, lhs: MPNode) {
   super();
   this.type = 'postfixop';
   this.op = op;
   this.lhs = lhs;
  }
  getChildren(): MPNode[] {
   return [this.lhs];
  }
}

export class MPIndexing extends MPNode {
  target: MPNode;
  indices: MPNode[];
  constructor(target: MPNode, indices: MPNode[]) {
   super();
   this.type = 'indexing';
   this.target = target;
   this.indices = indices;
  }
  getChildren(): MPNode[] {
   return [].concat(this.indices, [this.target]);
  }
}

export class MPIf extends MPNode {
  conditions: MPNode[];
  branches: MPNode[];
  constructor(conditions: MPNode[], branches: MPNode[]) {
   super();
   this.type = 'if';
   this.conditions = conditions;
   this.branches = branches;
  }
  getChildren(): MPNode[] {
   return [].concat(this.conditions, this.branches);
  }
}

export class MPLoopBit extends MPNode {
  mode: string;
  param: MPNode;
  constructor(mode: string, param: MPNode) {
    super();
    this.type = 'loopbit';
    this.mode = mode;
    this.param = param;
  }
  getChildren(): MPNode[] {
    return [this.param];
  }
 }

export class MPLoop extends MPNode {
  body: MPNode;
  conf: MPLoopBit[];
  constructor(body: MPNode, conf: MPLoopBit[]) {
    super();
    this.type = 'loop';
    this.body = body;
    this.conf = conf;
  }
  getChildren(): MPNode[] {
    return [].concat(this.conf, [this.body]);
  }
}

export class MPAssignment extends MPNode {
  op: string;
  lhs: MPNode;
  rhs: MPNode;
  constructor(op: string, lhs: MPNode, rhs: MPNode) {
    super();
    this.type = 'assignment';
    this.op = op;
    this.lhs = lhs;
    this.rhs = rhs;
  }
  getChildren(): MPNode[] {
    return [this.lhs, this.rhs];
  }
}

export class MPEvaluationFlag extends MPNode {
  name: MPIdentifier;
  value: MPNode;
  constructor(name: MPIdentifier, value: MPNode) {
   super();
   this.type = 'flag';
   this.name = name;
   this.value = value;
  }
}

export class MPStatement extends MPNode {
  statement: MPNode;
  flags: MPEvaluationFlag[];
  constructor(statement: MPNode, flags: MPEvaluationFlag[]) {
   super();
   this.type = 'statement';
   this.statement = statement;
   this.flags = flags;
  }
  getChildren() {
   return [].concat([this.statement], this.flags);
  }
}

export class MPRoot extends MPNode {
 items: MPNode[];
 constructor(items: MPNode[]) {
  super();
  this.type = 'root';
  this.items = items;
 }
 getChildren() {
  return this.items;
 }
 join(other: MPRoot): MPRoot {
   return new MPRoot(this.items.concat(other.items));
 }
}

/* tslint:enable:no-use-before-declare */
