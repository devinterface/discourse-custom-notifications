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
    let topic_id_selected = [];    

    if (document.querySelector('tbody.topic-list-body')) {
      // sono nella home
      get_topics_selected_home();
      export_csv();
    }
    else {
      // sono nella ricerca
      get_topics_selected_search();
      export_csv();
    }
    

    async function get_topics_selected_search() {
      document.querySelectorAll('div[role="listitem"]').forEach((item) => {
        let checkbox = item.querySelector("span.bulk-select").querySelector('input[type="checkbox"]');
        if (checkbox.checked) {
          topic_id_selected.push(parseInt(item.querySelector("div[data-topic-id]").getAttribute("data-topic-id")));
        }
      });
    }

    async function get_topics_selected_home() {
      document.querySelector('tbody.topic-list-body').querySelectorAll("tr").forEach((item) => {
        let checkbox = item.querySelector("td.bulk-select").querySelector('input[type="checkbox"]');
        if (checkbox.checked) {
          topic_id_selected.push(parseInt(item.getAttribute("data-topic-id")));
        }
      })
    }

    function export_csv() {      
      $.ajax({
        type: "POST",
        url: "/download_csv_topics",
        data: { topics_id: topic_id_selected },
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
          location.reload();
        },
        error: function (xhr) {
          console.error("Errore durante il download del CSV", xhr);
        },
      });
    }
  },
});