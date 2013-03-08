require 'simplecov'
SimpleCov.start

if ENV["TRAVIS"] || ENV["COVERALLS_RUN_LOCALLY"]
  require 'coveralls'
  Coveralls.wear!
end

require File.dirname(File.expand_path(__FILE__)) + '/../lib/trying'

describe "Trying" do
  include Trying

  before :each do
    trying_options :reset
  end

  def sleep n
    # each test should set its own expectation on how sleep will be called
    raise "Don't call sleep during testing!"
  end

  def should_raise e
    lambda { yield }.should raise_error e
  end

  def count_trying *opts
    @try_count = 0
    return trying(*opts) { |*args|
      @try_count += 1
      yield(*args)
    }
  end


  it "should not affect the return value of the block" do
    should_not_receive :sleep
    count_trying { 'foo' }.should == 'foo'
    @try_count.should == 1
  end

  it "should not affect the return value when there is a retry" do
    should_receive(:sleep).once.with(1)
    count_trying { |tries, ex| raise StandardError if tries < 1; 'foo' }.should == 'foo'
    @try_count.should == 2
  end

  it "passes the exception to the application" do
    should_receive(:sleep).once.with(1)
    should_raise(IOError) {
      count_trying { raise IOError }
    }
    @try_count.should == 2
  end

  it "should not retry Exceptions by default" do
    should_not_receive :sleep
    should_raise(Exception) {
      count_trying { raise Exception }
    }
    @try_count.should == 1
  end

  it "doesn't call the proc if :tries is 0" do
    should_not_receive :sleep
    count_trying(:tries => 0) { raise RangeError }
    @try_count.should == 0
  end

  it "calls the proc once if :tries is 1" do
    should_not_receive :sleep
    should_raise(RangeError) {
      count_trying(:tries => 1) { raise RangeError }
    }
    @try_count.should == 1
  end

  it "calls the proc twice if :tries is 2" do
    should_receive(:sleep).once.with(1)
    should_raise(RangeError) {
      count_trying(:tries => 2) { raise RangeError }
    }
    @try_count.should == 2
  end

  it "retries the specified number of times" do
    should_receive(:sleep).exactly(2).times.with(1)
    should_raise(StandardError) {
      count_trying(:tries => 3) { raise StandardError }
    }
    @try_count.should == 3
  end

  it "retries an exception that is covered by :on" do
    # FloatDomainError is a subclass of RangeError
    should_receive(:sleep).once.with(1)
    should_raise(FloatDomainError) {
      count_trying(:on => RangeError) { raise FloatDomainError }
    }
    @try_count.should == 2
  end

  it "doesn't retry exceptions that aren't covered by :on" do
    # NameError is a sibliing of RangeError, not a subclass
    should_not_receive :sleep
    should_raise(NameError) {
      count_trying(:on => RangeError) { raise NameError }
    }
    @try_count.should == 1
  end

  it "retries multiple exceptions that are covered by :on" do
    # FloatDomainError is a subclass of RangeError
    should_receive(:sleep).once.with(1)
    should_raise(FloatDomainError) {
      count_trying(:on => [IOError, RangeError, NoMethodError]) { raise FloatDomainError }
    }
    @try_count.should == 2
  end

  it "doesn't retry any exception if :on is empty" do
    should_raise(FloatDomainError) {
      count_trying(:on => []) { raise FloatDomainError }
    }
    @try_count.should == 1
  end

  it "should catch an exception that matches the regex" do
    should_receive(:sleep).once.with(1)
    count_trying(:matching => /IO timeout/) { |c,e| raise "yo, IO timeout!" if c == 0 }
    @try_count.should == 2
  end

  it "should not catch an exception that doesn't match the regex" do
    should_not_receive :sleep
    should_raise(RuntimeError) {
      count_trying(:matching => /TimeError/) { raise "yo, IO timeout!" }
    }
    @try_count.should == 1
  end

  it "works with all the options set" do
    should_receive(:sleep).exactly(3).times.with(0.3)
    count_trying(:tries => 4, :on => RuntimeError, :sleep => 0.3, :matching => /IO timeout/) { |c,e| raise "my IO timeout" if c < 3 }
    @try_count.should == 4
  end

  it "works with all the options set globally" do
    should_receive(:sleep).exactly(3).times.with(0.3)
    trying_options :tries => 4, :on => RuntimeError, :sleep => 0.3, :matching => /IO timeout/
    count_trying { |c,e| raise "my IO timeout" if c < 3 }
    @try_count.should == 4
  end

  it "sends the previous exception to the block" do
    should_receive(:sleep).once.with(1)
    trying { |tries, e|
      raise IOError if tries == 0         # first time through the loop
      e.should be_an_instance_of IOError  # make sure second time matches the first
    }
  end

  it "accepts :tries as a global option" do
    should_receive(:sleep).exactly(3).times.with(1)
    trying_options :tries => 4
    should_raise(RangeError) {
      count_trying { raise RangeError }
    }
    @try_count.should == 4
  end

  it "accepts a proc for sleep" do
    [1, 4, 16, 64].each { |i| should_receive(:sleep).once.ordered.with(i) }
    trying_options :tries => 5, :sleep => lambda { |n| 4**n }
    should_raise(RangeError) { trying { raise RangeError } }
  end

  it "should not call sleep if :sleep is nil" do
    should_not_receive :sleep
    count_trying(:sleep => nil) { |c,e| raise StandardError if c == 0 }
    @try_count.should == 2
  end

  it "should allow nesting by default" do
    trying { trying { 'inner' } }.should == 'inner'
  end

  it "detects nesting" do
    trying_options :detect_nesting => true
    should_raise(Trying::NestingError) {
      trying { trying { raise "not reached" } }
    }
    # make sure that the nesting flag is turned off
    trying { 'foo' }.should == 'foo'
  end

  it "detects nesting even if inner loop refuses" do
    should_raise(Trying::NestingError) {
      trying(:detect_nesting => true) {
        trying(:detect_nesting => false) { raise "not reached" }
      }
    }
  end

  it "doesn't allow invalid options" do
    should_raise(Trying::InvalidOptions) {
      trying(:bad_option => 2) { raise "this is bad" }
    }
  end

  it "doesn't allow invalid global options" do
    should_raise(Trying::InvalidOptions) {
      trying_options :bad_option => 'bogus'
      raise "not reached"
    }
  end

  it "should automatically log" do
    task = 'frobnicating the fizlunks'
    trying_options :sleep => nil, :logger => lambda { |t,r,e|
      t.should == task
      r.should == @try_count
      e.should == nil if r == 0
      e.message.should == "RangeError" if r > 0
    }
    should_raise(RangeError) {
      count_trying(:task => task) { raise RangeError }
    }
  end

  it "should test the default logging" do
    task = 'setting sigmaclapper to 0'
    should_raise(RangeError) {
      # sad to mock puts but alternatives get seriously complex
      STDERR.should_receive(:puts).with("setting sigmaclapper to 0")
      STDERR.should_receive(:puts).with("setting sigmaclapper to 0 RETRY 1 because RangeError")
      count_trying(:task => task, :sleep => nil) { raise RangeError }
    }
  end

  it "should not remember temporary options" do
    # found a bug where setting local options would affect globals
    # (forgot to dup the global hash when merging in the local opts)
    trying_options :logger => lambda { |t,r,e| }
    trying_options[:task].should == nil
    trying(:task => "TASK SET") { }
    trying_options[:task].should == nil
  end
end
