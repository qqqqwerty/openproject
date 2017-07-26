#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
class NonWorkDay < ActiveRecord::Base
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