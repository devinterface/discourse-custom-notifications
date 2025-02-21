import { PLUGIN_API_VERSION, withPluginApi } from "discourse/lib/plugin-api";
import CustomPalette from "../components/modal/custom-palette";

export default {
  name: "custom-initializer",
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

      api.onToolbarCreate((toolbar) => {
        toolbar.addButton({
          id: "color_ui_button",
          group: "extras",
          icon: "palette",
          title: "Color the text",
          perform: (e) => {
            api.container.lookup("service:modal").show(CustomPalette, {
              model: {
                toolbarEvent: {
                  addText: (text) => {
                    e.applySurround(
                      `[bgcolor=${text}]`,
                      "[/bgcolor]",
                      "placeholder_coloured_text"
                    );
                  },
                },
              },
            });
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
