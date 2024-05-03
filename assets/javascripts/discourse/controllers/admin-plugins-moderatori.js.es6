import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class AdminPLuginsModeratoriController extends Controller {
  @tracked showText = false;

  @action
  showTentacle() {
    this.showText = !this.showText;
    console.log("PLUGIN");
    ajax("/moderatori", {}).then((uploads) => console.log(uploads));
  }
}
