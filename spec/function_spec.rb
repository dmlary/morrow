require 'facets/string/indent'

describe Morrow::Function do
  shared_examples 'various function' do

    # function is safe to run
    shared_examples 'no error' do
      it 'will not raise an error' do
        expect { function }.to_not raise_error
      end
      it 'will freeze the instance' do
        expect(function).to be_frozen
      end
    end

    # syntax error in the ruby syntax
    shared_examples 'syntax error' do
      it 'will raise Parser::SyntaxError' do
        expect { function }
            .to raise_error(Parser::SyntaxError)
      end
    end

    # calling a prohibitied method
    shared_examples 'method error' do
      it 'will raise a ProhibitedMethod error' do
        expect { function }
            .to raise_error(described_class::ProhibitedMethod)
      end
    end

    # using an unsupported ruby feature (const, backticks)
    shared_examples 'node error' do
      it 'will raise a ProhibitedNodeType error' do
        expect { function }
            .to raise_error(described_class::ProhibitedNodeType)
      end
    end

    # the function doesn't have the correct block syntax
    shared_examples 'block error' do
      it 'will raise an UnexpectedNode error' do
        expect { function }
            .to raise_error(described_class::UnexpectedNode)
      end
    end

    # All of the test cases, broken down into description, code, and the
    # expected result.
    [
      # invalid syntax
      { desc: 'no block body provided', code: '1', expect: 'block error' },

      # permitted base types
      { desc: 'Integer', code: '{ 42 }', expect: 'no error' },
      { desc: 'Float', code: '{ 42.0 }', expect: 'no error' },
      { desc: 'inclusive Range', code: '{ 1..10 }', expect: 'no error' },
      { desc: 'exclusive Range', code: '{ 1...10 }', expect: 'no error' },
      { desc: 'complex function', code: '{ 1 + (1 + 1) }', expect: 'no error' },

      { desc: 'addition', code: '{ 1 + 1 }', expect: 'no error' },
      { desc: 'subtraction', code: '{ 1 - 1 }', expect: 'no error' },
      { desc: 'multiplication', code: '{ 1 * 1 }', expect: 'no error' },
      { desc: 'division', code: '{ 1 / 1 }', expect: 'no error' },
      { desc: 'exponentiation', code: '{ 1 ** 1 }', expect: 'no error' },
      { desc: 'argument', code: '{ |a| a }', expect: 'no error' },
      { desc: 'parens', code: '{ 1 + (1 + 1) }', expect: 'no error' },

      { desc: '>' , code: '{ 1 > 1 }', expect: 'no error' },
      { desc: '>=' , code: '{ 1 >= 1 }', expect: 'no error' },
      { desc: '<' , code: '{ 1 < 1 }', expect: 'no error' },
      { desc: '<=' , code: '{ 1 >= 1 }', expect: 'no error' },

      { desc: 'conditional function',
        expect: 'no error',
        code: <<~CODE },
          do |l|
            case l
            when 0..10
              l * 5
            else
              l * 10
            end
          end
        CODE
      { desc: 'ternary operator conditional function',
        expect: 'no error',
        code: '{ |l| l > 50 ? l * 1.5 : l }' },


      # denied base types
      { desc: 'nil', code: '{ nil }', expect: 'node error' },
      { desc: 'true', code: '{ true }', expect: 'node error' },
      { desc: 'false', code: '{ false }', expect: 'node error' },
      { desc: 'Symbol', code: '{ :symbol }', expect: 'node error' },
      { desc: 'String', code: '{ "wolf" }', expect: 'node error' },
      { desc: 'Array', code: '{ [] }', expect: 'node error' },
      { desc: 'Hash', code: '{ {} }', expect: 'node error' },

      # denied variables
      { desc: 'instance variable', code: '{ @var }', expect: 'node error' },
      { desc: 'class variable', code: '{ @@var }', expect: 'node error' },
      { desc: 'global variable', code: '{ $var }', expect: 'node error' },

      # constants are not permitted; makes everything much easier to
      # implement scripting safely.
      { desc: 'constant Morrow', code: '{ Morrow }', expect: 'node error' },
      { desc: 'constant Morrow::Helpers',
        code: '{ Morrow::Helpers }',
        expect: 'node error' },
      { desc: 'constant File', code: '{ File }', expect: 'node error' },
      { desc: 'constant Kernel', code: '{ Kernel }', expect: 'node error' },
      { desc: 'constant Object', code: '{ Object }', expect: 'node error' },

      # assignment
      { desc: 'assign local var',
        code: '{ local = 1 }',
        expect: 'no error' },
      { desc: 'assign instance var',
        code: '{ @instance_var = true }',
        expect: 'node error' },
      { desc: 'assign class var',
        code: '{ @@class_var = true }',
        expect: 'node error' },
      { desc: 'assign constant',
        code: '{ Constant = true }',
        expect: 'node error' },
      { desc: 'assign global variable',
        code: '{ $global_var = true }',
        expect: 'node error' },

      { desc: 'multiple assignment to local variables',
        code: '{ a,b = [1,2] }',
        expect: 'node error' },
      { desc: 'operation assignment to local var',
        code: '{ a += 1 }',
        expect: 'no error' },
      { desc: 'logical-and operator assignment on local var',
        code: '{ a &&= 1 }',
        expect: 'no error' },
      { desc: 'logical-or operator assignment on local var',
        code: '{ a ||= 1 }',
        expect: 'no error' },

      { desc: 'accessing local variable',
        code: '{ a = 1; a }',
        expect: 'no error' },

      # module & class creation/modification
      { desc: 'module creation/modification',
        code: '{ module Meep; end }',
        expect: 'node error' },
      { desc: 'class creation/modification',
        code: '{ class Meep; end }',
        expect: 'node error' },
      { desc: 'singleton class',
        expect: 'node error',
        code: <<~CODE
          do
            class << self
              def breakout
                # other code
              end
            end
          end
        CODE
      },

      # method (un)definition
      { desc: 'define instance method',
        expect: 'node error',
        code: '{ def xxx; end }' },
      { desc: 'undefine instance method',
        expect: 'node error',
        code: '{ undef :xxx }' },
      { desc: 'define singleton method',
        expect: 'node error',
        code: '{ def self.xxx; end }' },

      # aliasing
      { desc: 'method aliasing',
        expect: 'node error',
        code: '{ alias xxx yyy }' },

      ## flow control
      # if
      { desc: 'if statement',
        code: '{ if 1; 1; end }',
        expect: 'no error' },
      { desc: 'tail if statement',
        code: '{ 1 if 1 }',
        expect: 'no error' },
      { desc: 'if-else statement',
        code: '{ if 1; 1; else; 2; end }',
        expect: 'no error' },
      { desc: 'if-elsif statement',
        code: '{ if 1; 1; elsif 1; 2; end }',
        expect: 'no error' },

      # unless
      { desc: 'unless statement',
        code: '{ unless 1; 1; end }',
        expect: 'no error' },
      { desc: 'tail unless statement',
        code: '{ 1 unless 1 }',
        expect: 'no error' },
      { desc: 'unless-else statement',
        code: '{ unless 1; 1; else; 2; end }',
        expect: 'no error' },

      # case
      { desc: 'case statement',
        expect: 'no error',
        code: <<~CODE
          do
            case 1
            when 1
              3
            when 2
              4
            else
              5
            end
          end
        CODE
      },

      # while/until
      { desc: 'tail while statement',
        expect: 'node error',
        code: <<~CODE
          do
            while 1
              3
            end
          end
        CODE
      },
      { desc: 'tail while statement',
        expect: 'node error',
        code: '{ 3 while 1 }' },
      { desc: 'tail until statement',
        expect: 'node error',
        code: <<~CODE
          do
            until 1
              3
            end
          end
        CODE
      },
      { desc: 'tail until statement',
        expect: 'node error',
        code: '{ 3 until 1 }' },

      # next, break, and continue
      { desc: 'next', code: '{ next }', expect: 'no error' },
      { desc: 'break', code: '{ break }', expect: 'node error' },
      { desc: 'return', code: '{ return }', expect: 'node error' },

      # or, and, not
      { desc: 'or', code: '{ 1 or 0 }', expect: 'no error' },
      { desc: 'and', code: '{ 1 and 0 }', expect: 'no error' },
      { desc: 'not', code: '{ not 0 }', expect: 'no error' },

      # sending
      { desc: 'send method to receiver',
        expect: 'method error',
        code: '{ |a| a.eval(5) }' },
      { desc: 'sending non-whitelist command with no receiver',
        code: '{ |v| eval(v) }',
        expect: 'method error' },

      # try to rescue some stugg
      { desc: 'begin/rescue block with retry',
        expect: 'node error',
        code: <<~'CODE'
          do
            3
          rescue
            retry
          end
        CODE
      },
      { desc: 'raise an exception',
        expect: 'method error',
        code: '{ raise "this is an error" }' },

      # regression prevention
      { desc: 'Symbol#to_proc',
        expect: 'method error',
        code: '{ :send.to_proc.call(:eval, :puts, "hello world") }' },
      { desc: 'back-tick shell command',
        expect: 'node error',
        code: '{ `ls` }' },
      { desc: '%x{} shell command',
        expect: 'node error',
        code: '{ %x{ls} }' },
      { desc: 'system() command',
        expect: 'method error',
        code: '{ system("ls") }' },
      { desc: 'exec() command',
        expect: 'method error',
        code: '{ exec("ls") }' },
      { desc: 'File.open()',
        expect: 'method error',
        code: '{ File.open("/etc/passwd") }' },
      { desc: 'eval',
        expect: 'method error',
        code: '{ eval("File") }' },
      { desc: 'instance_eval',
        expect: 'method error',
        code: '{ instance_eval("File") }' },
      { desc: 'send()',
        expect: 'method error',
        code: '{ send(:eval, "File") }' },
      { desc: 'require()',
        expect: 'method error',
        code: '{ |x| require(x) }' },
      { desc: 'open()',
        expect: 'method error',
        code: '{ |x| open(x) }' },

      # syntax error
      { desc: 'syntax error', code: '{ 1 = 2 }', expect: 'syntax error' },
    ].each do |p|
      desc = p[:desc]
      code = p[:code]
      expect = p[:expect]
      context(desc) do
        let(:source) { code }
        include_examples(expect)
      end
    end
  end

  describe '#initialize' do
    let(:function) { described_class.new(source) }
    include_examples 'various function'
  end

  describe 'loaded from yaml' do
    let(:function) do
      if source
        YAML.load("!func |\n#{source.indent(2)}")
      else
        YAML.load("!func ")
      end
    end
    include_examples 'various function'
  end

  describe '#call()' do
    [ { desc: 'no arguments',
        func: '{ 1 }',
        args: [],
        result: 1 },
      { desc: 'one argument',
        func: '{ |v| v * 2 }',
        args: [ 2 ],
        result: 4 },
      { desc: 'too many arguments passed',
        func: '{ |v| v }',
        args: [ 1, 2, 3 ],
        result: 1 },
      { desc: 'insufficient arguments passed',
        func: '{ |a,b| b }',
        args: [ 1 ],
        result: nil },
    ].each do |t|
      describe t[:desc] do
        it 'will return %s' % t[:result].inspect do
          func = described_class.new(t[:func])
          expect(func.call(*t[:args])).to eq(t[:result])
        end
      end
    end
  end
end
