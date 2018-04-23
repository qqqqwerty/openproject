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

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :roadmap, only: :roadmap
  menu_item :settings, only: :settings

  helper :timelines

  before_action :disable_api
  before_action :find_project, except: [:index, :level_list, :new, :create, :un_archive_selected]
  before_action :authorize, only: [
    :show, :settings, :edit, :update, :modules, :types, :custom_fields
  ]
  before_action :authorize_global, only: [:new, :create]
  before_action :require_admin, only: [:archive, :unarchive, :destroy, :destroy_info, :un_archive_selected]
  before_action :jump_to_project_menu_item, only: :show
  before_action :load_project_settings, only: :settings
  before_action :determine_base

  accept_key_auth :index, :level_list, :show, :create, :update, :destroy, :un_archive_selected

  include SortHelper
  include PaginationHelper
  include CustomFieldsHelper
  include QueriesHelper
  include RepositoriesHelper
  include ProjectsHelper

  # Lists visible projects
  def index
    query = load_query
    set_sorting(query)

    unless query.valid?
      flash[:error] = query.errors.full_messages
    end

    @projects = load_projects query
    @custom_fields = ProjectCustomField.visible(User.current)

    respond_to do |format|
      format.atom do
        head(:gone)
      end
      format.html do
        render action: :index
      end
    end
  end

  current_menu_item :index do
    :list_projects
  end

  def new
    @issue_custom_fields = WorkPackageCustomField.order("#{CustomField.table_name}.position")
    @types = ::Type.all
    @project = Project.new
    @project.parent = Project.find(params[:parent_id]) if params[:parent_id]
    @project.attributes = permitted_params.project if params[:project].present?
  end

  current_menu_item :new do
    :new_project
  end

  def create
    @issue_custom_fields = WorkPackageCustomField.order("#{CustomField.table_name}.position")
    @types = ::Type.all
    @project = Project.new
    @project.attributes = permitted_params.project

    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params['project']['parent_id']) if params['project'].has_key?('parent_id')
      add_current_user_to_project_if_not_admin(@project)
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_work_packages_or_overview
        end
      end
    else
      respond_to do |format|
        format.html do render action: 'new' end
      end
    end
  end

  # Show @project
  def show
    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible
    @news = @project.news.limit(5).includes(:author, :project).order("#{News.table_name}.created_on DESC")
    @types = @project.rolled_up_types

    cond = @project.project_condition(Setting.display_subprojects_work_packages?)

    @open_issues_by_type = WorkPackage
                           .visible.group(:type)
                           .includes(:project, :status, :type)
                           .where(["(#{cond}) AND #{Status.table_name}.is_closed=?", false])
                           .references(:projects, :statuses, :types)
                           .count
    @total_issues_by_type = WorkPackage
                            .visible.group(:type)
                            .includes(:project, :status, :type)
                            .where(cond)
                            .references(:projects, :statuses, :types)
                            .count

    respond_to do |format|
      format.html
    end
  end

  def settings
    @altered_project ||= @project
  end

  def edit; end

  def update
    @altered_project = Project.find(@project.id)

    @altered_project.attributes = permitted_params.project
    if validate_parent_id && @altered_project.save
      if params['project'].has_key?('parent_id')
        @altered_project.set_allowed_parent!(params['project']['parent_id'])
      end
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to action: 'settings', id: @altered_project
        end
      end
      OpenProject::Notifications.send('project_updated', project: @altered_project)
    else
      respond_to do |format|
        format.html do
          load_project_settings
          render action: 'settings'
        end
      end
    end
  end

  def update_identifier
    @project.attributes = permitted_params.project

    if @project.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to action: 'settings', id: @project
        end
      end
      OpenProject::Notifications.send('project_renamed', project: @project)
    else
      respond_to do |format|
        format.html do
          load_project_settings
          render action: 'identifier'
        end
      end
    end
  end

  def types
    if UpdateProjectsTypesService.new(@project).call(permitted_params.projects_type_ids)
      flash[:notice] = l('notice_successful_update')
    else
      flash[:error] = @project.errors.full_messages
    end

    redirect_to settings_project_path(@project.identifier, tab: 'types')
  end

  def modules
    @project.enabled_module_names = permitted_params.project[:enabled_module_names]
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'settings', id: @project, tab: 'modules'
  end

  def custom_fields
    Project.transaction do
      @project.work_package_custom_field_ids = permitted_params.project[:work_package_custom_field_ids]
      if @project.save
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = t(:notice_project_cannot_update_custom_fields,
                          errors: @project.errors.full_messages.join(', '))
        raise ActiveRecord::Rollback
      end
    end
    redirect_to action: 'settings', id: @project, tab: 'custom_fields'
  end

  def archive
    flash[:error] = l(:error_can_not_archive_project) unless @project.archive
    redirect_to(url_for(controller: '/projects', action: 'index', status: params[:status]))
  end
  
  def un_archive_selected
    flash[:error] = l(:error_can_not_un_archive_projects)
    errors_count = 0
    affected_count = 0
    total_count = 0
    if !params[:projects].nil?
      params[:projects].each do |project_id|
        project = Project.find_by id: project_id.to_i
        if project
          total_count = total_count + 1
        end
        if params[:archive] == 'true'
          if !project.archived?
            unless project.archive
              flash[:error] = flash[:error] + project.name + ', '
              errors_count = errors_count + 1
            else
              affected_count = affected_count + 1
            end
          end
        else
          if project.archived?
            unless project.unarchive
              flash[:error] = flash[:error] + project.name + ', '
              errors_count = errors_count + 1 
            else
              affected_count = affected_count + 1
            end
          end
        end
      end
    end
    if errors_count == 0
      flash.clear
      flash[:notice] = l(:notice_no_projects_affected, affected: affected_count, total: total_count)
    end
    redirect_to(url_for(controller: '/projects', action: 'index', status: params[:status]))
  end

  def unarchive
    @project.unarchive if !@project.active?
    redirect_to(url_for(controller: '/projects', action: 'index', status: params[:status]))
  end
  
  # Delete @project
  def destroy
    @project_to_destroy = @project

    OpenProject::Notifications.send('project_deletion_imminent', project: @project_to_destroy)
    @project_to_destroy.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_to controller: '/admin', action: 'projects'
      end
    end

    hide_project_in_layout
  end

  def destroy_info
    @project_to_destroy = @project

    hide_project_in_layout
  end

  private

  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_work_packages_or_overview
    return if redirect_to_project_menu_item(@project, :work_packages)

    redirect_to controller: '/projects', action: 'show', id: @project
  end

  def jump_to_project_menu_item
    if params[:jump]
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(@project, params[:jump]) && return
    end
  end

  def load_project_settings
    @issue_custom_fields = WorkPackageCustomField.order("#{CustomField.table_name}.position")
    @category ||= Category.new
    @member ||= @project.members.new
    @types = ::Type.all
    @repository ||= @project.repository
    @wiki ||= @project.wiki
  end

  def hide_project_in_layout
    @project = nil
  end

  def add_current_user_to_project_if_not_admin(project)
    unless User.current.admin?
      r = Role.givable.find_by(id: Setting.new_project_user_role_id.to_i) || Role.givable.first
      m = Member.new do |member|
        member.user = User.current
        member.role_ids = [r].map(&:id) # member.roles = [r] fails, this works
      end
      project.members << m
    end
  end

  def load_query
    @query = ParamsToQueryService.new(Project, current_user).call(params)

    # Set default filter on status no filter is provided.
    if !params[:filters]
      @query.where('status', '=', Project::STATUS_ACTIVE.to_s)
    end

    # Order lft if no order is provided.
    if !params[:sortBy]
      @query.order(lft: :asc)
    end

    @query
  end

  def filter_projects_by_permission(projects)
    # Cannot simply use .visible here as it would
    # filter out archived projects for everybody.
    if User.current.admin?
      projects
    else
      projects.visible
    end
  end

  protected

  def determine_base
    @base = if params[:project_type_id]
              ProjectType.find(params[:project_type_id]).projects
            else
              Project
            end
  end

  def set_sorting(query)
    orders = query.orders.select(&:valid?).map { |o| [o.attribute.to_s, o.direction.to_s] }

    sort_clear
    sort_init orders
    sort_update orders.map(&:first)
  end

  def load_projects(query)
    projects = query
               .results
               .with_required_storage
               .with_latest_activity
               .includes(:custom_values, :enabled_modules)
               .page(page_param)
               .per_page(per_page_param)

    filter_projects_by_permission projects
  end

  # Validates parent_id param according to user's permissions
  # TODO: move it to Project model in a validation that depends on User.current
  def validate_parent_id
    return true if User.current.admin?
    parent_id = permitted_params.project && params[:project][:parent_id]
    if parent_id || @project.new_record?
      parent = parent_id.blank? ? nil : Project.find_by(id: parent_id.to_i)
      unless @project.allowed_parents.include?(parent)
        @project.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end
