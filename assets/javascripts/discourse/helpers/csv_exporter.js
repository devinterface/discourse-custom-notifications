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
    let query = new URLSearchParams(window.location.search).get("q");
    let topics_id_ajax = [];
    let topic_id_selected = [];
    let topic_id_final = [];

    function fetchData(page) {
      if (page > 10) {
        return;
      }
      $.ajax({
        url: `search?q=${encodeURIComponent(query)}&page=${page}`,
        method: "GET",
        dataType: "json",
      }).done(async (data) => {
        if (!data["posts"] || data["posts"].length === 0) {
          await get_topics_selected();
          return;
        }
        data["posts"].forEach((post) => {
          if (post.topic_id) {
            topics_id_ajax.push(post.topic_id);
          }
        });
        fetchData(page + 1);
      });
    }

    fetchData(1);

    async function get_topics_selected() {
      const listItems = document.querySelectorAll('div[role="listitem"]');
      listItems.forEach((item) => {
        const bulkSelectSpan = item.querySelector("span.bulk-select");
        if (bulkSelectSpan) {
          const checkbox = bulkSelectSpan.querySelector(
            'input[type="checkbox"]'
          );
          if (checkbox && checkbox.checked) {
            const topicDiv = item.querySelector("div[data-topic-id]");
            if (topicDiv) {
              topic_id_selected.push(
                parseInt(topicDiv.getAttribute("data-topic-id"))
              );
            }
          }
        }
      });
      await get_filter();
    }

    function get_filter() {
      topics_id_ajax.filter((element) => {
        if (topic_id_selected.includes(element)) {
          topic_id_final.push(element);
        }
      });
      export_csv();
    }

    function export_csv() {
      $.ajax({
        type: "POST",
        url: "/download_csv_topics",
        data: { topics_id: topic_id_final },
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
