require 'batsd_client'

class GraphsController < ApplicationController
  def show
    @request_time_day = TimingGraph.new('request-time', 1.day.ago)
    @request_time_week = TimingGraph.new('request-time', 1.week.ago)
    @request_time_year = TimingGraph.new('request-time', 1.year.ago)
  end

  private

  def client
    @client ||= BatsdClient.new
  end

  class TimingGraph
    def initialize(name, period, client = BatsdClient.new)
      @name = "timers:#{ENV['STATSD_NAMESPACE']}.#{name}"
      @period = period
      @client = client
    end

    def empty?
      max.empty?
    end

    [:max, :mean].each do |stat|
      define_method stat do
        @client.values(@name + ":#{stat}", @period).map {|measure| TimingData.new(measure) }
      end
    end

    class TimingData
      def initialize(measure)
        @measure = measure
      end

      def timestamp
        @measure[:timestamp]
      end

      def ms
        @measure[:value]
      end

      def to_js
        "{ x: #{timestamp.to_i}, y: #{ms} }"
      end
    end
  end
end
