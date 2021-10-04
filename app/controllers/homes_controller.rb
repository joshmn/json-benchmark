class HomesController < ApplicationController
  rescue_from NotImplementedError do |msg|
    render plain: msg
  end

  before_action :benchmark!
  after_action :log_benchmark!

  def index
    homes = Home.select(:id, :latitude, :longitude).limit(params[:limit] || 100)

    if params[:via].present?
      instance_exec(homes, &SerializeManager.fetch(params[:via]))
    else
      render plain: "Hello World."
    end
  end

  private

  def benchmark!
    MemoryProfiler.start
  end

  def log_benchmark!
    report = MemoryProfiler.stop
    Rails.logger.info("MEMSTAT: #{report.total_allocated} / #{report.total_allocated_memsize}")
    Rails.logger.info("RESPONSE BODY SIZE: #{response.body.size}")
    GC.start
  end
end
