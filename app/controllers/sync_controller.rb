class SyncController < ApplicationController
  def single
    SynchronizingJob.perform_later supplier
  end

  private

  def supplier
    @supplier ||= Supplier.find(params[:supplier_id])
  end
end
