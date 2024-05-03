import { ajax } from "discourse/lib/ajax";

export default class Moderatori {
  static findAll(userFilter) {
    return ajax(`/admin/attachments.json`, {
      data: userFilter,
    }).then((uploads) => uploads);
  }
}
