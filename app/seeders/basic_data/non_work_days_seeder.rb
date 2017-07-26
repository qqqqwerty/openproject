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
module BasicData
  class NonWorkDaysSeeder < Seeder
    def seed_data!
      NonWorkDay.transaction do
        data.each do |attributes|
          NonWorkDay.create(attributes)
        end
      end
    end

    def applicable?
      NonWorkDay.all.empty?
    end

    def not_applicable_message
      'Skipping non work days as there are already some configured'
    end

    def data
      [
        { date: Date.parse("2017-06-04")   },
        { date: Date.parse("2017-06-24")   },
        { date: Date.parse("2017-07-06")   },
        { date: Date.parse("2017-08-15")   },
        { date: Date.parse("2017-11-01")   },
        { date: Date.parse("2017-12-24")   },
        { date: Date.parse("2017-12-25")   },
        { date: Date.parse("2017-12-26")   },
        { date: Date.parse("2018-01-01")   },
        { date: Date.parse("2018-02-16")   },
        { date: Date.parse("2018-03-11")   },
        { date: Date.parse("2018-04-01")   },
        { date: Date.parse("2018-04-02")   },
        { date: Date.parse("2018-05-01")   },
        { date: Date.parse("2018-05-06")   },
        { date: Date.parse("2018-06-03")   },
        { date: Date.parse("2018-06-24")   },
        { date: Date.parse("2018-07-06")   },
        { date: Date.parse("2018-08-15")   },
        { date: Date.parse("2018-11-01")   },
        { date: Date.parse("2018-12-24")   },
        { date: Date.parse("2018-12-25")   },
        { date: Date.parse("2018-12-26")   }
      ]
    end
  end
end