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

require 'spec_helper'
require 'features/projects/projects_page'

describe 'Projects index page',
         type: :feature,
         js: true,
         with_settings: { login_required?: false } do

  let!(:admin) { FactoryGirl.create :admin }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let!(:custom_field) { FactoryGirl.create :project_custom_field }
  let!(:invisible_custom_field) { FactoryGirl.create :project_custom_field, visible: false }

  let!(:project) do
    FactoryGirl.create(:project,
                       name: 'Plain project',
                       identifier: 'plain-project')
  end
  let!(:public_project) do
    project = FactoryGirl.create(:project,
                                 name: 'Public project',
                                 identifier: 'public-project',
                                 is_public: true)
    project.custom_field_values = { invisible_custom_field.id => 'Secret CF' }
    project.save
    project
  end
  let!(:development_project) do
    FactoryGirl.create(:project,
                       name: 'Development project',
                       identifier: 'development-project')
  end

  def load_and_open_filters(user)
    login_as(user)
    visit projects_path
    click_button('Show/hide filters')
  end

  def set_filter(name, human_name, human_operator = nil, values = [])
    select human_name, from: 'add_filter_select'
    selected_filter = page.find("li[filter-name='#{name}']")

    within(selected_filter) do
      select human_operator, from: 'operator'

      return unless values.any?

      case name
      when 'name_and_identifier'
        set_name_and_identifier_filter(values)
      when 'status'
        set_status_filter(values)
      when 'created_on'
        set_created_on_filter(human_operator, values)
      when /cf_[\d]+/
        set_custom_field_filter(selected_filter, human_operator, values)
      end
    end
  end

  def set_name_and_identifier_filter(values)
    fill_in 'value', with: values.first
  end

  def set_status_filter(values)
    if values.size == 1
      select values.first, from: 'value'
    end
  end

  def set_created_on_filter(human_operator, values)
    case human_operator
    when 'on', 'less than days ago', 'more than days ago', 'days ago'
      fill_in 'value', with: values.first
    when 'between'
      fill_in 'from_value', with: values.first
      fill_in 'to_value', with: values.second
    end
  end

  def set_custom_field_filter(selected_filter, human_operator, values)
    if selected_filter[:'filter-type'] == 'list_optional'
      if values.size == 1
        value_select = find('.single-select select[name="value"]')
        value_select.select values.first
      end
    elsif selected_filter[:'filter-type'] == 'date'
      if human_operator == 'on'
        fill_in 'value', with: values.first
      end
    end
  end

  def allow_enterprise_edition
    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .and_return(false)
    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .with(:custom_fields_in_projects_list)
      .and_return(true)
  end

  def remove_filter(name)
    page.find("li[filter-name='#{name}'] .filter_rem").click
  end

  feature 'restricts project visibility' do
    feature 'for a anonymous user' do
      scenario 'only public projects shall be visible' do
        Role.anonymous
        visit projects_path

        expect(page).to_not have_text(project.name)
        expect(page).to have_text(public_project.name)

        # Test that the 'More' menu stays invisible on hover
        expect(page).to_not have_selector('.icon-show-more-horizontal')
      end
    end

    feature 'for project members' do
      let!(:user) do
        FactoryGirl.create(:user,
                           member_in_project: development_project,
                           member_through_role: developer,
                           login: 'nerd',
                           firstname: 'Alan',
                           lastname: 'Turing')
      end

      before do
        allow_enterprise_edition
      end

      scenario 'only public project or those the user is member of shall be visible' do
        Role.non_member
        login_as(user)
        visit projects_path

        expect(page).to have_text(development_project.name)
        expect(page).to have_text(public_project.name)
        expect(page).to_not have_text(project.name)

        # Non-admin users shall not see invisible CFs.
        expect(page).to_not have_text(invisible_custom_field.name.upcase)
        expect(page).to_not have_select('add_filter_select', with_options: [invisible_custom_field.name])
      end
    end

    feature 'for admins' do
      scenario 'test that all projects are visible' do
        login_as(admin)
        visit projects_path

        expect(page).to have_text(public_project.name)
        expect(page).to have_text(project.name)

        # because we use css opacity we can not test for the visibility changes
        expect(page).to have_selector('.icon-show-more-horizontal')

        # Test visiblity of 'more' menu list items
        page.first('tbody tr .icon-show-more-horizontal').click
        menu = page.first('tbody tr .project-actions')
        expect(menu).to have_text('Copy')
        expect(menu).to have_text('Project settings')
        expect(menu).to have_text('New subproject')
        expect(menu).to have_text('Delete')
        expect(menu).to have_text('Archive')
      end
    end
  end

  feature 'without valid Enterprise token' do
    scenario 'CF columns and filters are not visible' do
      load_and_open_filters admin

      # CF's columns are not present:
      expect(page).to_not have_text(custom_field.name.upcase)
      # CF's filters are not present:
      expect(page).to_not have_select('add_filter_select', with_options: [custom_field.name])
    end
  end

  feature 'with valid Enterprise token' do
    before do
      allow_enterprise_edition
    end

    scenario 'CF columns and filters are visible' do
      load_and_open_filters admin

      # CF's column is present:
      expect(page).to have_text(custom_field.name.upcase)
      # CF's filter is present:
      expect(page).to have_select('add_filter_select', with_options: [custom_field.name])

      # Admins shall be the only ones to see invisible CFs
      expect(page).to have_text(invisible_custom_field.name.upcase)
      expect(page).to have_select('add_filter_select', with_options: [invisible_custom_field.name])
    end
  end

  feature 'with a filter set' do
    scenario 'it should only show the matching projects and filters' do
      load_and_open_filters admin

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'contains',
                 ['Plain'])

      click_on 'Apply'
      # Filter is applied: Only the project that contains the the word "Plain" gets listed
      expect(page).to_not have_text(public_project.name)
      expect(page).to have_text(project.name)
      # Filter form is visible and the filter is still set.
      expect(page).to have_selector('li[filter-name="name_and_identifier"]')
    end
  end

  feature 'when paginating' do
    before do
      allow(Setting).to receive(:per_page_options_array).and_return([1, 5])
    end

    scenario 'it keeps applying filters and order' do
      load_and_open_filters admin

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'doesn\'t contain',
                 ['Plain'])

      click_on 'Apply'

      # Sorts ASC by name
      click_on 'Sort by "Name"'

      # Results should be filtered and ordered ASC by name
      expect(page).to have_text(development_project.name)
      expect(page).to_not have_text(project.name)        # as it filtered away
      expect(page).to have_text('Next')                  # as the result set is larger than 1
      expect(page).to_not have_text(public_project.name) # as it is on the second page

      # Changing the page size to 5 and back to 1 should not change the filters (which we test later on the second page)
      find('.pagination--options .pagination--item', text: '5').click # click page size '5'
      find('.pagination--options .pagination--item', text: '1').click # return back to page size '1'

      click_on '2' # Go to pagination page 2

      # On page 2 you should see the second page of the filtered set ordered ASC by name
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(project.name)             # Filtered away
      expect(page).to_not have_text('Next')                   # Filters kept active, so there is no third page.
      expect(page).to_not have_text(development_project.name) # That one should be on page 1

      # Sorts DESC by name
      click_on 'Ascending sorted by "Name"'

      # On page 2 the same filters should still be intact but the order should be DESC on name
      expect(page).to have_text(development_project.name)
      expect(page).to_not have_text(project.name)        # Filtered away
      expect(page).to_not have_text('Next')              # Filters kept active, so there is no third page.
      expect(page).to_not have_text(public_project.name) # That one should be on page 1

      # Sending the filter form again what implies to compose the request freshly
      click_on 'Apply'

      # We should see page 1, resetting pagination, as it is a new filter, but keeping the DESC order on the project
      # name
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(development_project.name) # as it is on the second page
      expect(page).to_not have_text(project.name)             # as it filtered away
      expect(page).to have_text('Next')                       # as the result set is larger than 1
    end
  end

  feature 'when filter of type' do
    scenario 'Name and identifier gives results in both, name and identifier' do
      load_and_open_filters admin

      # Filter on model attribute 'name'
      set_filter('name_and_identifier',
                 'Name or identifier',
                 'doesn\'t contain',
                 ['Plain'])

      click_on 'Apply'

      expect(page).to have_text(development_project.name)
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(project.name)

      # Filter on model attribute 'identifier'
      remove_filter('name_and_identifier')

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'is',
                 ['plain-project'])

      click_on 'Apply'

      expect(page).to have_text(project.name)
      expect(page).to_not have_text(development_project.name)
      expect(page).to_not have_text(public_project.name)
    end

    feature 'Active or archived' do
      let!(:archived_project) do
        FactoryGirl.create(:project,
                           name: 'Archived project',
                           identifier: 'archived-project',
                           status: Project::STATUS_ARCHIVED)
      end

      scenario 'filter on "status"' do
        load_and_open_filters admin

        # value selection defaults to "active"'
        expect(page).to have_selector('li[filter-name="status"]')

        # Filter has three operators 'all', 'active' and 'archived'
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="*"]')).to have_text('all')
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="="]')).to have_text('is')
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="!"]')).to have_text('is not')

        expect(page).to_not have_text('Archived project')
        expect(page).to have_text('Plain project')
        expect(page).to have_text('Development project')
        expect(page).to have_text('Public project')

        # Filter on model attribute 'status'
        set_filter('status',
                   'Active or archived',
                   'is',
                   ['archived'])

        click_on 'Apply'

        # Test visiblity of 'more' menu list items
        page.find('tbody tr').hover
        page.find('tbody tr .icon-show-more-horizontal').click
        menu = page.find('tbody tr .project-actions')
        expect(menu).to have_text('Unarchive')
        expect(menu).to have_text('Delete')
        expect(menu).to_not have_text('Archive')
        expect(menu).to_not have_text('Copy')
        expect(menu).to_not have_text('Settings')
        expect(menu).to_not have_text('New subproject')
      end
    end

    feature 'other filter types' do
      let!(:list_custom_field) { FactoryGirl.create :list_project_custom_field }
      let!(:date_custom_field) { FactoryGirl.create :date_project_custom_field }
      let(:datetime_of_this_week) do
        today = Date.today
        # Ensure that the date is not today but still in the middle of the week to not run into week-start-issues here.
        date_of_this_week = today + ((today.wday % 7) > 2 ? -1 : 1)
        DateTime.parse(date_of_this_week.to_s + 'T11:11:11+00:00')
      end
      let(:fixed_datetime) { DateTime.parse('2017-11-11T11:11:11+00:00') }

      let!(:project_created_on_today) do
        project = FactoryGirl.create(:project,
                                     name: 'Created today project',
                                     created_on: DateTime.now)
        project.custom_field_values = { list_custom_field.id => list_custom_field.possible_values[2],
                                        date_custom_field.id => '2011-11-11' }
        project.save!
        project
      end
      let!(:project_created_on_this_week) do
        FactoryGirl.create(:project,
                           name: 'Created on this week project',
                           created_on: datetime_of_this_week)
      end
      let!(:project_created_on_six_days_ago) do
        FactoryGirl.create(:project,
                           name: 'Created on six days ago project',
                           created_on: DateTime.now - 6.days)
      end
      let!(:project_created_on_fixed_date) do
        FactoryGirl.create(:project,
                           name: 'Created on fixed date project',
                           created_on: fixed_datetime)
      end
      let!(:todays_wp) do
        # This WP should trigger a change to the project's 'latest activity at' DateTime
        FactoryGirl.create(:work_package,
                           updated_at: DateTime.now,
                           project: project_created_on_today)
      end

      before do
        allow_enterprise_edition
        project_created_on_today
        load_and_open_filters admin
      end

      scenario 'selecting operator' do
        # created on 'today' shows projects that were created today
        set_filter('created_on',
                   'Created on',
                   'today')

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_this_week.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'this week' shows projects that were created within the last seven days
        remove_filter('created_on')

        set_filter('created_on',
                   'Created on',
                   'this week')

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to have_text(project_created_on_this_week.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'on' shows projects that were created within the last seven days
        remove_filter('created_on')

        set_filter('created_on',
                   'Created on',
                   'on',
                   ['2017-11-11'])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_this_week.name)

        # created on 'less than days ago'
        remove_filter('created_on')

        set_filter('created_on',
                   'Created on',
                   'less than days ago',
                   ['1'])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'more than days ago'
        remove_filter('created_on')

        set_filter('created_on',
                   'Created on',
                   'more than days ago',
                   ['1'])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)

        # created on 'between'
        remove_filter('created_on')

        set_filter('created_on',
                   'Created on',
                   'between',
                   ['2017-11-10', '2017-11-12'])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)

        # Latest activity at 'today'. This spot check would fail if the data does not get collected from multiple tables
        remove_filter('created_on')

        set_filter('latest_activity_at',
                   'Latest activity at',
                   'today')

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # CF List
        remove_filter('latest_activity_at')

        set_filter("cf_#{list_custom_field.id}",
                   list_custom_field.name,
                   'is',
                   [list_custom_field.possible_values[2].value])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # switching to multiselect keeps the current selection
        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Initial filter is a 'single select'
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
          click_on 'Toggle multiselect'
          # switching to multiselect keeps the current selection
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_truthy
          expect(cf_filter).to have_select('value', selected: list_custom_field.possible_values[2].value)

          select list_custom_field.possible_values[3].value, from: 'value'
        end

        click_on 'Apply'

        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Query has two values for that filter, so it shoud show a 'multi select'.
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_truthy
          expect(cf_filter)
            .to have_select('value',
                            selected: [list_custom_field.possible_values[2].value,
                                       list_custom_field.possible_values[3].value])

          # switching to single select keeps the first selection
          select list_custom_field.possible_values[1].value, from: 'value'
          unselect list_custom_field.possible_values[2].value, from: 'value'

          click_on 'Toggle multiselect'
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
          expect(cf_filter).to have_select('value', selected: list_custom_field.possible_values[1].value)
          expect(cf_filter).to_not have_select('value', selected: list_custom_field.possible_values[3].value)
        end

        click_on 'Apply'

        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Query has one value for that filter, so it should show a 'single select'.
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
        end

        # CF date filter work (at least for one operator)
        remove_filter("cf_#{list_custom_field.id}")

        set_filter("cf_#{date_custom_field.id}",
                   date_custom_field.name,
                   'on',
                   ['2011-11-11'])

        click_on 'Apply'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)
      end

      pending "NOT WORKING YET: Date vs. DateTime issue: Selecting same date for from and to value shows projects of that date"
    end
  end

  feature 'Non-admins with role with permission' do
    let!(:can_copy_projects_role) do
      FactoryGirl.create :role, name: 'Can Copy Projects Role', permissions: [:copy_projects]
    end
    let!(:can_add_subprojects_role) do
      FactoryGirl.create :role, name: 'Can Add Subprojects Role', permissions: [:add_subprojects]
    end

    let!(:parent_project) do
      FactoryGirl.create(:project,
                         name: 'Parent project',
                         identifier: 'parent-project')
    end

    let!(:can_copy_projects_manager) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: can_copy_projects_role)
    end
    let!(:can_add_subprojects_manager) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: can_add_subprojects_role)
    end
    let!(:simple_member) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: developer)
    end

    before do
      # We are not admin so we need to force the built-in roles to have them.
      Role.non_member

      # Remove public projects from the default list for these scenarios.
      public_project.update_attribute :status, Project::STATUS_ARCHIVED
    end

    scenario 'can see the "More" menu' do
      # For a simple project member the 'More' menu is not visible.
      login_as(simple_member)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      # 'More' does not become visible on hover
      page.find('tbody tr').hover
      expect(page).not_to have_selector('.icon-show-more-horizontal')

      # For a project member with :copy_projects privilege the 'More' menu is visible.
      login_as(can_copy_projects_manager)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      # 'More' becomes visible on hover
      # because we use css opacity we can not test for the visibility changes
      page.find('tbody tr').hover
      expect(page).to have_selector('.icon-show-more-horizontal')

      # Test visiblity of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('Copy')
      expect(menu).to_not have_text('New subproject')
      expect(menu).to_not have_text('Delete')
      expect(menu).to_not have_text('Archive')
      expect(menu).to_not have_text('Unarchive')

      # For a project member with :add_subprojects privilege the 'More' menu is visible.
      login_as(can_add_subprojects_manager)
      visit projects_path

      # 'More' becomes visible on hover
      # because we use css opacity we can not test for the visibility changes
      page.find('tbody tr').hover
      expect(page).to have_selector('.icon-show-more-horizontal')

      # Test visiblity of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('New subproject')
      expect(menu).to_not have_text('Copy')
      expect(menu).to_not have_text('Delete')
      expect(menu).to_not have_text('Archive')
      expect(menu).to_not have_text('Unrchive')
    end
  end

  feature 'order' do
    let!(:integer_custom_field) { FactoryGirl.create(:int_project_custom_field) }
    # order is important here as the implementation uses lft
    # first but then reorders in ruby
    let!(:child_project_z) do
      FactoryGirl.create(:project,
                         parent: project,
                         name: "Z Child")
    end
    let!(:child_project_a) do
      FactoryGirl.create(:project,
                         parent: project,
                         name: "A Child")
    end

    before do
      allow_enterprise_edition
      login_as(admin)
      visit projects_path

      project.custom_field_values = { integer_custom_field.id => 1 }
      project.save!
      development_project.custom_field_values = { integer_custom_field.id => 2 }
      development_project.save!
      public_project.custom_field_values = { integer_custom_field.id => 3 }
      public_project.save!
      child_project_z.custom_field_values = { integer_custom_field.id => 4 }
      child_project_z.save!
      child_project_a.custom_field_values = { integer_custom_field.id => 4 }
      child_project_a.save!
    end

    def expect_project_at_place(project, place)
      expect(page)
        .to have_selector("#project-table .project:nth-of-type(#{place}) td.name",
                          text: project.name)
    end

    def expect_projects_in_order(*projects)
      projects.each_with_index do |project, index|
        expect_project_at_place(project, index + 1)
      end
    end

    scenario 'allows to alter the order in which projects are displayed' do
      # initially, ordered by name asc on each hierarchical level
      expect_projects_in_order(development_project,
                               project,
                               child_project_a,
                               child_project_z,
                               public_project)

      click_link('Name')

      # Projects ordered by name asc
      expect_projects_in_order(child_project_a,
                               development_project,
                               project,
                               public_project,
                               child_project_z)

      click_link('Name')

      # Projects ordered by name desc
      expect_projects_in_order(child_project_z,
                               public_project,
                               project,
                               development_project,
                               child_project_a)

      click_link(integer_custom_field.name)

      # Projects ordered by cf asc first then project name desc
      expect_projects_in_order(project,
                               development_project,
                               public_project,
                               child_project_z,
                               child_project_a)

      click_link('Sort by "Project hierarchy"')

      # again ordered by name asc on each hierarchical level
      expect_projects_in_order(development_project,
                               project,
                               child_project_a,
                               child_project_z,
                               public_project)
    end
  end
end
