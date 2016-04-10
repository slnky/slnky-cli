require 'spec_helper'

describe Slnky::Command::Base do
  subject {described_class.new}
  it 'can manage commands' do
    expect { described_class.command('test', 'test if this works', 'test [options] PARAM') }.to_not raise_error
    expect(described_class.commands.count).to eq(2) # help and one we added above
    expect(described_class.commands.first).to be_a(Slnky::Command::Processor)
  end

  describe Slnky::Command::Processor do
    subject {described_class.new('test', 'testing', 'Usage: test [options] PARAM')}
    it 'can accept arguments' do
      expect { subject.process(['blarg']) }.to_not raise_error
      expect(subject.process(['blarg'])).to be_a(Slnky::Data)
    end
  end
end
