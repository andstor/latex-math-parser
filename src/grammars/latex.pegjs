/*
 * Grammar for parsing LaTeX math.
 */

{

 /** <?php
 require_once(__DIR__ . '/../MP_classes.php');
 if (!array_key_exists('letToken', $options)) {
   $options['letToken'] = 'let';
 }
 if (!array_key_exists('allowPM', $options)) {
   $options['allowPM'] = true;
 }
 $this->options = $options;
 ?> **/
 if (!options.hasOwnProperty('letToken')) {
   options.letToken = 'let';
 }
 if (!options.hasOwnProperty('allowPM')) {
   options.allowPM = true;
 }
 if (!options.hasOwnProperty('constants')) {
   options.constants = CONSTANTS; // Imported constants
 }

//TODO: delete
 function opLBind(op) {
  switch(op) {
   case ':':
   case '::':
   case ':=':
   case '::=':
    return 180;
   case '!':
   case '!!':
    return 160;
   case '^':
   case '**':
    return 140;
   case '.':
    return 130;
   case '*':
   case '@@IS@@':
   case '@@Is@@':
   case '/':
    return 120;
   case '+-':
   case '\\pm':
   case '+':
   case '-':
    return 100;
   case '=':
   case '*':
   case '#':
   case '>':
   case '>=':
   case '<':
   case '<=':
    return 80;
   case '%and':
   case 'and':
   case 'nounand':
    return 65;
   case 'nand':
    return 62;
   case 'nor':
    return 61;
   case '%or':
   case 'or':
   case 'nounor':
    return 60;
   case 'implies':
    return 59;
   case 'xor':
   case 'xnor':
    return 58;
  }
  return 0;
 }

//TODO: delete
 function opRBind(op) {
  switch(op) {
   case ':':
   case '::':
   case ':=':
   case '::=':
    return 20;
   case '^':
   case '**':
    return 139;
   case '.':
    return 129;
   case '*':
   case '@@IS@@':
   case '@@Is@@':
   case '/':
    return 120;
   case '\\pm':
   case '+-':
   case '+':
    return 100;
   case '-':
    return 134;
   case '=':
   case '#':
   case '>':
   case '>=':
   case '<':
   case '<=':
    return 80;
   case 'not ':
   case 'nounnot ':
    return 70;
  }
  return 0;
 }

//TODO: delete
 function opBind(op) {
   if (!(op instanceof MPOperation)) {
     return op;
   }
   op.lhs = opBind(op.lhs);
   op.rhs = opBind(op.rhs);

   let nop:MPNode = undefined;

   if (op.lhs instanceof MPOperation && (opLBind(op.op) > opRBind(op.lhs.op))) {
    var posA = mergePosition(op.lhs.position, op.position);
    var posB = mergePosition(op.lhs.rhs.position, op.rhs.position);
    nop = new MPOperation(op.lhs.op, op.lhs.lhs, new MPOperation(op.op,op.lhs.rhs,op.rhs));
    nop.position = posA;
    (nop as MPOperation).rhs.position = posB;
    op = nop;
    op = opBind(op);
   }
   if (op.rhs instanceof MPOperation && (opRBind(op.op) > opLBind(op.rhs.op))) {
    var posA = mergePosition(op.rhs.position, op.position);
    var posB = mergePosition(op.lhs.position, op.rhs.lhs.position);
    nop = new MPOperation(op.rhs.op, new MPOperation(op.op, op.lhs, op.rhs.lhs), op.rhs.rhs);
    nop.position = posA;
    (nop as MPOperation).lhs.position = posB;
    op = nop;
    op = opBind(op);
   }
   if (op.lhs instanceof MPPrefixOp && (opLBind(op.op) > opRBind(op.lhs.op))) {
    var posA = mergePosition(op.lhs.position, op.position);
    var posB = mergePosition(op.lhs.rhs.position, op.rhs.position);
    nop = new MPPrefixOp(op.lhs.op, new MPOperation(op.op,op.lhs.rhs,op.rhs));
    nop.position = posA;
    (nop as MPPrefixOp).rhs.position = posB;
    op = nop;
    op = opBind(op);
   }
   if (op.rhs instanceof MPPostfixOp && (opRBind(op.op) > opLBind(op.rhs.op))) {
    var posA = mergePosition(op.rhs.position, op.position);
    var posB = mergePosition(op.lhs.position, op.rhs.lhs.position);
    nop = new MPPostfixOp(op.rhs.op, new MPOperation(op.op, op.lhs, op.rhs.lhs));
    nop.position = posA;
    (nop as MPPostfixOp).lhs.position = posB;
    op = nop;
    op = opBind(op);
   }

   return op;
 }

 function mergePosition(posA,posB) {
    var R = {start:{offset:posA.start.offset,line:posA.start.line,column:posA.start.column},end:{offset:posA.end.offset,line:posA.end.line,column:posA.end.column}};
    if (posB.start.offset < R.start.offset)
        R.start = posB.start;
    if (posB.end.offset > R.end.offset)
        R.end = posB.end;
    return R;
 }


  function compareEnv(g1, g2) {
    return g1.content.join("") == g2.content.join("");
  }

  function extractOptional(optional, index) {
    return optional ? optional[index] : null;
  }

 function extractList(list, index) {
    return list.map(function(element) { return element[index]; });
  }
  function buildList(head, tail, index) {
    return [head].concat(extractList(tail, index));
  }

  function buildBinaryExpression(head, tail) {
    return tail.reduce(function(result, element) {
      var n = new MPOperation(element[1],result,element[3]);
      n.position = location();
      return n;
    }, head);
  }
  function buildLogicalExpression(head, tail) {
    return tail.reduce(function(result, element) {
      var n = new MPOperation(element[1],result,element[3]);
      n.position = location();
      return n;
    }, head);
  }

  function optionalList(value) {
    return value !== null ? value : [];
  }

}

Root
  //=  final:Statement __?{
  =  lines:(_? Line _?)* _? final:Statement? _?{
  /** <?php
  $items = array();
  foreach ($lines as $item) {
   $items[] = $item[1];
  }
  if ($final)
   $items[] = $final;
  $r = new MP_Root($items);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/

  var items = lines.map(function (value,index){return value[1];});
  if (typeof final != 'undefined' && null != final)
    items = items.concat([final]);

  var n = new MPRoot(items);
  n.position = location();
  return n;
  }

Line
 = _? s:Statement _? EOL {/** <?php return $s; ?> **/ return s;}

EvaluationFlag
  = _? ',' _? id:Identifier val:(('=' / ':') Expression)? {
  /** <?php
  $v = new MP_Boolean(true);
  if ($val)
   $v = $val[1];
  $r = new MP_EvaluationFlag($id,$v);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var v = new MPBoolean(true);
  if (typeof val != 'undefined' && null != val)
    v = val[1];
  var n = new MPEvaluationFlag(id, v);
  n.position = location();
  return n; }

Statement
  = _? exp:Expression flags:EvaluationFlag* {
  /** <?php
  $r = new MP_Statement($exp,$flags);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  //TODO:var value =  exps.map(function (value,index){return value[1];})
  var n = new MPStatement(exp, flags);
  n.position = location();
  return n; }


Expression
  = AssignmentExpression

AssignmentOperator
  = "*="
  / "/="
  / "%="
  / "+="
  / "-="
  / "<<="
  / ">>="
  / ">>>="
  / "&="
  / "^="
  / "|="

AssignmentExpression
  = left:LeftHandSideExpression _?
    "=" !"=" _?
    right:AssignmentExpression
    {
    var n = new MPAssignment("=", left, right);
    n.position = location();
    return n;}
  / left:LeftHandSideExpression _?
    operator:AssignmentOperator _?
    right:AssignmentExpression
    {
    var n = new MPAssignment(operator, left, right);
    n.position = location();
    return n;}
  / LogicalORExpression

LogicalOROperator
  = "||"

LogicalORExpression
  = head:LogicalANDExpression
    tail:(_? LogicalOROperator _? LogicalANDExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalANDOperator
  = "&&"

LogicalANDExpression
  = head:BitwiseORExpression
    tail:(_? LogicalANDOperator _? BitwiseORExpression)*
    { return buildLogicalExpression(head, tail); }

BitwiseOROperator
  = $("|" ![|=])


BitwiseORExpression
  = head:BitwiseXORExpression
    tail:(_? BitwiseOROperator _? BitwiseXORExpression)*
    { return buildBinaryExpression(head, tail); }


BitwiseXOROperator
  = $("^" !"=")

BitwiseXORExpression
  = head:BitwiseANDExpression
    tail:(_? BitwiseXOROperator _? BitwiseANDExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseANDOperator
  = $("&" ![&=])

BitwiseANDExpression
  = head:EqualityExpression
    tail:(_? BitwiseANDOperator _? EqualityExpression)*
    { return buildBinaryExpression(head, tail); }


EqualityOperator
  = "==="
  / "!=="
  / "=="
  / "!="


EqualityExpression
  = head:RelationalExpression
    tail:(_? EqualityOperator _? RelationalExpression)*
    { return buildBinaryExpression(head, tail); }

RelationalOperator
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")
  /// $InstanceofToken
  /// $InToken


RelationalExpression
  = head:ShiftExpression
    tail:(_? RelationalOperator _? ShiftExpression)*
    { return buildBinaryExpression(head, tail); }


ShiftOperator
  = $("<<"  !"=")
  / $(">>>" !"=")
  / $(">>"  !"=")

ShiftExpression
  = head:AdditiveExpression
    tail:(_? ShiftOperator _? AdditiveExpression)*
    { return buildBinaryExpression(head, tail); }

AdditiveOperator
  = $("+" ![+=])
  / $("-" ![-=])
  / $("\\pm")

AdditiveExpression
  = head:MultiplicativeExpression
    tail:(_? AdditiveOperator _? MultiplicativeExpression)*
    { return buildBinaryExpression(head, tail); }

MultiplicativeOperator
  = $("*" !"=")
  / $("\\cdot" !"=")
  / $("/" !"=")
  / $("%" !"=")

MultiplicativeExpression
  = head:UnaryExpression
    tail:(_? MultiplicativeOperator _? UnaryExpression)*
    {
      /* return tail.reduce(function(result, element) {
          let implied = false;
          let op = element[1];
          if (element[1] === null) {
            op = "*";  // Implied multiplication
          }
          var n = new MPOperation(op,result,element[3], true);
          n.position = location();
          return n;
      }, head); */
      return buildBinaryExpression(head, tail);
    }

UnaryOperator
  = //$DeleteToken
  /// $VoidToken
  /// $TypeofToken
   "++"
  / "--"
  / $("+" !"=")
  / $("-" !"=")
  / "~"
  / "!"

UnaryExpression
  = PostfixExpression
  / operator:UnaryOperator _? argument:UnaryExpression {
      var n = new MPPrefixOp(operator, argument);
      n.position = location();
      return n;
    }

//TODO: remove this? or add faculty?
PostfixOperator
  = "++"
  / "--"
  / "!"

PostfixExpression
  = argument:LeftHandSideExpression _? operator:PostfixOperator {
      var n = new MPPostfixOp(operator, argument);
      n.position = location();
      return n;
      // prefix = false;
      // Update Expression
    }
  / LeftHandSideExpression

LeftHandSideExpression
  = PrimaryExpression

ArgumentList
  = head:AssignmentExpression tail:(_? "," _? AssignmentExpression)* {
      return buildList(head, tail, 3);
    }

Arguments
  = "(" _? args:(ArgumentList _?)? ")" {
      return optionalList(extractOptional(args, 0));
    }

PrimaryExpression
  = Group           //"(" _ expression:Expression _ ")" { return expression; }
  / MatrixEnvironment // begin{matrix} and end{matrix}
  / FunctionCall    // a = f(x)
  / Constant        // \pi, e, \infty, ...
  / Macro           // \macro  or   \macro{}  or   \macro{}{}    etc... or command everything else...
  / Indexing        // a[b]
  / Literal         // number, string,  boolean,  etc...
  / Identifier      // hello, foo, bar, etc...
  / List            // \left\[ \right\]    or [1,2,3]
  / Set             // \left\{ \right\}   or   \{1,2,3\}

//TODO: delete
DotOp
  = lhs:PrimaryExpression _? '.' _? rhs:Expression {
  /** <?php
  $r = new MP_Operation('.',$lhs,$rhs);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return opBind($r);
  ?> **/
  var n = new MPOperation('.',lhs,rhs);
  n.position = location();
  return opBind(n); }

//TODO: fix group to handle (1,2,3,4)
FunctionCall
  = fnc:(Identifier/String/Group/Indexing) args:(_? Group)+ indices:(_? List)+ {
  /** <?php
  // So indexing the return value of a function call is possible and there are array functions.
  $inner = new MP_FunctionCall($fnc, $args[0][1]->items);
  $inner->position = mergePosition($fnc->position, $args[0][1]->position);
  for ($i = 1; $i < count($args); $i++) {
   $f = new MP_FunctionCall($inner, $args[$i][1]->items);
   $f->position = mergePosition($inner->position, $args[$i][1]->position);
   $inner = $f;
  }
  $v = array();
  foreach ($indices as $ind)
   $v[] = $ind[1];
  $r = new MP_Indexing($inner,$v);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  let inner = new MPFunctionCall(fnc, args[0][1].items);
  inner.position = mergePosition(fnc.position, args[0][1].position);
  for (let i = 1; i < args.length; i++) {
   let f = new MPFunctionCall(inner, args[i][1].items);
   f.position = mergePosition(inner.position, args[i][1].position);
   inner = f;
  }
  var v = indices.map(function (value,index){return value[1];});
  var n = new MPIndexing(inner, v);
  n.position = location();
  return n; }
  / fnc:(Identifier/String/Group/Indexing) args:(_? Group)+ {
  /** <?php
  // We might be calling the return value of a function...
  $inner = new MP_FunctionCall($fnc, $args[0][1]->items);
  $inner->position = mergePosition($fnc->position, $args[0][1]->position);
  for ($i = 1; $i < count($args); $i++) {
    $f = new MP_FunctionCall($inner, $args[$i][1]->items);
    $f->position = mergePosition($inner->position, $args[$i][1]->position);
    $inner = $f;
  }
  return $inner;
  ?> **/
  let inner = new MPFunctionCall(fnc, args[0][1].items);
  inner.position = mergePosition(fnc.position, args[0][1].position);
  for (let i = 1; i < args.length; i++) {
    let f = new MPFunctionCall(inner, args[i][1].items);
    f.position = mergePosition(inner.position, args[i][1].position);
    inner = f;
  }
  return inner; }

Macro "macro"
  = Function

  /* / Escape m:Identifier args:Argument* {
    throw new Error("Macro \"" + m.value + "\" not supported");
    var n = new MPMacro(m, args);
    n.position = location();
    return n;} */

FuncName
  = "max"
  / "min"
  //"lg"
  /// "log"
  /// "ln"
  /// "sqrt"
  /// "abs"
  /// "sum"
  /// "lim"
  /// "int"
  /// "binom"

Function
  = Frac
  / Limit
  / Logarithm
  / Binomial
  / Sum
  / Integral
  / Trigonometric
  / NthRoot
  / Abs
  / Escape m:FuncName args:(_? Argument)+ {
    var n = new MPFunction(m, args);
    n.position = location();
    return n;}
  / Escape m:FuncName (_/!Char) exp:MultiplicativeExpression {
    var n = new MPFunction(m, [exp]);
    n.position = location();
    return n;}

Frac
  = Escape 'frac' BeginGroup _? numerator:Expression _? EndGroup _? BeginGroup _? denominator:Expression _? EndGroup {
    var n = new MPFraction(numerator, denominator);
    n.position = location();
    return n;}

Limit
  = Escape 'lim' '_' BeginGroup _? from:Identifier Escape 'to' _? to:Expression _? EndGroup exp:MultiplicativeExpression {
    var n = new MPLimit(from, to, exp);
    n.position = location();
    return n;}

Logarithm
  = Escape 'log' '_' base:(Argument/SingleDigitInteger/SingleDigitIdentifier) exp:(Expression) {
    var n = new MPLogarithm(exp, base);
    n.position = location();
    return n;}
  / Escape 'log' (_/!Char) exp:Expression {
    var n = new MPLogarithm(exp, new MPInteger(10));
    n.position = location();
    return n;}
  / Escape 'lg' (_/!Char) exp:Expression {
    var n = new MPLogarithm(exp, new MPInteger(10));
    n.position = location();
    return n;}
  / Escape 'ln' (_/!Char) exp:Expression {
    var n = new MPLogarithm(exp, new MPConstant('e', "Euler's number"));
    n.position = location();
    return n;}

Binomial
  = Escape 'binom' low:(Argument/SingleDigitInteger/SingleDigitIdentifier) upp:(Argument/SingleDigitInteger/SingleDigitIdentifier) {
    var n = new MPBinomial(low, upp);
    n.position = location();
    return n;}

Sum
  = Escape "sum" '_' low:SumArgument _? '^' upp:Argument sum:Expression {
    var n = new MPSum(upp, low[0], low[1], sum);
    n.position = location();
    return n;}
  / Escape "sum" '^' upp:Argument _? '_' low:SumArgument sum:Expression {
    var n = new MPSum(upp, low[0], low[1], sum);
    n.position = location();
    return n;}

SumArgument
  = BeginGroup _? index:Char _? '=' _? value:Expression _? EndGroup { return [index, value];}

//TODO: DIGIT/CHAR to be single Integer or Single identifier?...
Integral // TODO: change digit and char to Number and Identifier with only one digit/char
  = Escape 'int' '_' low:(Argument/SingleDigitInteger/SingleDigitIdentifier) '^' upp:(Argument/SingleDigitInteger/SingleDigitIdentifier) _?  exp:Integrand _? '*'? d:Differential  {
    //error("The number must be an odd integer.");
    var n = new MPIntegral(exp, d, low, upp, true);
    n.position = location();
    return n;}
  / Escape 'int' (_/!Char)  exp:Integrand _? '*'? d:Differential  {
    //error("The number must be an odd integer.");
    var n = new MPIntegral(exp, d, null, null, false);
    n.position = location();
    return n;}

Integrand
 =  Expression
  
Differential
  = 'd' v:Char {
    var n = new MPDifferential(v);
    n.position = location();
    return n;}

TrigFunc
  = "sin"
  / "cos"
  / "tan"
  / "sec"
  / "csc"
  / "cot"
  / "sinh"
  / "cosh"
  / "tanh"
  / "sech"
  / "csch"
  / "coth"

TrigFuncInv
  = "asin" / "arcsin"
  / "acos" / "arccos"
  / "atan" / "arctan"
  / "asec" / "arcsec"
  / "acsc" / "arccsc"
  / "acot" / "arccot"
  / "asinh" / "arcsinh"
  / "acosh" / "arccosh"
  / "atanh" / "arctanh"
  / "asech" / "arcsech"
  / "acsch" / "arccsch"
  / "acoth" / "arccoth"

Trigonometric
  = Escape name:(TrigFunc/TrigFuncInv) '^' BeginGroup _? '-1' _? EndGroup _? exp:(Argument/MultiplicativeExpression) {
    //TODO: indicate inverse
    var n = new MPTrigonometric(name, exp, true);
    n.position = location();
    return n;}
  / Escape name:(TrigFunc/TrigFuncInv) op:'^' BeginGroup _? !'-1' pow:Expression _? EndGroup _? exp:(Argument/MultiplicativeExpression) {
    //TODO: indicate inverse
    var t = new MPTrigonometric(name, exp);
    t.position = location();
    
    var n = new MPOperation(op,t,pow);
    n.position = location();
    return opBind(n);}
  / Escape name:(TrigFunc/TrigFuncInv) op:'^' pow:AlphaNumerical _? exp:MultiplicativeExpression {
    //TODO: AlphaNumerical to SinggleAlphaNumerical prooperly object.
    var t = new MPTrigonometric(name, exp);
    t.position = location();
    
    var n = new MPOperation(op,t,pow);
    n.position = location();
    return n;}
  / Escape name:(TrigFunc/TrigFuncInv) _? exp:Argument {
    var n = new MPTrigonometric(name, exp);
    n.position = location();
    return n;}
  / Escape name:(TrigFunc/TrigFuncInv) (_/!Char) exp:MultiplicativeExpression {
    var n = new MPTrigonometric(name, exp);
    n.position = location();
    return n;}

NthRoot
  = Escape 'sqrt' _? '[' _? nth:Expression _? ']' _? exp:(Argument/MultiplicativeExpression) {
    var n = new MPNthRoot(exp, nth);
    n.position = location();
    return n;}
  / Escape 'sqrt' _? exp:Argument {
    var n = new MPNthRoot(exp, new MPInteger(1));
    n.position = location();
    return n;}
  / Escape 'sqrt' (_/!Char) exp:MultiplicativeExpression {
    var n = new MPNthRoot(exp, new MPInteger(1));
    n.position = location();
    return n;}

Abs
  = '|' _? arg:Expression _? '|' {
  /** <?php
  // So the abs syntax candy is a very special thing that we don't actually map
  // to an object for logical use. Atleast yet.
  $f = new MP_FunctionCall(new MP_Identifier('abs'), array($arg));
  $f->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $f;
  ?> **/
  let f = new MPFunction(new MPIdentifier('abs'), [arg]);
  f.position = location();
  return f;
  }

Argument
  = BeginGroup _? exp:Expression _? EndGroup { return exp; }

Group
  = '\\left' '(' _? exp:Expression _? '\\right' ')' {
  //TODO: change items to item.
  //var v = tail.map(function (value,index){return value[3];});
  var n = new MPGroup([exp]);//.concat(v));
  n.position = location();
  return n; }
  / '(' _? exp:Expression _? ')' {
  //TODO: change items to item.
  //var v = tail.map(function (value,index){return value[3];});
  var n = new MPGroup([exp]);//.concat(v));
  n.position = location();
  return n; }
  / '\\left' '(' _? '\\right' ')' {
  var n = new MPGroup([]);
  n.position = location();
  return n; }
  / '(' _? ')' {
  var n = new MPGroup([]);
  n.position = location();
  return n; }

Indexing
  = trg:(Identifier / List / Set / Group) indices:(_? List)+ {
  /** <?php
  $v = array();
  foreach ($indices as $ind)
   $v[] = $ind[1];
  $r = new MP_Indexing($trg,$v);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var v = indices.map(function (value,index){return value[1];});
  var n = new MPIndexing(trg, v);
  n.position = location();
  return n; }

List
  = '[' _? exp:Expression tail:(_? ',' _? Expression)* _? ']' {
  /** <?php
  $items = array($exp);
  foreach ($tail as $el)
   $items[] = $el[3];
  $r = new MP_List($items);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var v = tail.map(function (value,index){return value[3];});
  var n = new MPList([exp].concat(v));
  n.position = location();
  return n;  }
  / '[' _? ']' {
  /** <?php
  $r = new MP_List(array());
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPList([]);
  n.position = location();
  return n; }

Set
  = '\\left' Escape '{' _? exp:Expression tail:(_? ',' _? Expression)* _? '\\right' Escape '}' {
  /** <?php
  $items = array($exp);
  foreach ($tail as $el)
   $items[] = $el[3];
  $r = new MP_Set($items);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var v = tail.map(function (value,index){return value[3];});
  var n = new MPSet([exp].concat(v));
  n.position = location();
  return n; }

  / Escape '{' _? exp:Expression tail:(_? ',' _? Expression)* _? Escape '}' {
  /** <?php
  $items = array($exp);
  foreach ($tail as $el)
   $items[] = $el[3];
  $r = new MP_Set($items);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var v = tail.map(function (value,index){return value[3];});
  var n = new MPSet([exp].concat(v));
  n.position = location();
  return n; }
  / '\\{' _? '\\}' {
  /** <?php
  $r = new MP_Set(array());
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPSet([]);
  n.position = location();
  return n; }

Identifier 
  = !ReservedWord !SpecialWord name:IdentifierName { return name; }

IdentifierName "identifier"
  = char:IdentifierStart morechars:(!SpecialWord IdentifierTail)* {
  /** <?php
  $r = new MP_Identifier($char.join("",$morechars));
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  let tail = morechars.map(function(value,index) { return value[1]; }).join("");
  var n = new MPIdentifier(char+tail);
  n.position = location();
  return n; }

IdentifierStart
  = [a-zA-Z]
  / '_'
  / ULetter

IdentifierTail
  = IdentifierStart
  / [0-9]
  //TODO:  / IdentifierStart '_' '{' IdentifierName / [0-9] '}'

ReservedWord
  = 'var' //!IdentifierTail

SpecialWord
  = $(Differential)

Literal
  = Float
  / Boolean
  / Integer
  / String

Constant
  = c:(Escape? AlphaNumerical+ { return text()}) &{
    return options.constants.get(c) !== undefined;
    }
    !Char {
    let constant = options.constants.get(c);
    var n = new MPConstant(constant.name, constant.description);
    n.position = location();
    return n;}

Integer "integer"
  = d: Digit+ {
  /** <?php
  $r = new MP_Integer(intval(join("",$d),10), join("",$d));
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPInteger(parseInt(d.join(""), 10));
  n.position = location();
  return n; }

Float "float"
  = da:Digit* '.' db:Digit+ dc:FloatExp? {
  /** <?php
  $r = new MP_Float(floatval(join("",$da).'.'.join("",$db).$dc), join("",$da).'.'.join("",$db).$dc);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPFloat(parseFloat(text()), text());
  n.position = location();
  return n;}
  / da:Digit* '.' dc:FloatExp? {
  /** <?php
  $r = new MP_Float(floatval(join("",$da).'.'.$dc), join("",$da).'.'.$dc);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPFloat(parseFloat(text()), text());
  n.position = location();
  return n;}
  / da:Digit+ db:FloatExp {
  /** <?php
  $r = new MP_Float(floatval(join("",$da).$db), join("",$da).$db);
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPFloat(parseFloat(text()), text());
  n.position = location();
  return n;}

FloatExp
  = a:('e'/'E') b:[+-]? c:[0-9]+ {
  /** <?php
    return $a . $b . join('',$c);
  ?> **/
    return text();
  }

Boolean "boolean"
  = v:("true" / "false") !IdentifierTail {
  /** <?php
  $r = new MP_Boolean($v == 'true');
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPBoolean(v == 'true');
  n.position = location();
  return n; }

String "string"
  = '"' chars:StringChars* '"' {
  /** <?php
  $r = new MP_String(join("",$chars));
  $r->position = array('start'=>$this->peg_reportedPos,'end'=>$this->peg_currPos);
  return $r;
  ?> **/
  var n = new MPString(chars.join(""));
  n.position = location();
  return n; }

StringChars
  = !('"' / "\\") c:. { /** <?php return $c; ?> **/ return c; }
  / "\\\\" { return "\\"; }
  / '\\"' { return '"'; }
  / '\\' { return ''; } // Note that this is how Maxima does it. It throws away escapes it does not know and it only knows those two.

_ "whitespace"
  = [ \t\n\r\v\f\u00A0\uFEFF\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000\u000A-\u000D]+


// Unicode categories stolen from here https://github.com/pegjs/pegjs/blob/master/examples/javascript.pegjs#L374
// Letter, Lowercase
ULetter "unicode letter character"
 = [\u0061-\u007A\u00B5\u00DF-\u00F6\u00F8-\u00FF\u0101\u0103\u0105\u0107\u0109\u010B\u010D\u010F\u0111\u0113\u0115\u0117\u0119\u011B\u011D\u011F\u0121\u0123\u0125\u0127\u0129\u012B\u012D\u012F\u0131\u0133\u0135\u0137-\u0138\u013A\u013C\u013E\u0140\u0142\u0144\u0146\u0148-\u0149\u014B\u014D\u014F\u0151\u0153\u0155\u0157\u0159\u015B\u015D\u015F\u0161\u0163\u0165\u0167\u0169\u016B\u016D\u016F\u0171\u0173\u0175\u0177\u017A\u017C\u017E-\u0180\u0183\u0185\u0188\u018C-\u018D\u0192\u0195\u0199-\u019B\u019E\u01A1\u01A3\u01A5\u01A8\u01AA-\u01AB\u01AD\u01B0\u01B4\u01B6\u01B9-\u01BA\u01BD-\u01BF\u01C6\u01C9\u01CC\u01CE\u01D0\u01D2\u01D4\u01D6\u01D8\u01DA\u01DC-\u01DD\u01DF\u01E1\u01E3\u01E5\u01E7\u01E9\u01EB\u01ED\u01EF-\u01F0\u01F3\u01F5\u01F9\u01FB\u01FD\u01FF\u0201\u0203\u0205\u0207\u0209\u020B\u020D\u020F\u0211\u0213\u0215\u0217\u0219\u021B\u021D\u021F\u0221\u0223\u0225\u0227\u0229\u022B\u022D\u022F\u0231\u0233-\u0239\u023C\u023F-\u0240\u0242\u0247\u0249\u024B\u024D\u024F-\u0293\u0295-\u02AF\u0371\u0373\u0377\u037B-\u037D\u0390\u03AC-\u03CE\u03D0-\u03D1\u03D5-\u03D7\u03D9\u03DB\u03DD\u03DF\u03E1\u03E3\u03E5\u03E7\u03E9\u03EB\u03ED\u03EF-\u03F3\u03F5\u03F8\u03FB-\u03FC\u0430-\u045F\u0461\u0463\u0465\u0467\u0469\u046B\u046D\u046F\u0471\u0473\u0475\u0477\u0479\u047B\u047D\u047F\u0481\u048B\u048D\u048F\u0491\u0493\u0495\u0497\u0499\u049B\u049D\u049F\u04A1\u04A3\u04A5\u04A7\u04A9\u04AB\u04AD\u04AF\u04B1\u04B3\u04B5\u04B7\u04B9\u04BB\u04BD\u04BF\u04C2\u04C4\u04C6\u04C8\u04CA\u04CC\u04CE-\u04CF\u04D1\u04D3\u04D5\u04D7\u04D9\u04DB\u04DD\u04DF\u04E1\u04E3\u04E5\u04E7\u04E9\u04EB\u04ED\u04EF\u04F1\u04F3\u04F5\u04F7\u04F9\u04FB\u04FD\u04FF\u0501\u0503\u0505\u0507\u0509\u050B\u050D\u050F\u0511\u0513\u0515\u0517\u0519\u051B\u051D\u051F\u0521\u0523\u0525\u0527\u0529\u052B\u052D\u052F\u0561-\u0587\u13F8-\u13FD\u1D00-\u1D2B\u1D6B-\u1D77\u1D79-\u1D9A\u1E01\u1E03\u1E05\u1E07\u1E09\u1E0B\u1E0D\u1E0F\u1E11\u1E13\u1E15\u1E17\u1E19\u1E1B\u1E1D\u1E1F\u1E21\u1E23\u1E25\u1E27\u1E29\u1E2B\u1E2D\u1E2F\u1E31\u1E33\u1E35\u1E37\u1E39\u1E3B\u1E3D\u1E3F\u1E41\u1E43\u1E45\u1E47\u1E49\u1E4B\u1E4D\u1E4F\u1E51\u1E53\u1E55\u1E57\u1E59\u1E5B\u1E5D\u1E5F\u1E61\u1E63\u1E65\u1E67\u1E69\u1E6B\u1E6D\u1E6F\u1E71\u1E73\u1E75\u1E77\u1E79\u1E7B\u1E7D\u1E7F\u1E81\u1E83\u1E85\u1E87\u1E89\u1E8B\u1E8D\u1E8F\u1E91\u1E93\u1E95-\u1E9D\u1E9F\u1EA1\u1EA3\u1EA5\u1EA7\u1EA9\u1EAB\u1EAD\u1EAF\u1EB1\u1EB3\u1EB5\u1EB7\u1EB9\u1EBB\u1EBD\u1EBF\u1EC1\u1EC3\u1EC5\u1EC7\u1EC9\u1ECB\u1ECD\u1ECF\u1ED1\u1ED3\u1ED5\u1ED7\u1ED9\u1EDB\u1EDD\u1EDF\u1EE1\u1EE3\u1EE5\u1EE7\u1EE9\u1EEB\u1EED\u1EEF\u1EF1\u1EF3\u1EF5\u1EF7\u1EF9\u1EFB\u1EFD\u1EFF-\u1F07\u1F10-\u1F15\u1F20-\u1F27\u1F30-\u1F37\u1F40-\u1F45\u1F50-\u1F57\u1F60-\u1F67\u1F70-\u1F7D\u1F80-\u1F87\u1F90-\u1F97\u1FA0-\u1FA7\u1FB0-\u1FB4\u1FB6-\u1FB7\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FC7\u1FD0-\u1FD3\u1FD6-\u1FD7\u1FE0-\u1FE7\u1FF2-\u1FF4\u1FF6-\u1FF7\u210A\u210E-\u210F\u2113\u212F\u2134\u2139\u213C-\u213D\u2146-\u2149\u214E\u2184\u2C30-\u2C5E\u2C61\u2C65-\u2C66\u2C68\u2C6A\u2C6C\u2C71\u2C73-\u2C74\u2C76-\u2C7B\u2C81\u2C83\u2C85\u2C87\u2C89\u2C8B\u2C8D\u2C8F\u2C91\u2C93\u2C95\u2C97\u2C99\u2C9B\u2C9D\u2C9F\u2CA1\u2CA3\u2CA5\u2CA7\u2CA9\u2CAB\u2CAD\u2CAF\u2CB1\u2CB3\u2CB5\u2CB7\u2CB9\u2CBB\u2CBD\u2CBF\u2CC1\u2CC3\u2CC5\u2CC7\u2CC9\u2CCB\u2CCD\u2CCF\u2CD1\u2CD3\u2CD5\u2CD7\u2CD9\u2CDB\u2CDD\u2CDF\u2CE1\u2CE3-\u2CE4\u2CEC\u2CEE\u2CF3\u2D00-\u2D25\u2D27\u2D2D\uA641\uA643\uA645\uA647\uA649\uA64B\uA64D\uA64F\uA651\uA653\uA655\uA657\uA659\uA65B\uA65D\uA65F\uA661\uA663\uA665\uA667\uA669\uA66B\uA66D\uA681\uA683\uA685\uA687\uA689\uA68B\uA68D\uA68F\uA691\uA693\uA695\uA697\uA699\uA69B\uA723\uA725\uA727\uA729\uA72B\uA72D\uA72F-\uA731\uA733\uA735\uA737\uA739\uA73B\uA73D\uA73F\uA741\uA743\uA745\uA747\uA749\uA74B\uA74D\uA74F\uA751\uA753\uA755\uA757\uA759\uA75B\uA75D\uA75F\uA761\uA763\uA765\uA767\uA769\uA76B\uA76D\uA76F\uA771-\uA778\uA77A\uA77C\uA77F\uA781\uA783\uA785\uA787\uA78C\uA78E\uA791\uA793-\uA795\uA797\uA799\uA79B\uA79D\uA79F\uA7A1\uA7A3\uA7A5\uA7A7\uA7A9\uA7B5\uA7B7\uA7FA\uAB30-\uAB5A\uAB60-\uAB65\uAB70-\uABBF\uFB00-\uFB06\uFB13-\uFB17\uFF41-\uFF5A]
 / [\u02B0-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0374\u037A\u0559\u0640\u06E5-\u06E6\u07F4-\u07F5\u07FA\u081A\u0824\u0828\u0971\u0E46\u0EC6\u10FC\u17D7\u1843\u1AA7\u1C78-\u1C7D\u1D2C-\u1D6A\u1D78\u1D9B-\u1DBF\u2071\u207F\u2090-\u209C\u2C7C-\u2C7D\u2D6F\u2E2F\u3005\u3031-\u3035\u303B\u309D-\u309E\u30FC-\u30FE\uA015\uA4F8-\uA4FD\uA60C\uA67F\uA69C-\uA69D\uA717-\uA71F\uA770\uA788\uA7F8-\uA7F9\uA9CF\uA9E6\uAA70\uAADD\uAAF3-\uAAF4\uAB5C-\uAB5F\uFF70\uFF9E-\uFF9F]
 / [\u00AA\u00BA\u01BB\u01C0-\u01C3\u0294\u05D0-\u05EA\u05F0-\u05F2\u0620-\u063F\u0641-\u064A\u066E-\u066F\u0671-\u06D3\u06D5\u06EE-\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u0800-\u0815\u0840-\u0858\u08A0-\u08B4\u0904-\u0939\u093D\u0950\u0958-\u0961\u0972-\u0980\u0985-\u098C\u098F-\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC-\u09DD\u09DF-\u09E1\u09F0-\u09F1\u0A05-\u0A0A\u0A0F-\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32-\u0A33\u0A35-\u0A36\u0A38-\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2-\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0-\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F-\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32-\u0B33\u0B35-\u0B39\u0B3D\u0B5C-\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99-\u0B9A\u0B9C\u0B9E-\u0B9F\u0BA3-\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C60-\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0-\u0CE1\u0CF1-\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32-\u0E33\u0E40-\u0E45\u0E81-\u0E82\u0E84\u0E87-\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA-\u0EAB\u0EAD-\u0EB0\u0EB2-\u0EB3\u0EBD\u0EC0-\u0EC4\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065-\u1066\u106E-\u1070\u1075-\u1081\u108E\u10D0-\u10FA\u10FD-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17DC\u1820-\u1842\u1844-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE-\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C77\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5-\u1CF6\u2135-\u2138\u2D30-\u2D67\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u3006\u303C\u3041-\u3096\u309F\u30A1-\u30FA\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FD5\uA000-\uA014\uA016-\uA48C\uA4D0-\uA4F7\uA500-\uA60B\uA610-\uA61F\uA62A-\uA62B\uA66E\uA6A0-\uA6E5\uA78F\uA7F7\uA7FB-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9E0-\uA9E4\uA9E7-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA6F\uAA71-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5-\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADC\uAAE0-\uAAEA\uAAF2\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uABC0-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40-\uFB41\uFB43-\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF66-\uFF6F\uFF71-\uFF9D\uFFA0-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]
 / [\u01C5\u01C8\u01CB\u01F2\u1F88-\u1F8F\u1F98-\u1F9F\u1FA8-\u1FAF\u1FBC\u1FCC\u1FFC]
 / [\u0041-\u005A\u00C0-\u00D6\u00D8-\u00DE\u0100\u0102\u0104\u0106\u0108\u010A\u010C\u010E\u0110\u0112\u0114\u0116\u0118\u011A\u011C\u011E\u0120\u0122\u0124\u0126\u0128\u012A\u012C\u012E\u0130\u0132\u0134\u0136\u0139\u013B\u013D\u013F\u0141\u0143\u0145\u0147\u014A\u014C\u014E\u0150\u0152\u0154\u0156\u0158\u015A\u015C\u015E\u0160\u0162\u0164\u0166\u0168\u016A\u016C\u016E\u0170\u0172\u0174\u0176\u0178-\u0179\u017B\u017D\u0181-\u0182\u0184\u0186-\u0187\u0189-\u018B\u018E-\u0191\u0193-\u0194\u0196-\u0198\u019C-\u019D\u019F-\u01A0\u01A2\u01A4\u01A6-\u01A7\u01A9\u01AC\u01AE-\u01AF\u01B1-\u01B3\u01B5\u01B7-\u01B8\u01BC\u01C4\u01C7\u01CA\u01CD\u01CF\u01D1\u01D3\u01D5\u01D7\u01D9\u01DB\u01DE\u01E0\u01E2\u01E4\u01E6\u01E8\u01EA\u01EC\u01EE\u01F1\u01F4\u01F6-\u01F8\u01FA\u01FC\u01FE\u0200\u0202\u0204\u0206\u0208\u020A\u020C\u020E\u0210\u0212\u0214\u0216\u0218\u021A\u021C\u021E\u0220\u0222\u0224\u0226\u0228\u022A\u022C\u022E\u0230\u0232\u023A-\u023B\u023D-\u023E\u0241\u0243-\u0246\u0248\u024A\u024C\u024E\u0370\u0372\u0376\u037F\u0386\u0388-\u038A\u038C\u038E-\u038F\u0391-\u03A1\u03A3-\u03AB\u03CF\u03D2-\u03D4\u03D8\u03DA\u03DC\u03DE\u03E0\u03E2\u03E4\u03E6\u03E8\u03EA\u03EC\u03EE\u03F4\u03F7\u03F9-\u03FA\u03FD-\u042F\u0460\u0462\u0464\u0466\u0468\u046A\u046C\u046E\u0470\u0472\u0474\u0476\u0478\u047A\u047C\u047E\u0480\u048A\u048C\u048E\u0490\u0492\u0494\u0496\u0498\u049A\u049C\u049E\u04A0\u04A2\u04A4\u04A6\u04A8\u04AA\u04AC\u04AE\u04B0\u04B2\u04B4\u04B6\u04B8\u04BA\u04BC\u04BE\u04C0-\u04C1\u04C3\u04C5\u04C7\u04C9\u04CB\u04CD\u04D0\u04D2\u04D4\u04D6\u04D8\u04DA\u04DC\u04DE\u04E0\u04E2\u04E4\u04E6\u04E8\u04EA\u04EC\u04EE\u04F0\u04F2\u04F4\u04F6\u04F8\u04FA\u04FC\u04FE\u0500\u0502\u0504\u0506\u0508\u050A\u050C\u050E\u0510\u0512\u0514\u0516\u0518\u051A\u051C\u051E\u0520\u0522\u0524\u0526\u0528\u052A\u052C\u052E\u0531-\u0556\u10A0-\u10C5\u10C7\u10CD\u13A0-\u13F5\u1E00\u1E02\u1E04\u1E06\u1E08\u1E0A\u1E0C\u1E0E\u1E10\u1E12\u1E14\u1E16\u1E18\u1E1A\u1E1C\u1E1E\u1E20\u1E22\u1E24\u1E26\u1E28\u1E2A\u1E2C\u1E2E\u1E30\u1E32\u1E34\u1E36\u1E38\u1E3A\u1E3C\u1E3E\u1E40\u1E42\u1E44\u1E46\u1E48\u1E4A\u1E4C\u1E4E\u1E50\u1E52\u1E54\u1E56\u1E58\u1E5A\u1E5C\u1E5E\u1E60\u1E62\u1E64\u1E66\u1E68\u1E6A\u1E6C\u1E6E\u1E70\u1E72\u1E74\u1E76\u1E78\u1E7A\u1E7C\u1E7E\u1E80\u1E82\u1E84\u1E86\u1E88\u1E8A\u1E8C\u1E8E\u1E90\u1E92\u1E94\u1E9E\u1EA0\u1EA2\u1EA4\u1EA6\u1EA8\u1EAA\u1EAC\u1EAE\u1EB0\u1EB2\u1EB4\u1EB6\u1EB8\u1EBA\u1EBC\u1EBE\u1EC0\u1EC2\u1EC4\u1EC6\u1EC8\u1ECA\u1ECC\u1ECE\u1ED0\u1ED2\u1ED4\u1ED6\u1ED8\u1EDA\u1EDC\u1EDE\u1EE0\u1EE2\u1EE4\u1EE6\u1EE8\u1EEA\u1EEC\u1EEE\u1EF0\u1EF2\u1EF4\u1EF6\u1EF8\u1EFA\u1EFC\u1EFE\u1F08-\u1F0F\u1F18-\u1F1D\u1F28-\u1F2F\u1F38-\u1F3F\u1F48-\u1F4D\u1F59\u1F5B\u1F5D\u1F5F\u1F68-\u1F6F\u1FB8-\u1FBB\u1FC8-\u1FCB\u1FD8-\u1FDB\u1FE8-\u1FEC\u1FF8-\u1FFB\u2102\u2107\u210B-\u210D\u2110-\u2112\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u2130-\u2133\u213E-\u213F\u2145\u2183\u2C00-\u2C2E\u2C60\u2C62-\u2C64\u2C67\u2C69\u2C6B\u2C6D-\u2C70\u2C72\u2C75\u2C7E-\u2C80\u2C82\u2C84\u2C86\u2C88\u2C8A\u2C8C\u2C8E\u2C90\u2C92\u2C94\u2C96\u2C98\u2C9A\u2C9C\u2C9E\u2CA0\u2CA2\u2CA4\u2CA6\u2CA8\u2CAA\u2CAC\u2CAE\u2CB0\u2CB2\u2CB4\u2CB6\u2CB8\u2CBA\u2CBC\u2CBE\u2CC0\u2CC2\u2CC4\u2CC6\u2CC8\u2CCA\u2CCC\u2CCE\u2CD0\u2CD2\u2CD4\u2CD6\u2CD8\u2CDA\u2CDC\u2CDE\u2CE0\u2CE2\u2CEB\u2CED\u2CF2\uA640\uA642\uA644\uA646\uA648\uA64A\uA64C\uA64E\uA650\uA652\uA654\uA656\uA658\uA65A\uA65C\uA65E\uA660\uA662\uA664\uA666\uA668\uA66A\uA66C\uA680\uA682\uA684\uA686\uA688\uA68A\uA68C\uA68E\uA690\uA692\uA694\uA696\uA698\uA69A\uA722\uA724\uA726\uA728\uA72A\uA72C\uA72E\uA732\uA734\uA736\uA738\uA73A\uA73C\uA73E\uA740\uA742\uA744\uA746\uA748\uA74A\uA74C\uA74E\uA750\uA752\uA754\uA756\uA758\uA75A\uA75C\uA75E\uA760\uA762\uA764\uA766\uA768\uA76A\uA76C\uA76E\uA779\uA77B\uA77D-\uA77E\uA780\uA782\uA784\uA786\uA78B\uA78D\uA790\uA792\uA796\uA798\uA79A\uA79C\uA79E\uA7A0\uA7A2\uA7A4\uA7A6\uA7A8\uA7AA-\uA7AD\uA7B0-\uA7B4\uA7B6\uFF21-\uFF3A]

/* Token "token"
  //= SpecialMacro
  = Macro
  /// full_comment
  / Group
  / AlignmentTab
  / Number
  /// Whitespace
  /// Punctuation
 */


TimesSign
  = '*'
  / '\\cdot'
  / '\\times'

Number "number"
  = Integer
  / Float

SingleDigitIdentifier "single digit identifier"
  = c:Char {
    var n = new MPIdentifier(c);
    n.position = location();
    return n;}
  
SingleDigitInteger "single digit integer"
  = d:Digit {
    var n = new MPInteger(parseInt(d, 10));
    n.position = location();
    return n;}

// Single char or integer
AlphaNumerical //"alphanumerical"
  = c:Char {
    var n = new MPIdentifier(c);
    n.position = location();
    return n;}
  / d:Digit {
    var n = new MPInteger(parseInt(d, 10));
    n.position = location();
    return n;}


Environment
  = MatrixEnvironment

MatrixEnvironment "matrix environment"
  = BeginEnv
    BeginGroup
    env:MatrixEnvName
    EndGroup
    //env_comment:sameline_comment?
    _?
    body:(
      head:MatrixRow tail:(_? Escape Escape _? MatrixRow)* {
          return buildList(head, tail, 4);
      }
    )?
    _?
    EndEnv
    BeginGroup
    env2:MatrixEnvName
    EndGroup
    & { return env === env2} // Ensure that the environment is the same
    {
      var n = new MPMatrix(env, body);
      n.position = location();
      return n;
    }

MatrixRow
  = head:EqualityExpression tail:(_? AlignmentTab _? EqualityExpression)* {
    return buildList(head, tail, 3);
  }

BeginEnv = Escape "begin"
EndEnv = Escape "end"

MatrixEnvName
  = 'matrix'
  / 'pmatrix'
  / 'bmatrix'
  / 'Bmatrix'
  / 'vmatrix'
  / 'Vmatrix'
  / 'smallmatrix'

// catcode 0
Escape "escape" = "\\"
// catcode 1
BeginGroup = "{"
// catcode 2
EndGroup = "}"
// catcode 3
math_shift = "$"
// catcode 4
AlignmentTab = "&"
// catcode 5 (linux, os x, windows)
Newline "newline"
  = !"\r" "\n"
  / "\r"
  / "\r\n"
// catcode 6
MacroParameter = "#"
// catcode 7
Superscript = "^"
// catcode 8
Subscript = "_"
// catcode 9
Ignore = "\0"
// catcode 10
SP "Whitespace" = [ \t]+ { return " "; }
// catcode 11
Char "letter" = c:[a-zA-Z]
// catcode 12 (other)
Digit "digit" = n:[0-9]
// catcode 12
Punctuation "Punctuation" = p:[.,;:\-\*/()!?=+<>\[\]]
// catcode 14, including the newline
CommentStart = "%"


EOL = Newline / !.
