// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {opWorkPackagesModule} from '../../../angular-modules';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {debugLog} from '../../../helpers/debug_output';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from '../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from '../../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {WorkPackageEditFieldGroupController} from "../../wp-edit/wp-edit-field/wp-edit-field-group.directive";
import {
  WorkPackageEditingService
} from '../../wp-edit-form/work-package-editing-service';
import {States} from '../../states.service';
import {CurrentProjectService} from '../../projects/current-project.service';

interface FieldDescriptor {
  name:string;
  label:string;
  field?:DisplayField;
  fields?:DisplayField[];
  spanAll:boolean;
  multiple:boolean;
}

export class WorkPackageProjectContextViewController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupController;
  public workPackage:WorkPackageResourceInterface;

  public projectContext:{
    matches:boolean,
    href:string|null,
    field?:FieldDescriptor[]
  };
  public text:any;

  constructor(protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $stateParams:ng.ui.IStateParamsService,
              protected I18n:op.I18n,
              protected currentProject:CurrentProjectService,
              protected PathHelper:any,
              protected states:States,
              protected wpEditing:WorkPackageEditingService,
              protected wpDisplayField:WorkPackageDisplayFieldService,
              protected wpCacheService:WorkPackageCacheService) {
  }

  public initialize() {
    // Create I18n texts
    this.setupI18nTexts();

    scopedObservable(this.$scope, this.wpEditing.temporaryEditResource(this.workPackage.id).values$())
      .subscribe((resource:WorkPackageResourceInterface) => {
        // Prepare the fields that are required always
        const isNew = this.workPackage.isNew;

        if (!resource.project) {
          this.projectContext = { matches: false, href: null };
        } else {
          this.projectContext = {
            href: this.PathHelper.projectWorkPackagePath(resource.project.idFromLink, this.workPackage.id),
            matches: resource.project.href === this.currentProject.apiv3Path
          };
        }

        if (isNew && !this.currentProject.inProjectContext) {
          this.projectContext.field = this.getFields(resource, ['project']);
        }
      });
  }

  /*
   * Returns the work package label
   */
  public get idLabel() {
    return `#${this.workPackage.id}`;
  }

  public get projectContextText():string {
    let id = this.workPackage.project.idFromLink;
    let projectPath = this.PathHelper.projectPath(id);
    let project = `<a href="${projectPath}">${this.workPackage.project.name}<a>`;
    return this.I18n.t('js.project.work_package_belongs_to', { projectname: project });
  }

  private setupI18nTexts() {
    this.text = {
      project: {
        required: this.I18n.t('js.project.required_outside_context'),
        context: this.I18n.t('js.project.context'),
        switchTo: this.I18n.t('js.project.click_to_switch_context'),
      },
    };
  }

  /**
   * Maps the grouped fields into their display fields.
   * May return multiple fields (for the date virtual field).
   */
  private getFields(resource:WorkPackageResourceInterface, fieldNames:string[]):FieldDescriptor[] {
    const descriptors:FieldDescriptor[] = [];

    fieldNames.forEach((fieldName:string) => {
      /*if (fieldName === 'date') {
        descriptors.push(this.getDateField(resource));
        return;
      }*/

      if (!resource.schema[fieldName]) {
        debugLog('Unknown field for current schema', fieldName);
        return;
      }

      const field:DisplayField = this.displayField(resource, fieldName);
      descriptors.push({
        name: fieldName,
        label: field.label,
        multiple: false,
        spanAll: field.isFormattable,
        field: field
      });
    });

    return descriptors;
  }

  private displayField(resource:WorkPackageResourceInterface, name:string):DisplayField {
    return this.wpDisplayField.getField(
      resource,
      name,
      resource.schema[name]
    ) as DisplayField;
  }

  private get form() {
    return this.wpEditFieldGroup.form;
  }

}

function wpProjectContextViewDirective():any {

  return {
    restrict: 'E',
    templateUrl: '/components/work-packages/wp-project-context-view/wp-project-context-view.directive.html',

    scope: {
      workPackage: '=?'
    },

    require: ['^wpEditFieldGroup'],
    link: (scope:any,
           element:ng.IAugmentedJQuery,
           attrs:any,
           controllers: [WorkPackageEditFieldGroupController]) => {
      scope.$ctrl.wpEditFieldGroup = controllers[0];
      scope.$ctrl.initialize();
    },
    bindToController: true,
    controller: WorkPackageProjectContextViewController,
    controllerAs: '$ctrl'
  };
}

opWorkPackagesModule.directive('wpProjectContextView', wpProjectContextViewDirective);