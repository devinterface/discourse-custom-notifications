import { PLUGIN_API_VERSION, withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "bbcode-init",
  initialize() {
    withPluginApi(PLUGIN_API_VERSION, (api) => {
      console.log("Inizializzo plugin");

      // DA GITHUB
      const hasAlpha = /(.,){3}|\//;
      const MAX_LENGTH = 25;

      const getVariable = (value) => {
        const color = value.replace(/\s/g, "");
        return hasAlpha.test(color) || color.length > MAX_LENGTH ? "" : color;
      };

      const colors = [
        { name: "Select an option", value: "" },
        { name: "Yellow", value: "yellow" },
        { name: "Red", value: "red" },
        { name: "Blue", value: "blue" },
        { name: "Green", value: "green" },
      ];

      api.onToolbarCreate((toolbar) => {
        toolbar.addButton({
          id: "color_ui_button",
          group: "extras",
          icon: "palette",
          title: "Color the text",
          perform: (e) => {
            const existingSelect = document.getElementById(
              "color_picker_select"
            );
            if (existingSelect) {
              existingSelect.remove();
            }

            const select = document.createElement("select");
            select.id = "color_picker_select";
            select.style.position = "absolute";
            select.style.top = "100px";
            select.style.left = "10px";

            colors.forEach((color) => {
              const option = document.createElement("option");
              option.value = color.value;
              option.textContent = color.name;
              select.appendChild(option);
            });

            select.addEventListener("change", () => {
              const selectedColor = select.value;
              e.applySurround(
                `[wrap=color color=black bgcolor=${selectedColor}]`,
                "[/wrap]",
                "placeholder_coloured_text"
              );
              select.remove();
            });

            document.body.appendChild(select);
          },
        });
      });

      api.decorateCookedElement(
        (post) => {
          post
            .querySelectorAll("[data-color]")
            .forEach((i) =>
              i.style.setProperty("--color", getVariable(i.dataset.color))
            );

          post
            .querySelectorAll("[data-bgcolor]")
            .forEach((i) =>
              i.style.setProperty("--bgcolor", getVariable(i.dataset.bgcolor))
            );
        },
        { id: "wrap-colors" }
      );
    });
  },
};
