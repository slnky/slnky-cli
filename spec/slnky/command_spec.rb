require 'spec_helper'

describe Slnky::Command::Base do
  subject {described_class.new}
  it 'can manage commands' do
    expect { described_class.command('test', 'test if this works', 'test [options] PARAM') }.to_not raise_error
    expect(described_class.commands.count).to eq(2) # help and one we added above
    expect(described_class.commands.first).to be_a(Slnky::Command::Processor)
  end

  describe Slnky::Command::Processor do
    subject {described_class.new('test', 'testing', <<-USAGE.strip_heredoc)}
        Usage: test [options] PARAM

        -h --help       print help
        -v --verbose    make verbose
        -n --name NAME  named NAME
    USAGE
    let(:options) { %w{-v --name myname myparam} }
    it 'can process options' do
      expect { subject.process(options) }.to_not raise_error
      expect(subject.process(options)).to be_a(Slnky::Data)
    end

    it 'can accept arguments' do
      expect(subject.process(options).param).to eq('myparam')
    end

    it 'can accept options' do
      expect(subject.process(options).verbose).to eq(true)
      expect(subject.process(options).name).to eq('myname')
    end
  end
end
