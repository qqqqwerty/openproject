class AddUsedUserToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :used_user, :integer
  end
end
