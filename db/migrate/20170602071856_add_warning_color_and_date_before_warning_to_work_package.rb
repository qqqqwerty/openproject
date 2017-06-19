class AddWarningColorAndDateBeforeWarningToWorkPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :work_packages, :warning_color, :integer
    add_column :work_packages, :day_before_warning, :date
  end
end
