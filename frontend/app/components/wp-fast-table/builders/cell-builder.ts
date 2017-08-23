import {WorkPackageResourceInterface} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {
  DisplayFieldRenderer,
  editFieldContainerClass
} from '../../wp-edit-form/display-field-renderer';
export const tdClassName = 'wp-table--cell-td';
export const editCellContainer = 'wp-table--cell-container';
export const wpCellTdClassName = 'wp-table--cell-td';

export class CellBuilder {

  private fieldRenderer = new DisplayFieldRenderer('table');

  public build(workPackage:WorkPackageResourceInterface, attribute:string) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, wpCellTdClassName, attribute);

    const container = document.createElement('span');
    container.classList.add(editCellContainer, editFieldContainerClass, attribute);
    const displayElement = this.fieldRenderer.render(workPackage, attribute);

    container.appendChild(displayElement);
    td.appendChild(container);

    if (name === 'status') {
        var background_color: string = this.getWorkPackageState(workPackage.status.href, workPackage.dayBeforeWarning, workPackage.warningColor);
        if (background_color != null) {
            td.setAttribute('bgcolor', background_color);
        }
    }

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResourceInterface, attribute:string) {
    const displayElement = this.fieldRenderer.render(workPackage, attribute);

    container.innerHTML = '';
    container.appendChild(displayElement);
  }

    private getWorkPackageState(status_href:string, day_before_warning:number, warning_color:number): string {
      var colors: string[] = ['', 'cyan', 'yellow', 'red', 'orange'];
      var last_day = new Date(day_before_warning); 
      last_day.setHours(0, 0, 0, 0);

      if (isNaN(last_day.getFullYear()) ||
         isNaN(last_day.getMonth()) ||
         isNaN(last_day.getDate())) {
          return colors[3];
      }

      var badStatuses: number[] = [15, 17];

      var pieces: string[] = status_href.split(/[\/]+/);
      var id: number = Number(pieces[pieces.length-1]);

      if (badStatuses.indexOf(id) > -1) {
          return colors[4];
      }

      var today = new Date();
      today.setHours(0, 0, 0, 0);     

      if(last_day.getTime() < today.getTime()){
          return colors[warning_color];
      }
      return colors[0];
    }
}
