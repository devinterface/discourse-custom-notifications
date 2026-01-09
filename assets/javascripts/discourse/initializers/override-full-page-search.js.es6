import { PLUGIN_API_VERSION, withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse/lib/decorators";

export default {
  name: "override-full-page-search-can-bulk-select",
  initialize() {
    withPluginApi(PLUGIN_API_VERSION, (api) => {
      console.log("Override full page search!");
      api.modifyClass(
        "controller:full-page-search",
        (Superclass) =>
          class extends Superclass {
            @discourseComputed("hasResults")
            canBulkSelect(hasResults) {
              return this.currentUser && hasResults;
            }
          }
      );
    });
  },
};
