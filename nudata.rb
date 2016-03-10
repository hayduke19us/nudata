#!/usr/bin/env ruby

require 'rest-client'
require 'optparse'

# curl -v -X POST -H "Authorization:EAN CID=428281,APIKey=qmatfwd872ysmh33efh8yg9h" -H "Content-Type:application/json" https://widget.ean.com/analytics/behaviorCaptureWidget

USAGE = "ruby ./nudata.rb [-cCID | -c=CID] [-kKEY | -key=KEY] [-uURL | -u=URL]".freeze

module Nudata

  def self.error_msg(args)
    puts %{

    The cid and key are required!

    Your arguments: #{args}

    Template example: #{USAGE}

    Real example: ruby ./nudata.rb -c1234 -k12345ag -uhttp://example.com 
    }
  end

  class Request
    attr_reader :cid, :key, :url

    def initialize(args)
      @cid   = args.fetch(:cid, nil)
      @key   = args.fetch(:key, nil)
      @url   = args.fetch(:url, 'https://widget.ean.com/analytics/behaviorCaptureWidget')
      @times = args.fetch(:times, 3)
    end

    def run
      RestClient::Request.execute(method: :post, url: url, headers: default_headers)
    end

    def default_headers
      {
        'Authorization' => "EAN CID=#{cid},APIKey=#{key}",
        'Content-Type'  => 'application/json'
      }
    end
  end

  class Compare
    History = Struct.new(:points, :current, :last)

    def initialize(response)
      @body    = response.body
      @headers = response.headers
      @cookies = response.cookies
      @code    = response.code
    end

    def history
      @history ||= History.new
    end

    def show
    end
  end
end

Options = Struct.new(:cid, :key, :url, :asylum)
args = Options.new

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./nudata.rb [options]"

  opts.on("-cCID", "-cid=CID") do |cid|
    args.cid = cid
  end

  opts.on("-kKEY", "-key=KEY") do |key|
    args.key = key
  end

  opts.on("-uURL", "-url=URL") do |url|
    args.url = url
  end

  opts.on("-tTIMES", "-times=TIMES") do |times|
    args.times = times
  end

  opts.on("-asylum") do 
    puts "Welcome to the nudata asylum"
    args.cid = '428281'
    args.key = 'qmatfwd872ysmh33efh8yg9h'
    args.asylum = true
  end
end

opt_parser.parse!

class Struct
  unless self.methods.include?(:to_h)
    define_method :to_h do
      hash = {}
      self.each_pair { |k, v| hash[k] = v }
      hash
    end
  end
end

def sanitize(args, heavy=true)
  args = args.to_h
  args.delete(:asylum)

  if heavy
    args.map { |k, v| args.delete(k) if v.nil? }
  end

  args
end

if args.cid && args.key || args.asylum
  nudata_request = Nudata::Request.new sanitize(args)
  Compare.new(nudata_request.run).show
else
  puts Nudata.error_msg sanitize(args, false)
end

