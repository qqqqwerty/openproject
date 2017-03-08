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
require 'rack/test'

describe 'API v3 Query resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get projects/:project_id/queries/default' do
    let(:base_path) { api_v3_paths.query_project_default(project.id) }

    it_behaves_like 'GET individual query' do
      context 'lacking permissions' do
        let(:permissions) { [] }

        it_behaves_like 'unauthorized access'
      end
    end
  end

  describe '#post projects/:project_id/queries/form' do
    let(:path) { api_v3_paths.query_project_form(project.identifier) }

    before do
      post path
    end

    it 'succeeds' do
      expect(last_response.status).to eq(200)
    end

    it 'returns the form' do
      expect(last_response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end
  end
end