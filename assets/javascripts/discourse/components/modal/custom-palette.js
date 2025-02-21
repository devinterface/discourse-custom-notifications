import Component from "@glimmer/component";
import { action } from "@ember/object";
import { cancel } from "@ember/runloop";

export default class CustomPalette extends Component {
  _debounced;

  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this._debounced);
  }

  // KEEP THIS FUNCTION
  @action
  keyDown(event) {}

  // KEEP THIS FUNCTION
  @action
  mouseDown(event) {}

  @action
  setColor(color) {
    this.args.model.toolbarEvent.addText(color);
    this.args.closeModal();
  }
}
