require 'batsd_client'

class GraphsController < ApplicationController
  before_filter :hide_from_public

  def show
    @request_time_day = TimingGraph.new('request-time', 1.day.ago)
    @request_time_week = TimingGraph.new('request-time', 1.week.ago)
    @request_time_year = TimingGraph.new('request-time', 1.year.ago)
  end

  private

  def hide_from_public
    authenticate_or_request_with_http_basic { |_, p| p == ENV["HTTP_PASSWORD"] || 'hard-to-guess' }
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
        values = @client.values(@name + ":#{stat}", @period) rescue []
        values.map {|measure| TimingData.new(measure) }
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
