class AddTransportToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :transport, :boolean
  end
end
