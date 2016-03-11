#!/usr/bin/env ruby

require 'rest-client'
require 'optparse'

USAGE = "ruby ./nudata.rb [-cCID | -c=CID] [-kKEY | -key=KEY] [-uURL | -u=URL]".freeze

module Nudata
  def self.error_msg(args)
    puts %{

    The cid and key are required!

    cid   = CID
    key   = APIKEY
    count = The number of Nudata responses to compare

    Your arguments: #{args}

    Template example: #{USAGE}

    Real example: ruby ./nudata.rb -c1234 -k12345ag -uhttp://example.com 
    }
  end

  class Request
    attr_reader :cid, :key, :url

    def initialize(args)
      @cid = args.fetch(:cid, nil)
      @key = args.fetch(:key, nil)
      @url = args.fetch(:url, nil')
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

  class Response
    attr_reader :body, :headers, :cookies

    def initialize(response)
      @body    = JSON.parse(response.body)
      @headers = response.headers
      @cookies = response.cookies
    end
  end

  class Compare
    History = ::Struct.new(:points, :current, :last)

    attr_reader :request, :count

    def initialize(request, count)
      @request = request
      @count   = count ? count : 4
    end

    def show
      run

      puts history.points
    end

    def history
      @history ||= History.new({ cookies: [], headers: [], body: [] })
    end

    private

    def run
      count.times do
        response = Response.new(request.run)

        history.current = response

        if history.last
          history.last = history.last
        else
          history.last = history.current
        end

        a_b!
      end
    end

    def a_b!
      points = history.points

      points[:cookies] << (history.current.cookies.to_a - history.last.cookies.to_a).count
      points[:headers] << (history.current.headers.to_a.flatten - history.last.headers.to_a.flatten).count

      points[:body] << (history.current.body.to_a - history.last.body.to_a).count
    end
  end
end

Options = Struct.new(:cid, :key, :url, :asylum, :count)
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

  opts.on("-asylum") do 
    puts "Welcome to the nudata asylum"
  end

  opts.on("-nCOUNT", type='int') do |count|
    args.count = count.to_i
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

  compare = Nudata::Compare.new nudata_request, args.count
  compare.show
else
  puts Nudata.error_msg sanitize(args, false)
end

