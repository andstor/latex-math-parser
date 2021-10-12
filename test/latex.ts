import { expect } from "chai";
import { parse, SyntaxError } from '../src/parser.js';
import { MPStatement, MPOperation, MPInteger, MPRoot } from '../src/MP_classes.js';

describe('latex parser should parse', () => {

   it('pemdas 1', () => {
      const input = 'sin(1+2)*3-1';
      const ast: MPRoot = parse(input, undefined);
      let debug = ast.debugPrint(input);
      console.log(debug);
      
      /*
      expect(ast.items.length).to.equal(1);
      const statement = ast.items[0] as MPStatement;
      expect(statement.flags.length).to.equal(0);

      const firstop = statement.statement as MPOperation;
      expect(firstop.op).to.equal('+');

      const secondop = firstop.rhs as MPOperation;
      expect(secondop.op).to.equal('*');

      const first = firstop.lhs as MPInteger;
      const second = secondop.lhs as MPInteger;
      const third = secondop.rhs as MPInteger;

      expect(first.value).to.equal(1);
      expect(second.value).to.equal(2);
      expect(third.value).to.equal(3);
      */
   });

})