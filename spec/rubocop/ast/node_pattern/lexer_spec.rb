# frozen_string_literal: true

RSpec.describe RuboCop::AST::NodePattern::Lexer do
  let(:source) { '(send nil? #func(:foo) #func (bar))' }
  let(:lexer) { RuboCop::AST::NodePattern::Parser::WithMeta::Lexer.new(source) }
  let(:tokens) do
    tokens = []
    while (token = lexer.next_token)
      tokens << token
    end
    tokens
  end

  it 'provides tokens via next_token' do # rubocop:disable RSpec/ExampleLength
    type, (text, range) = tokens[3]
    expect(type).to eq :tFUNCTION_CALL
    expect(text).to eq :func
    expect(range.to_range).to eq 11...16

    expect(tokens.map(&:first)).to eq [
      '(',
      :tNODE_TYPE,
      :tPREDICATE,
      :tFUNCTION_CALL, :tARG_LIST, :tSYMBOL, ')',
      :tFUNCTION_CALL,
      '(', :tNODE_TYPE, ')',
      ')'
    ]
  end

  context 'with $type+' do
    let(:source) { '(array sym $int+ x)' }

    it 'works' do
      expect(tokens.map(&:last).map(&:first)).to eq \
        %i[( array sym $ int + x )]
    end
  end

  [
    /test/,
    /[abc]+\/()?/x, # rubocop:disable Style/RegexpLiteral
    /back\\slash/
  ].each do |regexp|
    context "when given a regexp #{regexp.inspect}" do
      let(:source) { regexp.inspect }

      it 'round trips' do
        token = tokens.first
        value = token.last.first
        expect(value.inspect).to eq regexp.inspect
      end
    end
  end

  context 'when given a regexp ending with a backslash' do
    let(:source) { '/tricky\\/' }

    it 'does not lexes it properly' do
      expect { tokens }.to raise_error(RuboCop::AST::NodePattern::LexerRex::ScanError)
    end
  end
end
