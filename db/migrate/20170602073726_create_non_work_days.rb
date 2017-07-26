class CreateNonWorkDays < ActiveRecord::Migration[5.0]
  def change
    create_table :non_work_days do |t|
      t.date :date
    end
  end
end