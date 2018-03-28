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

TypedDag::Configuration.set node_class_name: 'WorkPackage',
                            edge_class_name: 'Relation',
                            ancestor_column: 'from_id',
                            descendant_column: 'to_id',
                            types: {
                              hierarchy: { from: { name: :parent, limit: 1 },
                                           to: :children,
                                           all_from: :ancestors,
                                           all_to: :descendants },
                              relates: { from: :related_to,
                                         to: :relates_to,
                                         all_from: :all_related_to,
                                         all_to: :all_relates_to },
                              duplicates: { from: :duplicates,
                                            to: :duplicated,
                                            all_from: :all_duplicates,
                                            all_to: :all_duplicated },
                              follows: { from: :precedes,
                                         to: :follows,
                                         all_from: :all_precedes,
                                         all_to: :all_follows },
                              blocks: { from: :blocked_by,
                                        to: :blocks,
                                        all_from: :all_blocked_by,
                                        all_to: :all_blocks },
                              includes: { from: :part_of,
                                          to: :includes,
                                          all_from: :all_part_of,
                                          all_to: :all_includes },
                              requires: { from: :required_by,
                                          to: :requires,
                                          all_from: :all_required_by,
                                          all_to: :all_requires }
                            }

# Hacking the after_* callbacks to be positioned after the callbacks
# for the typed_dag so that the transitive relations are properly adapted before
# the path is build.
module RelationHierarchyIncluder
  def self.prepended(base)
    included_block = base.instance_variable_get(:@_included_block)

    new_includer = Proc.new do
      class_eval(&included_block)

      include Relation::HierarchyPaths
    end

    base.instance_variable_set(:@_included_block, new_includer)
  end
end

TypedDag::Edge::ClosureMaintenance.prepend(RelationHierarchyIncluder)
