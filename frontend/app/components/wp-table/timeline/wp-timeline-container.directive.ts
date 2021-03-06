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
import {openprojectModule} from "../../../angular-modules";
import {TimelineViewParameters, RenderInfo, timelineElementCssClass} from "./wp-timeline";
import {WorkPackageResourceInterface} from "./../../api/api-v3/hal-resources/work-package-resource.service";
import {HalRequestService} from '../../api/api-v3/hal-request/hal-request.service';
import {WpTimelineHeader} from "./wp-timeline.header";
import {States} from "./../../states.service";
import {BehaviorSubject, Observable} from "rxjs";
import * as moment from 'moment';
import Moment = moment.Moment;
import IDirective = angular.IDirective;
import IScope = angular.IScope;
import { WpTimelineGlobalService } from "./wp-timeline-global.directive";
import { opDimensionEventName } from "../../common/ui/detect-dimension-changes.directive";

export class WorkPackageTimelineTableController {

  private _viewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackageResourceInterface} = {};

  public wpTimelineHeader: WpTimelineHeader;

  public readonly globalService = new WpTimelineGlobalService(this.$scope, this.states, this.halRequest);

  private updateAllWorkPackagesSubject = new BehaviorSubject<boolean>(true);

  private refreshViewRequested = false;

  public visible = false;

  public disableViewParamsCalculation = false;

  constructor(private $scope: IScope,
              private $element: ng.IAugmentedJQuery,
              private TypeResource:any,
              private states: States,
              private halRequest: HalRequestService) {

    "ngInject";

    this.wpTimelineHeader = new WpTimelineHeader(this);
    $element.on(opDimensionEventName, () => {
      this.refreshView();
    });

    states.table.timelineVisible
      .observeOnScope($scope)
      .subscribe((visible) => {

        if (visible) {
          this.refreshView();
        }
    });

    // TODO: Load only necessary types from API
    TypeResource.loadAll();
  }

  /**
   * Toggle whether this instance is currently showing.
   */
  public toggle() {
    this.visible = !this.visible;
    this.states.table.timelineVisible.put(this.visible);
  }

  /**
   * Returns a defensive copy of the currently used view parameters.
   */
  getViewParametersCopy(): TimelineViewParameters {
    return _.cloneDeep(this._viewParameters);
  }

  get viewParameterSettings() {
    return this._viewParameters.settings;
  }

  refreshView() {
    if (!this.refreshViewRequested) {
      setTimeout(() => {
        this.calculateViewParams(this._viewParameters);
        this.updateAllWorkPackagesSubject.next(true);
        this.wpTimelineHeader.refreshView(this._viewParameters);
        this.refreshScrollOnly();
        this.refreshViewRequested = false;
      }, 30);
    }
    this.refreshViewRequested = true;
  }

  refreshScrollOnly() {
    jQuery("." + timelineElementCssClass).css("margin-left", this._viewParameters.scrollOffsetInPx + "px");
  }

  addWorkPackage(wpId: string): Observable<RenderInfo> {

    const wpObs = this.states.workPackages.get(wpId).observeOnScope(this.$scope)
      .map((wp: any) => {
        this.workPackagesInView[wp.id] = wp;
        const viewParamsChanged = this.calculateViewParams(this._viewParameters);
        if (viewParamsChanged) {
          // view params have changed, notify all cells
          this.globalService.updateViewParameter(this._viewParameters);
          this.refreshView();
        }

        return {
          viewParams: this._viewParameters,
          workPackage: wp
        };
      });

    return Observable.combineLatest(
        wpObs,
        this.updateAllWorkPackagesSubject,
        (renderInfo: RenderInfo, forceUpdate: boolean) => {
          return renderInfo;
        }
      );
  }

  private calculateViewParams(currentParams: TimelineViewParameters): boolean {
    if (this.disableViewParamsCalculation) {
      return false;
    }

    const newParams = new TimelineViewParameters();
    let changed = false;

    // Calculate view parameters
    for (const wpId in this.workPackagesInView) {
      const workPackage = this.workPackagesInView[wpId];

      const startDate = workPackage.startDate ? moment(workPackage.startDate) : currentParams.now;
      const dueDate = workPackage.dueDate ? moment(workPackage.dueDate) : currentParams.now;
      const date = workPackage.date ? moment(workPackage.date) : currentParams.now;

      // start date
      newParams.dateDisplayStart = moment.min(
        newParams.dateDisplayStart,
        currentParams.now,
        startDate,
        date);

      // due date
      newParams.dateDisplayEnd = moment.max(
        newParams.dateDisplayEnd,
        currentParams.now,
        dueDate,
        date);
    }

    // left spacing
    newParams.dateDisplayStart.subtract(3, "days");

    // right spacing
    const headerWidth = this.wpTimelineHeader.getHeaderWidth();
    const pixelPerDay = currentParams.pixelPerDay;
    const visibleDays = Math.ceil((headerWidth / pixelPerDay) * 1.5);
    newParams.dateDisplayEnd.add(visibleDays, "days");

    // Check if view params changed:

    // start date
    if (!newParams.dateDisplayStart.isSame(this._viewParameters.dateDisplayStart)) {
      changed = true;
      this._viewParameters.dateDisplayStart = newParams.dateDisplayStart;
    }

    // end date
    if (!newParams.dateDisplayEnd.isSame(this._viewParameters.dateDisplayEnd)) {
      changed = true;
      this._viewParameters.dateDisplayEnd = newParams.dateDisplayEnd;
    }


    this._viewParameters.timelineHeader = this.wpTimelineHeader;

    return changed;
  }
}


function wpTimelineContainer() {
  return {
    restrict: 'A',
    controller: WorkPackageTimelineTableController,
    bindToController: true
  };
}

openprojectModule.directive('wpTimelineContainer', wpTimelineContainer);
