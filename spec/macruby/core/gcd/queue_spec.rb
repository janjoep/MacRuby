require File.dirname(__FILE__) + "/../../spec_helper"

#TODO: Dispatch::Queue.main.run (without killing spec runner!)

if MACOSX_VERSION >= 10.6
  describe "Dispatch::Queue.concurrent" do
    it "returns an instance of Queue" do
      o = Dispatch::Queue.concurrent
      o.should be_kind_of(Dispatch::Queue)
    end

    it "can accept a symbol argument which represents the priority" do
      o = Dispatch::Queue.concurrent(:low)
      o.should be_kind_of(Dispatch::Queue)
 
      o = Dispatch::Queue.concurrent(:default)
      o.should be_kind_of(Dispatch::Queue)

      o = Dispatch::Queue.concurrent(:high)
      o.should be_kind_of(Dispatch::Queue)
    end

    it "raises an ArgumentError if the given argument is not a valid priority symbol" do
      lambda { Dispatch::Queue.concurrent(:foo) }.should raise_error(ArgumentError)
    end
    
    it "should return the same queue object across invocations" do
      a = Dispatch::Queue.concurrent(:low)
      b = Dispatch::Queue.concurrent(:low)
      a.should eql?(b)
    end
    
    it "raises a TypeError if the provided priority is not a symbol" do
      lambda { Dispatch::Queue.concurrent(42) }.should raise_error(TypeError)
    end
  end

  describe "Dispatch::Queue.current" do
    it "returns an instance of Queue" do
      o = Dispatch::Queue.current
      o.should be_kind_of(Dispatch::Queue)
    end
    
    it "should return the parent queue when inside an executing block" do
      q = Dispatch::Queue.new('org.macruby.gcd_spec.queue')
      @q2 = nil
      q.async do
        @q2 = Dispatch::Queue.current
      end
      q.sync {}
      q.label.should == @q2.label
    end
  end

  describe "Dispatch::Queue.main" do
    it "returns an instance of Queue" do
      o = Dispatch::Queue.main
      o.should be_kind_of(Dispatch::Queue)
    end
  end

  describe "Dispatch::Queue.new" do
    it "accepts a name and returns an instance of Queue" do
      o = Dispatch::Queue.new('foo')
      o.should be_kind_of(Dispatch::Queue)

      lambda { Dispatch::Queue.new('foo', 42) }.should raise_error(ArgumentError)
      lambda { Dispatch::Queue.new(42) }.should raise_error(TypeError)
    end
    
    it "raises an ArgumentError if not passed a string" do
      lambda { Dispatch::Queue.new() }.should raise_error(ArgumentError)
    end
  end

  describe "Dispatch::Queue#async" do
    it "accepts a block and yields it asynchronously" do
      o = Dispatch::Queue.new('foo')
      @i = 0
      o.async { @i = 42 }
      while @i == 0 do; end
      @i.should == 42
    end


    it "raises an ArgumentError if no block is given" do
      o = Dispatch::Queue.new('foo')
      lambda { o.async }.should raise_error(ArgumentError) 
    end
  end

  describe "Dispatch::Queue#sync" do
    it "accepts a block and yields it synchronously" do
      o = Dispatch::Queue.new('foo')
      @i = 0
      o.sync { @i = 42 }
      @i.should == 42
    end

    it "raises an ArgumentError if no block is given" do
      o = Dispatch::Queue.new('foo')
      lambda { o.sync }.should raise_error(ArgumentError) 
    end
  end

  describe "Dispatch::Queue#apply" do
    it "accepts an input size and a block and yields it as many times" do
      o = Dispatch::Queue.new('foo')
      @i = 0
      o.apply(10) { @i += 1 }
      @i.should == 10
      @i = 42
      o.apply(0) { @i += 1 }
      @i.should == 42

      lambda { o.apply(nil) {} }.should raise_error(TypeError) 
    end

    it "raises an ArgumentError if no block is given" do
      o = Dispatch::Queue.new('foo')
      lambda { o.apply(42) }.should raise_error(ArgumentError) 
    end
  end

  describe "Dispatch::Queue#after" do
    it "accepts a given time (in seconds) and a block and yields it after" do
      o = Dispatch::Queue.new('foo')
      [1.0, 2, 0.9, 1.5].each do |test_time|
      
      t = Time.now
      o.after(test_time) { @i = 42 }
      @i = 0
      while @i == 0 do; end
      @i.should == 42
      t2 = Time.now - t
      t2.should > test_time
      t2.should < test_time*2
      end
    end

    it "raises an ArgumentError if no time is given" do
      o = Dispatch::Queue.new('foo')
      lambda { o.after(nil) {} }.should raise_error(TypeError) 
    end

    it "raises an ArgumentError if no block is given" do
      o = Dispatch::Queue.new('foo')
      lambda { o.after(42) }.should raise_error(ArgumentError) 
    end
  end

  describe "Dispatch::Queue#label" do
    it "returns the name of the queue" do
      o = Dispatch::Queue.new('foo')
      o.label.should == 'foo'

      o = Dispatch::Queue.main
      o.label.should == 'com.apple.main-thread'
    end

    it "is also returned by to_s" do
      o = Dispatch::Queue.new('foo')
      o.to_s.should == o.label

      o = Dispatch::Queue.main
      o.to_s.should == 'com.apple.main-thread'
    end

    it "is included as part of inspect" do
      o = Dispatch::Queue.new('foo')
      o.inspect.index('foo').should.be_kind_of(Fixnum)
    end
  end

  describe "Dispatch::Queue#suspend!" do
    it "suspends the queue which can be resumed by calling #resume!" do
      o = Dispatch::Queue.new('foo')
      o.async { sleep 1 }
      o.suspended?.should == false
      o.suspend! 
      o.suspended?.should == true
      o.resume!
      o.suspended?.should == false
    end
  end
  
end