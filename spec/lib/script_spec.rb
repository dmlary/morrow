describe Script do
  # various scripts
  #
  # This is a sampling of all the elements we support/reject in scripts.  This
  # shared example is used for #initialize, and yaml load to verify that the
  # scripts are safely handled under each condition.
  #
  shared_examples 'various scripts' do

    # script is safe to run
    shared_examples 'no error' do
      it 'will not raise an error' do
        expect { script }.to_not raise_error
      end
      it 'will freeze the instance' do
        expect(script).to be_frozen
      end
    end

    # syntax error in the ruby syntax
    shared_examples 'syntax error' do
      it 'will raise Parser::SyntaxError' do
        expect { script }
            .to raise_error(Parser::SyntaxError)
      end
    end

    # calling a prohibitied method
    shared_examples 'method error' do
      it 'will raise a ProhibitedMethod error' do
        expect { script }
            .to raise_error(Script::ProhibitedMethod)
      end
    end

    # using an unsupported ruby feature (const, backticks)
    shared_examples 'node error' do
      it 'will raise a ProhibitedNodeType error' do
        expect { script }
            .to raise_error(Script::ProhibitedNodeType)
      end
    end

    # All of the test cases, broken down into description, code, and the
    # expected result.
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
        { desc: 'constant World', code: 'World', expect: 'node error' },
        { desc: 'constant World::Helpers',
          code: 'World::Helpers',
          expect: 'node error' },
        { desc: 'constant File', code: 'File', expect: 'node error' },
        { desc: 'constant Kernel', code: 'Kernel', expect: 'node error' },
        { desc: 'constant Object', code: 'Object', expect: 'node error' },
        { desc: 'constant Script', code: 'Script', expect: 'node error' },

        # assignment
        { desc: 'assign local var',
          code: 'local = true',
          expect: 'no error' },
        { desc: 'assign instance var',
          code: '@instance_var = true',
          expect: 'node error' },
        { desc: 'assign class var',
          code: '@@class_var = true',
          expect: 'node error' },
        { desc: 'assign constant',
          code: 'Constant = true',
          expect: 'node error' },
        { desc: 'assign global variable',
          code: '$global_var = true',
          expect: 'node error' },

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
          expect: 'node error' },
        { desc: 'class creation/modification',
          code: 'class Meep; end',
          expect: 'node error' },
        { desc: 'singleton class',
          expect: 'node error',
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
          expect: 'node error',
          code: 'def xxx; end' },
        { desc: 'undefine instance method',
          expect: 'node error',
          code: 'undef :xxx' },
        { desc: 'define singleton method',
          expect: 'node error',
          code: 'def self.xxx; end' },

        # aliasing
        { desc: 'method aliasing',
          expect: 'node error',
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
          expect: 'method error',
          code: 'a.eval("File")' },
        { desc: 'sending non-whitelist command with no receiver',
          code: 'eval("File")',
          expect: 'method error' },

        # regression prevention
        { desc: 'Symbol#to_proc',
          expect: 'method error',
          code: ':send.to_proc.call(:eval, :puts, "hello world")' },
        { desc: 'back-tick shell command',
          expect: 'node error',
          code: '`ls`' },
        { desc: '%x{} shell command',
          expect: 'node error',
          code: '%x{ls}' },
        { desc: 'system() command',
          expect: 'method error',
          code: 'system("ls")' },
        { desc: 'exec() command',
          expect: 'method error',
          code: 'exec("ls")' },
        { desc: 'File.open()',
          expect: 'method error',
          code: 'File.open("/etc/passwd")' },
        { desc: 'eval',
          expect: 'method error',
          code: 'eval("File")' },
        { desc: 'instance_eval',
          expect: 'method error',
          code: 'instance_eval("File")' },
        { desc: 'send()', expect: 'method error',
          code: 'send(:eval, "File")' },
        { desc: 'require()', expect: 'method error', code: 'require("pry")' },
        { desc: 'open()', expect: 'method error', code: 'open("/etc/passwd")' },

        # teleporter examples
        { desc: 'teleporter enter',
          expect: 'no error',
          code: <<~'CODE'
            here = args[:here]
            unless porter = get_component(here, :teleporter)
              error "#{here} missing teleporter component"
              return
            end
            entity = args[:entity]
            port = get_component!(entity, :teleport)
            port[:dest] = porter[:dest]
            port[:at] = now + porter[:delay]
          CODE
        },
        { desc: 'teleporter exit',
          expect: 'no error',
          code: 'remove_component(args[:entity], :teleport)' },

        # syntax error
        { desc: 'syntax error', code: '1 = 2', expect: 'syntax error' },

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
    let(:script) { Script.new(source) }
    include_examples 'various scripts'
  end

  describe 'loaded from yaml' do
    let(:script) do
      if source
        YAML.load("!script |\n#{source.indent(2)}")
      else
        YAML.load("!script")
      end
    end
    include_examples 'various scripts'
  end

  describe '#call(config: {}, args: {})' do
    it 'will execute the script & pass config & arguments' do
      script = Script.new('args[:out] = config[:in]')
      conf = { in: :passed }
      arg = { out: :failed }
      script.call(config: conf, args: arg)
      expect(arg[:out]).to eq(:passed)
    end
  end
end
