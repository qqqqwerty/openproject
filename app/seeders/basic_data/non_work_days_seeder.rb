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
        { date: Date.parse("2018-12-26")   },
        { date: Date.parse("2019-01-01")   },
        { date: Date.parse("2019-02-16")   },
        { date: Date.parse("2019-03-11")   },
        { date: Date.parse("2019-04-22")   }, # Velykos
        { date: Date.parse("2019-05-01")   },
        { date: Date.parse("2019-06-24")   },
        { date: Date.parse("2019-07-06")   },
        { date: Date.parse("2019-08-15")   },
        { date: Date.parse("2019-11-01")   },
        { date: Date.parse("2019-12-24")   },
        { date: Date.parse("2019-12-25")   },
        { date: Date.parse("2019-12-26")   },
        { date: Date.parse("2020-01-01")   },
        { date: Date.parse("2020-02-16")   },
        { date: Date.parse("2020-03-11")   },
        { date: Date.parse("2020-04-13")   }, # Velykos
        { date: Date.parse("2020-05-01")   },
        { date: Date.parse("2020-06-24")   },
        { date: Date.parse("2020-07-06")   },
        { date: Date.parse("2020-08-15")   },
        { date: Date.parse("2020-11-01")   },
        { date: Date.parse("2020-12-24")   },
        { date: Date.parse("2020-12-25")   },
        { date: Date.parse("2020-12-26")   },
        { date: Date.parse("2021-01-01")   },
        { date: Date.parse("2021-02-16")   },
        { date: Date.parse("2021-03-11")   },
        { date: Date.parse("2021-04-05")   }, # Velykos
        { date: Date.parse("2021-05-01")   },
        { date: Date.parse("2021-06-24")   },
        { date: Date.parse("2021-07-06")   },
        { date: Date.parse("2021-08-15")   },
        { date: Date.parse("2021-11-01")   },
        { date: Date.parse("2021-12-24")   },
        { date: Date.parse("2021-12-25")   },
        { date: Date.parse("2021-12-26")   },
        { date: Date.parse("2022-01-01")   },
        { date: Date.parse("2022-02-16")   },
        { date: Date.parse("2022-03-11")   },
        { date: Date.parse("2022-04-18")   }, # Velykos
        { date: Date.parse("2022-05-01")   },
        { date: Date.parse("2022-06-24")   },
        { date: Date.parse("2022-07-06")   },
        { date: Date.parse("2022-08-15")   },
        { date: Date.parse("2022-11-01")   },
        { date: Date.parse("2022-12-24")   },
        { date: Date.parse("2022-12-25")   },
        { date: Date.parse("2022-12-26")   },
        { date: Date.parse("2023-01-01")   },
        { date: Date.parse("2023-02-16")   },
        { date: Date.parse("2023-03-11")   },
        { date: Date.parse("2023-04-10")   }, # Velykos
        { date: Date.parse("2023-05-01")   },
        { date: Date.parse("2023-06-24")   },
        { date: Date.parse("2023-07-06")   },
        { date: Date.parse("2023-08-15")   },
        { date: Date.parse("2023-11-01")   },
        { date: Date.parse("2023-12-24")   },
        { date: Date.parse("2023-12-25")   },
        { date: Date.parse("2023-12-26")   },
        { date: Date.parse("2024-01-01")   },
        { date: Date.parse("2024-02-16")   },
        { date: Date.parse("2024-03-11")   },
        { date: Date.parse("2024-04-01")   }, # Velykos
        { date: Date.parse("2024-05-01")   },
        { date: Date.parse("2024-06-24")   },
        { date: Date.parse("2024-07-06")   },
        { date: Date.parse("2024-08-15")   },
        { date: Date.parse("2024-11-01")   },
        { date: Date.parse("2024-12-24")   },
        { date: Date.parse("2024-12-25")   },
        { date: Date.parse("2024-12-26")   },
        { date: Date.parse("2025-01-01")   },
        { date: Date.parse("2025-02-16")   },
        { date: Date.parse("2025-03-11")   },
        { date: Date.parse("2025-04-21")   }, # Velykos
        { date: Date.parse("2025-05-01")   },
        { date: Date.parse("2025-06-24")   },
        { date: Date.parse("2025-07-06")   },
        { date: Date.parse("2025-08-15")   },
        { date: Date.parse("2025-11-01")   },
        { date: Date.parse("2025-12-24")   },
        { date: Date.parse("2025-12-25")   },
        { date: Date.parse("2025-12-26")   },
        { date: Date.parse("2026-01-01")   },
        { date: Date.parse("2026-02-16")   },
        { date: Date.parse("2026-03-11")   },
        { date: Date.parse("2026-04-06")   }, # Velykos
        { date: Date.parse("2026-05-01")   },
        { date: Date.parse("2026-06-24")   },
        { date: Date.parse("2026-07-06")   },
        { date: Date.parse("2026-08-15")   },
        { date: Date.parse("2026-11-01")   },
        { date: Date.parse("2026-12-24")   },
        { date: Date.parse("2026-12-25")   },
        { date: Date.parse("2026-12-26")   },
        { date: Date.parse("2027-01-01")   },
        { date: Date.parse("2027-02-16")   },
        { date: Date.parse("2027-03-11")   },
        { date: Date.parse("2027-03-29")   }, # Velykos
        { date: Date.parse("2027-05-01")   },
        { date: Date.parse("2027-06-24")   },
        { date: Date.parse("2027-07-06")   },
        { date: Date.parse("2027-08-15")   },
        { date: Date.parse("2027-11-01")   },
        { date: Date.parse("2027-12-24")   },
        { date: Date.parse("2027-12-25")   },
        { date: Date.parse("2027-12-26")   },
        { date: Date.parse("2028-01-01")   },
        { date: Date.parse("2028-02-16")   },
        { date: Date.parse("2028-03-11")   },
        { date: Date.parse("2028-04-17")   }, # Velykos
        { date: Date.parse("2028-05-01")   },
        { date: Date.parse("2028-06-24")   },
        { date: Date.parse("2028-07-06")   },
        { date: Date.parse("2028-08-15")   },
        { date: Date.parse("2028-11-01")   },
        { date: Date.parse("2028-12-24")   },
        { date: Date.parse("2028-12-25")   },
        { date: Date.parse("2028-12-26")   },
        { date: Date.parse("2029-01-01")   },
        { date: Date.parse("2029-02-16")   },
        { date: Date.parse("2029-03-11")   },
        { date: Date.parse("2029-04-02")   }, # Velykos
        { date: Date.parse("2029-05-01")   },
        { date: Date.parse("2029-06-24")   },
        { date: Date.parse("2029-07-06")   },
        { date: Date.parse("2029-08-15")   },
        { date: Date.parse("2029-11-01")   },
        { date: Date.parse("2029-12-24")   },
        { date: Date.parse("2029-12-25")   },
        { date: Date.parse("2029-12-26")   },
        { date: Date.parse("2030-01-01")   },
        { date: Date.parse("2030-02-16")   },
        { date: Date.parse("2030-03-11")   },
        { date: Date.parse("2030-04-22")   }, # Velykos
        { date: Date.parse("2030-05-01")   },
        { date: Date.parse("2030-06-24")   },
        { date: Date.parse("2030-07-06")   },
        { date: Date.parse("2030-08-15")   },
        { date: Date.parse("2030-11-01")   },
        { date: Date.parse("2030-12-24")   },
        { date: Date.parse("2030-12-25")   },
        { date: Date.parse("2030-12-26")   }
      ]
    end
  end
end