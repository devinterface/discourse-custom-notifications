import { addBulkDropdownButton } from "discourse/components/bulk-select-topics-dropdown";
addBulkDropdownButton({
  id: "button-export-csv",
  label: "custom.export_topic_csv",
  icon: "file",
  class: "btn-default",
  visible: ({ currentUser }) => true,
  allowSilent: true,
  actionType: "performAndRefresh",
  action: () => {
    let topics_id = [];
    const listItems = document.querySelectorAll('div[role="listitem"]');

    listItems.forEach((item) => {
      const bulkSelectSpan = item.querySelector("span.bulk-select");

      if (bulkSelectSpan) {
        const checkbox = bulkSelectSpan.querySelector('input[type="checkbox"]');

        if (checkbox && checkbox.checked) {
          const topicDiv = item.querySelector("div[data-topic-id]");

          if (topicDiv) {
            const topicId = topicDiv.getAttribute("data-topic-id");
            topics_id.push(topicId);
          } else {
          }
        }
      }
    });
    $.ajax({
      type: "POST",
      url: "/download_csv_topics",
      data: { topics_id: topics_id },
      xhrFields: {
        responseType: "blob",
      },
      success: function (blob, status, xhr) {
        const disposition = xhr.getResponseHeader("Content-Disposition");
        const filename = disposition
          ? disposition.match(/filename="(.+)"/)[1]
          : "download.csv";

        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      },
      error: function (xhr) {
        console.error("Errore durante il download del CSV", xhr);
      },
    });
    location.reload();
  },
});
