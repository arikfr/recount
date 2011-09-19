require 're_count/counter'

describe ReCount::Counter do
  let (:counter_name) { "test_#{(rand * 10000).to_i}" }
  let (:counter) { ReCount::Counter.new(counter_name) }
  let (:yesterday) { Time.now - 60*60*24 }

  describe '.new' do
    it 'accepts counter name and returns an instnace' do
      c = ReCount::Counter.new("hits")
      c.class.should eql(ReCount::Counter)
    end

    it 'accepts counter name as symbol' do
      c = ReCount::Counter.new(:hits)
      c.name.should eql("hits")
    end
  end

  describe '.redis_connection' do
    it 'Redis object with default params' do
      ReCount::Counter.redis_connection.should be_an_instance_of(Redis)
    end

    it 'returns set value if is set' do
      redis_connection = ReCount::Counter.redis_connection
      ReCount::Counter.redis_connection = :redis
      ReCount::Counter.redis_connection.should eql(:redis)
      ReCount::Counter.redis_connection = redis_connection
    end
  end

  describe '#increase' do
    context 'no arguments' do
      it "increases total value by 1" do
        lambda {
          counter.increase
        }.should change(counter, :total_value).by(1)
      end

      it "increases today's value by 1" do
        lambda {
          counter.increase
        }.should change{ counter.day_value }.by(1)
      end
    end

    context 'numeric argument' do
      it 'increases current value by given value for today' do
        lambda {
          counter.increase(2)
        }.should change{ counter.day_value }.by(2)
      end
    end

    context 'numeric value and date' do
      it 'updates the value for the given date' do
        lambda {
          counter.increase(1, yesterday)
        }.should change{counter.day_value(yesterday)}.by(1)
      end
    end

    it 'returns new value' do
      counter.increase.should eql(1)
      counter.increase.should eql(2)
    end
  end


  describe '#total_value' do
    it 'returns 0 for new counter' do
      counter.total_value.should eql(0)
    end

    it 'returns all time total value of counter' do
      counter.increase(1, Time.new(2009, 1,1))
      counter.increase(2, Time.new(2008, 1,1))
      counter.increase(3, Time.new(2010, 1,1))
      counter.increase(4, Time.new(2010, 2,4))
      counter.increase(5, Time.new(2011, 1,5))
      counter.total_value.should eql(1+2+3+4+5)
    end
  end

  describe '#day_value' do
    before :each do
      counter.increase(1, yesterday)
      counter.increase(1, Time.now)
    end

    it 'returns the value for the given day' do
      counter.day_value(yesterday).should eql(1)
    end

    it 'returns the value for today if no date passed' do
      counter.day_value.should eql(1)
    end
  end

  describe '#month_value' do
    it 'returns the vlaue for the given month' do
      counter.increase(1, Time.new(2011, 10, 1))
      counter.increase(2, Time.new(2011, 10, 2))
      counter.increase(3, Time.new(2011, 10, 3))
      counter.increase(3, Time.new(2011, 9, 3))
      counter.month_value(Time.new(2011, 10)).should eql(3+2+1)
    end
  end

  describe '#year_value' do
    it 'returns the value for the given year' do
      counter.increase(1, Time.new(2011, 1, 1))
      counter.increase(2, Time.new(2011, 2, 1))
      counter.increase(3, Time.new(2011, 3, 1))
      counter.year_value(Time.new(2011)).should eql(3+2+1)
    end
  end

  describe '#to_object' do
    before :each do
      counter.increase(1, Time.new(Time.now.year-1, 1, 1))
      counter.increase(1, Time.new(Time.now.year, 1, 1))
      counter.increase(2, Time.new(Time.now.year, Time.now.month, 1))
      counter.increase(3, Time.now)
    end

    it 'returns hash with value for this day' do
      counter.to_object[:day].should eql(3)
    end

    it 'returns hash with value for this month' do
      counter.to_object[:month].should eql(3+2)
    end

    it 'returns hash with value for this year' do
      counter.to_object[:year].should eql(1+2+3)
    end

    it 'returns hash with total value' do
      counter.to_object[:total].should eql(1+1+2+3)
    end

    it 'updates after another increase' do
      counter.to_object[:day].should eql(3)
      counter.increase(1, Time.now)
      counter.to_object[:day].should eql(3+1)
    end
  end
end
