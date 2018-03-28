import {debugLog} from '../../../../helpers/debug_output';
import {$injectFields, injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';
import {KeepTabService} from "../../../wp-panels/keep-tab/keep-tab.service";
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';

export class RowClickHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public states:States;
  public keepTab:KeepTabService;
  public wpTableSelection:WorkPackageTableSelection;
  public wpTableFocus:WorkPackageTableFocusService;

  private clicks = 0;
  private timer:number;

  constructor(table:WorkPackageTable) {
    $injectFields(this, 'keepTab', '$state', 'states', 'wpTableSelection', 'wpTableFocus');
  }

  public get EVENT() {
    return 'click.table.row';
  }

  public get SELECTOR() {
    return `.${tableRowClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (target.parents(`.${tdClassName}`).length) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let wpId = element.data('workPackageId');
    let classIdentifier = element.data('classIdentifier');

    if (!wpId) {
      return true;
    }

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    let [index, row] = table.findRenderedRow(classIdentifier);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.wpTableSelection.setMultiSelectionFrom(table.renderedRows, wpId, index);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(wpId);
    }

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    this.wpTableFocus.updateFocus(wpId);
    return false;
  }
}

