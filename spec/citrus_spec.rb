require 'spec_helper_light'

require 'citrus'
require 'citrus_grammars'

# For now we simply validate the grammar here, which will throw exceptions
# if it's ever unable to parse anything, instead of checking parsed values
# (as the structure of those may change, pretty often and should be tested
# as part of StatBuilder instead)

describe StatsParam do
  # Simple metrics with calcs, no conds

  it 'should parse a stat with one metric and one calc' do
    StatsParam.parse('apm(avg)')
  end

  it 'should parse a stat with one metric and two calcs' do
    StatsParam.parse('apm(avg,sum)')
  end

  it 'should parse a stat with two metrics and one calc on the first' do
    StatsParam.parse('apm(avg),apm')
  end

  it 'should parse a stat with two metrics and one calc on the second' do
    StatsParam.parse('apm,apm(avg)')
  end

  # Metrics with calcs and conditions

  it 'should parse a stat with one metric, one calc and one cond' do
    StatsParam.parse('apm(avg:[>p])')
  end

  it 'should parse a stat with one metric, one calc and multiple conds' do
    StatsParam.parse('apm(avg:[>p,20m])')
  end

  it 'should parse a stat with one metric, multiple calcs and multiple conds on the first' do
    StatsParam.parse('apm(avg:[>p,20m],sum,count)')
  end

  it 'should parse a stat with two metrics, both with multiple conds' do
    StatsParam.parse('apm(avg:[>p,20m]),wpm(sum:[<z,10m])')
  end

  it 'should parse a stat with two metrics, with conds on the first' do
    StatsParam.parse('apm(avg:[>p,20m]),wpm')
  end

  it 'should parse a stat with two metrics, with conds on the second' do
    StatsParam.parse('apm,wpm(avg:[>p,20m])')
  end

  it 'should parse a stat with two metrics, both with multiple calcs, one with multiple conds' do
    StatsParam.parse('apm(sum,count,avg),wpm(avg:[>p,20m])')
  end
end
