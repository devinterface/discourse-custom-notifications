import { registerHelper } from "discourse-common/lib/helpers";

registerHelper("check-moderatori", checkModeratori);

export default function checkModeratori(args) {
  let groups = args[0];
  for (let i = 0; i < groups.length; i++) {
    if (groups[i]["name"] == "Moderatori") {
      return true;
    }
  }
  return false;
}
