class SynchronizingJob < ApplicationJob
  queue_as :default

  def perform(supplier)
    5.times do
      ActionCable.server.broadcast 'activity_channel', message: render_logging(supplier)
      sleep 1
    end
  end

  private

  def render_logging(supplier)
    ApplicationController.renderer.render partial: 'welcome/logs',
                                          locals: { message: supplier.name }
  end
end
