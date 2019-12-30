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
        { desc: 'nil', code: 'nil', include: 'no error' },
        { desc: 'true', code: 'true', include: 'no error' },
        { desc: 'false', code: 'false', include: 'no error' },
        { desc: 'Symbol', code: ':symbol', include: 'no error' },
        { desc: 'Integer', code: '47', include: 'no error' },
        { desc: 'Float', code: '47.0', include: 'no error' },
        { desc: 'String', code: '"wolf"', include: 'no error' },
        { desc: 'Array', code: '[]', include: 'no error' },
        { desc: 'Hash', code: '{}', include: 'no error' },
        { desc: 'inclusive Range', code: '1..10', include: 'no error' },
        { desc: 'exclusive Range', code: '1...10', include: 'no error' },

        # constants are not permitted; makes everything much easier to
        # implement scripting safely.
        { desc: 'constant World', code: 'World', include: 'raise error' },
        { desc: 'constant World::Helpers',
          code: 'World::Helpers',
          include: 'raise error' },
        { desc: 'constant File', code: 'File', include: 'raise error' },
        { desc: 'constant Kernel', code: 'Kernel', include: 'raise error' },
        { desc: 'constant Object', code: 'Object', include: 'raise error' },
        { desc: 'constant Script', code: 'Script', include: 'raise error' },

        # assignment
        { desc: 'assign local var',
          code: 'local = true',
          include: 'no error' },
        { desc: 'assign instance var',
          code: '@instance_var = true',
          include: 'raise error' },
        { desc: 'assign class var',
          code: '@@class_var = true',
          include: 'raise error' },
        { desc: 'assign constant',
          code: 'Constant = true',
          include: 'raise error' },
        { desc: 'assign global variable',
          code: '$global_var = true',
          include: 'raise error' },

        { desc: 'multiple assignment to local variables',
          code: 'a,b = [1,2]',
          include: 'no error' },
        { desc: 'operation assignment to local var',
          code: 'a += 1',
          include: 'no error' },
        { desc: 'logical-and operator assignment on local var',
          code: 'a &&= 1',
          include: 'no error' },
        { desc: 'logical-or operator assignment on local var',
          code: 'a ||= 1',
          include: 'no error' },

        { desc: 'assign array index',
          code: '[][5] = true',
          include: 'no error' },
        { desc: 'access array index',
          code: '[][5]',
          include: 'no error' },

        { desc: 'assign hash index',
          code: '{}[5] = true',
          include: 'no error' },
        { desc: 'access hash index',
          code: '{}[5]',
          include: 'no error' },

        { desc: 'accessing local variable',
          code: 'a = true; a',
          include: 'no error' },

        # module & class creation/modification
        { desc: 'module creation/modification',
          code: 'module Meep; end',
          include: 'raise error' },
        { desc: 'class creation/modification',
          code: 'class Meep; end',
          include: 'raise error' },
        { desc: 'singleton class',
          include: 'raise error',
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
          include: 'raise error',
          code: 'def xxx; end' },
        { desc: 'undefine instance method',
          include: 'raise error',
          code: 'undef :xxx' },
        { desc: 'define singleton method',
          include: 'raise error',
          code: 'def self.xxx; end' },

        # aliasing
        { desc: 'method aliasing',
          include: 'raise error',
          code: 'alias xxx yyy' },

        ## flow control
        # if
        { desc: 'if statement',
          code: 'if true; true; end',
          include: 'no error' },
        { desc: 'tail if statement',
          code: 'true if true',
          include: 'no error' },
        { desc: 'if-else statement',
          code: 'if true; true; else; false; end',
          include: 'no error' },
        { desc: 'if-elsif statement',
          code: 'if true; true; elsif true; false; end',
          include: 'no error' },

        # unless
        { desc: 'unless statement',
          code: 'unless true; true; end',
          include: 'no error' },
        { desc: 'tail unless statement',
          code: 'true unless true',
          include: 'no error' },
        { desc: 'unless-else statement',
          code: 'unless true; true; else; false; end',
          include: 'no error' },

        # case
        { desc: 'case statement',
          include: 'no error',
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
          include: 'no error',
          code: <<~CODE
            while true
              3
            end
          CODE
        },
        { desc: 'tail while statement',
          include: 'no error',
          code: '3 while true' },
        { desc: 'tail until statement',
          include: 'no error',
          code: <<~CODE
            until true
              3
            end
          CODE
        },
        { desc: 'tail until statement',
          include: 'no error',
          code: '3 until true' },

        # next, break, and continue
        { desc: 'next', code: 'next', include: 'no error' },
        { desc: 'break', code: 'break', include: 'no error' },
        { desc: 'return', code: 'return', include: 'no error' },

        # or, and, not
        { desc: 'or', code: 'true or false', include: 'no error' },
        { desc: 'and', code: 'true and false', include: 'no error' },
        { desc: 'not', code: 'not false', include: 'no error' },

        # sending
        #
        { desc: 'send whitelist command to receiver',
          include: 'no error',
          code: '[1,2,3].map' },
        { desc: 'sending whitelist command with no receiver',
          code: 'get_component("wolf", :damage)',
          include: 'no error' },
        { desc: 'sending whitelisted command a block',
          include: 'no error',
          code: '[].map { |v| v + 1 }'},

        { desc: 'send non-whitelist command to receiver',
          include: 'raise error',
          code: 'a.eval("File")' },
        { desc: 'sending non-whitelist command with no receiver',
          code: 'eval("File")',
          include: 'raise error' },

        # regression prevention
        { desc: 'Symbol#to_proc',
          include: 'raise error',
          code: ':send.to_proc.call(:eval, :puts, "hello world")' },
        { desc: 'back-tick shell command',
          include: 'raise error',
          code: '`ls`' },
        { desc: '%x{} shell command',
          include: 'raise error',
          code: '%x{ls}' },
        { desc: 'system() command',
          include: 'raise error',
          code: 'system("ls")' },
        { desc: 'exec() command',
          include: 'raise error',
          code: 'exec("ls")' },
        { desc: 'File.open()',
          include: 'raise error',
          code: 'File.open("/etc/passwd")' },
        { desc: 'eval',
          include: 'raise error',
          code: 'eval("File")' },
        { desc: 'instance_eval',
          include: 'raise error',
          code: 'instance_eval("File")' },
        { desc: 'send()',
          include: 'raise error',
          code: 'send(:eval, "File")' },
        { desc: 'require()',
          include: 'raise error',
          code: 'require("pry")' },

        # complex examples
        { desc: 'teleporter enter',
          include: 'no error',
          code: <<~CODE
            porter = get_component(entity, :teleporter) or return
            port = get_component!(actor, :teleport)
            port[:dest] = porter[:dest]
            port[:at] = now + porter[:delay]
          CODE
        },
        { desc: 'teleporter exit',
          include: 'no error',
          code: <<~CODE
            remove_component(actor, :teleport)
          CODE
        },
    ].each do |desc: nil, code: nil, include: nil|
      context(desc) do
        let(:script) { Script.new(code) }
        include_examples(include)
      end
    end
  end
end
