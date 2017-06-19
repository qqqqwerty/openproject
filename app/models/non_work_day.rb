class NonWorkDay < ApplicationRecord
  def self.get_work_day(offset)
    target_day = Date.today + 1
    left_to_skip = offset.to_i
    wrong_date = true
    max_its = 10
    i = 0
    while wrong_date && i < max_its
      if target_day.saturday?
        target_day += 2
      elsif target_day.sunday?
        target_day += 1
      end
      holiday = NonWorkDay.where(date: target_day).first
      if holiday.blank?
        left_to_skip = left_to_skip - 1
        if left_to_skip == 0
          wrong_date = false
        else
          target_day += 1
        end
      else
        target_day += 1
      end
      i += 1
    end
    target_day
  end
end
