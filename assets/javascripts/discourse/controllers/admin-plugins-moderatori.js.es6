import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class AdminPLuginsModeratoriController extends Controller {
  @tracked showText = false;
  @tracked createUserText = "";
  @tracked editEmailText = "";

  @action
  showTentacle() {
    this.showText = !this.showText;
    console.log("PLUGIN");
    ajax("/moderatori", {}).then((uploads) => console.log(uploads));
  }

  @action
  createUser() {
    let new_email = document.getElementById("new_email_create").value;
    let new_username = document.getElementById("new_username_create").value;
    let new_password = document.getElementById("new_password_create").value;

    if (new_email == "") {
      this.createUserText = "Inserisci email";
      return;
    } else if (new_username == "") {
      this.createUserText = "Inserisci username";
      return;
    } else if (new_password == "") {
      this.createUserText = "Inserisci password";
      return;
    } else if (new_password.length < 12) {
      console.log(new_password);
      this.createUserText = "Lunghezza minima password: 12";
      return;
    } else {
      $.ajax({
        type: "POST",
        url: "/custom_create_user",
        data: {
          new_email: new_email,
          new_username: new_username,
          new_password: new_password,
        },
        success: (response) => {
          this.createUserText = response["text"].toString();
        },
        error: function (xhr) {
          console.error("Errore", xhr);
        },
      });
    }
  }

  @action
  editEmail() {
    let old_email = document.getElementById("old_email_edit").value;
    let new_email = document.getElementById("new_email_edit").value;
    if (old_email == "") {
      this.editEmailText = "Inserisci vecchia email";
      return;
    } else if (new_email == "") {
      this.editEmailText = "Inserisci nuova email";
      return;
    } else if (old_email == new_email) {
      this.editEmailText = "Le email sono uguali";
      return;
    } else {
      $.ajax({
        type: "POST",
        url: "/custom_update_email",
        data: {
          old_email: old_email,
          new_email: new_email,
        },
        success: (response) => {
          this.editEmailText = response["text"].toString();
        },
        error: function (xhr) {
          console.error("Errore", xhr);
        },
      });
    }
  }
}
