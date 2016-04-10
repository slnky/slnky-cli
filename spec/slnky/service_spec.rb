require 'spec_helper'

describe Slnky::Service::Base do
  subject { described_class.new }

  it 'can manage subscriptions' do
    expect { described_class.subscribe('test.event', :method) }.to_not raise_error
    expect(subject.subscriber.list.count).to eq(1)
    expect(subject.subscriber.list.first).to be_a(Slnky::Service::Subscription)
  end

  it 'can manage timers' do
    expect { described_class.timer(5.seconds, :method) }.to_not raise_error
    expect(subject.timers.list.count).to eq(1)
    expect(subject.timers.list.first).to be_a(Slnky::Service::Periodic)
  end
end
