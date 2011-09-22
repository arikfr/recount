require 're_count/server'
require 'goliath/test_helper'

describe ReCount::Server do
  include Goliath::TestHelper

  let(:err) { Proc.new { |c| fail "HTTP Request failed #{c.response}" } }

  def test_post_request (path, &blk)
    with_api(ReCount::Server) do
      post_request({:path => path}, err, &blk)
    end
  end

  def test_get_request (path, &blk)
    with_api(ReCount::Server) do
      get_request({:path => path}, err, &blk)
    end
  end

  describe 'POST /counters/:counter_name/increment' do
    it 'increases the counter' do
      test_post_request('/counters/test/increment') do
        ReCount::Counter.instances.last.total_value.should eql(1)
      end
    end

    it 'uses the correct counter name' do
      test_post_request('/counters/test/increment') do
        ReCount::Counter.instances.last.name.should eql('test')
      end
    end

    it 'returns status code 200' do
      test_post_request('/counters/test/increment') do |c|
        c.response_header.status.should == 200
      end
    end

    it 'returns new today value' do
      test_post_request('/counters/test/increment') do |c|
        Yajl::Parser.parse(c.response).include?("day").should be_true
      end
    end
  end

  describe 'GET /counters' do
    let (:names) { ['test_all1', 'test_all2'] }

    before :each do
      names.each { |name| ReCount::Counter.new(name).increase }
    end

    it 'returns list of all counters in the system' do
      test_get_request('/counters') do |c|
        response = Yajl::Parser.parse(c.response)
        response.include?('counters').should be_true
        response['counters'].should =~ names
      end
    end

    it 'returns list of all counters with their data when passed extended param' do
      results = names.map do |name|
        ReCount::Counter.new(name).to_object.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}
      end

      test_get_request('/counters?extended') do |c|
        response = Yajl::Parser.parse(c.response)
        response.include?('counters').should be_true
        response['counters'].should eql(results)
      end
    end

    it 'returns status code 200' do
      test_get_request('/counters') do |c|
        c.response_header.status.should == 200
      end
    end
  end

  describe 'GET /counters/:counter_name' do
    it 'returns json with current counter values' do |c|
      test_get_request('/counters/test') do |c|
        json = Yajl::Parser.parse(c.response)
        json.include?("day").should be_true
        json.include?("month").should be_true
        json.include?("year").should be_true
        json.include?("total").should be_true
      end
    end

    it 'returns status code 200' do
      test_get_request('/counters/test') do |c|
        c.response_header.status.should == 200
      end
    end
  end
end
