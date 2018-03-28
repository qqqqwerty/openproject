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

class WorkPackages::CopyService
  include ::Shared::ServiceContext

  attr_accessor :user,
                :work_package,
                :contract

  def initialize(user:, work_package:, contract: WorkPackages::CreateContract)
    self.user = user
    self.work_package = work_package
    self.contract = contract
  end

  def call(attributes: {}, send_notifications: true)
    in_context(send_notifications) do
      copy(attributes, send_notifications)
    end
  end

  protected

  def copy(attribute_override, send_notifications)
    attributes = copied_attributes(work_package, attribute_override)

    copied = create(attributes, send_notifications)

    if copied.success?
      copy_watchers(copied.result)
    end

    copied
  end

  def create(attributes, send_notifications)
    WorkPackages::CreateService
      .new(user: user,
           contract: contract)
      .call(attributes: attributes,
            send_notifications: send_notifications)
  end

  def copied_attributes(wp, override)
    wp
      .attributes
      .slice(*writable_work_package_attributes(wp))
      .merge('author_id' => user.id,
             'parent_id' => wp.parent_id,
             'custom_field_values' => wp.custom_value_attributes)
      .merge(override)
  end

  def writable_work_package_attributes(wp)
    contract.new(wp, user).writable_attributes
  end

  def copy_watchers(copied)
    work_package.watchers.each do |watcher|
      copied.add_watcher(watcher.user) if watcher.user.active?
    end
  end
end
