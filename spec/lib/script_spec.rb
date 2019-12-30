describe Script do
  describe '#safe!' do
    shared_examples 'no error' do
      it 'will not raise an error' do
        expect { script.safe! }.to_not raise_error
      end
    end

    shared_examples 'raise error' do
      it 'will raise an UnsafeScript error' do
        expect { script.safe! }.to raise_error(Script::UnsafeScript)
      end
    end

    [
        # base types
        { desc: 'nil', code: 'nil', expect: 'no error' },
        { desc: 'true', code: 'true', expect: 'no error' },
        { desc: 'false', code: 'false', expect: 'no error' },
        { desc: 'Symbol', code: ':symbol', expect: 'no error' },
        { desc: 'Integer', code: '47', expect: 'no error' },
        { desc: 'Float', code: '47.0', expect: 'no error' },
        { desc: 'String', code: '"wolf"', expect: 'no error' },
        { desc: 'Array', code: '[]', expect: 'no error' },
        { desc: 'Hash', code: '{}', expect: 'no error' },
        { desc: 'inclusive Range', code: '1..10', expect: 'no error' },
        { desc: 'exclusive Range', code: '1...10', expect: 'no error' },
        { desc: 'interpolated String', expect: 'no error',
          code: 'x = 3; "wolf #{x}"' },
        { desc: 'format String', expect: 'no error',
          code: 'x = 3; "wolf %d" % x' },

        # constants are not permitted; makes everything much easier to
        # implement scripting safely.
        { desc: 'constant World', code: 'World', expect: 'raise error' },
        { desc: 'constant World::Helpers',
          code: 'World::Helpers',
          expect: 'raise error' },
        { desc: 'constant File', code: 'File', expect: 'raise error' },
        { desc: 'constant Kernel', code: 'Kernel', expect: 'raise error' },
        { desc: 'constant Object', code: 'Object', expect: 'raise error' },
        { desc: 'constant Script', code: 'Script', expect: 'raise error' },

        # assignment
        { desc: 'assign local var',
          code: 'local = true',
          expect: 'no error' },
        { desc: 'assign instance var',
          code: '@instance_var = true',
          expect: 'raise error' },
        { desc: 'assign class var',
          code: '@@class_var = true',
          expect: 'raise error' },
        { desc: 'assign constant',
          code: 'Constant = true',
          expect: 'raise error' },
        { desc: 'assign global variable',
          code: '$global_var = true',
          expect: 'raise error' },

        { desc: 'multiple assignment to local variables',
          code: 'a,b = [1,2]',
          expect: 'no error' },
        { desc: 'operation assignment to local var',
          code: 'a += 1',
          expect: 'no error' },
        { desc: 'logical-and operator assignment on local var',
          code: 'a &&= 1',
          expect: 'no error' },
        { desc: 'logical-or operator assignment on local var',
          code: 'a ||= 1',
          expect: 'no error' },

        { desc: 'assign array index',
          code: '[][5] = true',
          expect: 'no error' },
        { desc: 'access array index',
          code: '[][5]',
          expect: 'no error' },

        { desc: 'assign hash index',
          code: '{}[5] = true',
          expect: 'no error' },
        { desc: 'access hash index',
          code: '{}[5]',
          expect: 'no error' },

        { desc: 'accessing local variable',
          code: 'a = true; a',
          expect: 'no error' },

        # module & class creation/modification
        { desc: 'module creation/modification',
          code: 'module Meep; end',
          expect: 'raise error' },
        { desc: 'class creation/modification',
          code: 'class Meep; end',
          expect: 'raise error' },
        { desc: 'singleton class',
          expect: 'raise error',
          code: <<~CODE
            class << self
              def breakout
                # other code
              end
            end
          CODE
        },

        # method (un)definition
        { desc: 'define instance method',
          expect: 'raise error',
          code: 'def xxx; end' },
        { desc: 'undefine instance method',
          expect: 'raise error',
          code: 'undef :xxx' },
        { desc: 'define singleton method',
          expect: 'raise error',
          code: 'def self.xxx; end' },

        # aliasing
        { desc: 'method aliasing',
          expect: 'raise error',
          code: 'alias xxx yyy' },

        ## flow control
        # if
        { desc: 'if statement',
          code: 'if true; true; end',
          expect: 'no error' },
        { desc: 'tail if statement',
          code: 'true if true',
          expect: 'no error' },
        { desc: 'if-else statement',
          code: 'if true; true; else; false; end',
          expect: 'no error' },
        { desc: 'if-elsif statement',
          code: 'if true; true; elsif true; false; end',
          expect: 'no error' },

        # unless
        { desc: 'unless statement',
          code: 'unless true; true; end',
          expect: 'no error' },
        { desc: 'tail unless statement',
          code: 'true unless true',
          expect: 'no error' },
        { desc: 'unless-else statement',
          code: 'unless true; true; else; false; end',
          expect: 'no error' },

        # case
        { desc: 'case statement',
          expect: 'no error',
          code: <<~CODE
            case true
            when true
              3
            when false
              4
            else
              5
            end
          CODE
        },

        # while/until
        { desc: 'tail while statement',
          expect: 'no error',
          code: <<~CODE
            while true
              3
            end
          CODE
        },
        { desc: 'tail while statement',
          expect: 'no error',
          code: '3 while true' },
        { desc: 'tail until statement',
          expect: 'no error',
          code: <<~CODE
            until true
              3
            end
          CODE
        },
        { desc: 'tail until statement',
          expect: 'no error',
          code: '3 until true' },

        # next, break, and continue
        { desc: 'next', code: 'next', expect: 'no error' },
        { desc: 'break', code: 'break', expect: 'no error' },
        { desc: 'return', code: 'return', expect: 'no error' },

        # or, and, not
        { desc: 'or', code: 'true or false', expect: 'no error' },
        { desc: 'and', code: 'true and false', expect: 'no error' },
        { desc: 'not', code: 'not false', expect: 'no error' },

        # sending
        #
        { desc: 'send whitelist command to receiver',
          expect: 'no error',
          code: '[1,2,3].map' },
        { desc: 'sending whitelist command with no receiver',
          code: 'get_component("wolf", :damage)',
          expect: 'no error' },
        { desc: 'sending whitelisted command a block',
          expect: 'no error',
          code: '[].map { |v| v + 1 }'},

        { desc: 'send non-whitelist command to receiver',
          expect: 'raise error',
          code: 'a.eval("File")' },
        { desc: 'sending non-whitelist command with no receiver',
          code: 'eval("File")',
          expect: 'raise error' },

        # regression prevention
        { desc: 'Symbol#to_proc',
          expect: 'raise error',
          code: ':send.to_proc.call(:eval, :puts, "hello world")' },
        { desc: 'back-tick shell command',
          expect: 'raise error',
          code: '`ls`' },
        { desc: '%x{} shell command',
          expect: 'raise error',
          code: '%x{ls}' },
        { desc: 'system() command',
          expect: 'raise error',
          code: 'system("ls")' },
        { desc: 'exec() command',
          expect: 'raise error',
          code: 'exec("ls")' },
        { desc: 'File.open()',
          expect: 'raise error',
          code: 'File.open("/etc/passwd")' },
        { desc: 'eval',
          expect: 'raise error',
          code: 'eval("File")' },
        { desc: 'instance_eval',
          expect: 'raise error',
          code: 'instance_eval("File")' },
        { desc: 'send()',
          expect: 'raise error',
          code: 'send(:eval, "File")' },
        { desc: 'require()',
          expect: 'raise error',
          code: 'require("pry")' },

        # teleporter examples
        { desc: 'teleporter enter',
          expect: 'no error',
          code: <<~CODE
            porter = get_component(entity, :teleporter) or return
            port = get_component!(actor, :teleport)
            port[:dest] = porter[:dest]
            port[:at] = now + porter[:delay]
          CODE
        },
        { desc: 'teleporter exit',
          expect: 'no error',
          code: 'remove_component(actor, :teleport)' },
    ].each do |desc: nil, code: nil, expect: nil|
      context(desc) do
        let(:script) { Script.new(code) }
        include_examples(expect)
      end
    end
  end
end
