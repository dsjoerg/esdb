# Testing ApiFields, dubbed FieldsParam, also known as 'filter' in matches.rb
# right now.
#
# Actual integration with the Api is tested in the respectice endpoint specs.

require 'spec_helper'

describe ApiFields::Parser do
  describe :parse do
    it 'should parse a convoluted string correctly' do
      fields = 'this(+is(+test(+of(-strength))))'
      parsed = ApiFields::Parser.parse(fields)
      parsed.should be_a(ApiFields::Matcher)

      parsed.tree.should == {'this' => {'is' => {'test' => {'of' =>  {'strength' => false}}}}}
    end

    it 'should not include child nodes if their parent is negated' do
      fields = 'super(-parent(+child))'
      parsed = ApiFields::Parser.parse(fields)
      parsed.should be_a(ApiFields::Matcher)

      parsed.tree.should == {'super' => {'parent' => false}}
    end

    it 'should default all missing childs to true' do
      fields = 'nothing'
      parsed = ApiFields::Parser.parse(fields)
      parsed.should be_a(ApiFields::Matcher)

      parsed.this.does.not.exist?.should == true
    end

  end
end