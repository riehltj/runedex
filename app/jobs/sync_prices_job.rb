class SyncPricesJob < ApplicationJob
  queue_as :default

  def perform
    TcgPriceSync.call
  end
end
