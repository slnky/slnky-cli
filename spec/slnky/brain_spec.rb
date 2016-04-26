require 'spec_helper'

describe Slnky::Brain::Base do
  subject {described_class.new}

  it 'can set/get string' do
    expect { subject.hset(:test, 'key1', 'value1') }.not_to raise_error
    expect(subject.hget(:test, 'key1')).to eq('value1')
  end

  it 'can set/get object' do
    expect { subject.hset(:test, 'key2', {test: true}) }.not_to raise_error
    expect(subject.hget(:test, 'key2')).to eq({"test" => true})
  end

  it 'can get all values' do
    expect(subject.hgetall(:test)).to eq({"key1"=>"value1", "key2"=>{"test" => true}})
  end
end