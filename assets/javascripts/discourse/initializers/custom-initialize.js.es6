import { PLUGIN_API_VERSION, withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "custom-initialize",
  initialize() {
    withPluginApi(PLUGIN_API_VERSION, (api) => {
      console.log("Inizializzo plugin");
    });
  },
};
