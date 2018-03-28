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

require 'support/pages/page'

module Pages
  class ProjectSettings < Page
    attr_accessor :project

    def initialize(project)
      super()

      self.project = project
    end

    def visit_tab!(name)
      visit settings_project_path(project, tab: name)
    end

    # only notice is used as opposed to notification-box
    def expect_notification(type: :notice, message:)
      expect(page).to have_selector(".flash.#{type}", text: message, wait: 10)
    end

    def expect_type_active(type)
      expect_type(type, true)
    end

    def expect_type_inactive(type)
      expect_type(type, false)
    end

    def expect_type(type, active = true)
      expect(page)
        .to have_field("project_planning_element_type_ids_#{type.id}", checked: active)
    end

    def expect_wp_custom_field_active(custom_field)
      expect_wp_custom_field(custom_field, true)
    end

    def expect_wp_custom_field_inactive(custom_field)
      expect_wp_custom_field(custom_field, false)
    end

    def expect_wp_custom_field(custom_field, active = true)
      expect(page)
        .to have_field(custom_field.name, checked: active)
    end

    private

    def path
      settings_project_path(project)
    end
  end
end
