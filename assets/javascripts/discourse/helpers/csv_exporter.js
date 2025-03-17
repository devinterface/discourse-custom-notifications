import { addBulkDropdownButton } from "discourse/components/bulk-select-topics-dropdown";
// addBulkDropdownButton({
//   id: "button-export-csv",
//   label: "custom.export_topic_csv",
//   icon: "file",
//   class: "btn-default",
//   visible: ({ currentUser }) => true,
//   allowSilent: true,
//   actionType: "performAndRefresh",
//   action: () => {
//     let query = new URLSearchParams(window.location.search).get("q");
//     let topics_id_ajax = [];
//     let topic_id_selected = [];
//     let topic_id_final = [];

//     const tbody = document.querySelector('tbody.topic-list-body');

//     if (tbody) {
//       // sono nella home
//       fetchData_home(1);
//     }
//     else {
//       // sono nella ricerca
//       fetchData_search(1);
//     }

//     // TODO forse non serve chiamata ajax perchè se l'utente scrolla ho già gli elementi nel html

//     function fetchData_home(page) {
//       if (page > 10) {
//         return;
//       }
//       $.ajax({
//         url: `search?q=${encodeURIComponent(query)}&page=${page}`,
//         method: "GET",
//         dataType: "json",
//       }).done(async (data) => {
//         if (!data["posts"] || data["posts"].length === 0) {
//           await get_topics_selected_home();
//           return;
//         }
//         data["posts"].forEach((post) => {
//           if (post.topic_id) {
//             topics_id_ajax.push(post.topic_id);
//           }
//         });
//         fetchData_search(page + 1);
//       });
//     }


//     function fetchData_search(page) {
//       if (page > 10) {
//         return;
//       }
//       $.ajax({
//         url: `search?q=${encodeURIComponent(query)}&page=${page}`,
//         method: "GET",
//         dataType: "json",
//       }).done(async (data) => {
//         if (!data["posts"] || data["posts"].length === 0) {
//           await get_topics_selected_search();
//           return;
//         }
//         data["posts"].forEach((post) => {
//           if (post.topic_id) {
//             topics_id_ajax.push(post.topic_id);
//           }
//         });
//         fetchData_search(page + 1);
//       });
//     }

//     async function get_topics_selected_search() {
//       const listItems = document.querySelectorAll('div[role="listitem"]');
//       listItems.forEach((item) => {
//         const bulkSelectSpan = item.querySelector("span.bulk-select");
//         if (bulkSelectSpan) {
//           const checkbox = bulkSelectSpan.querySelector(
//             'input[type="checkbox"]'
//           );
//           if (checkbox && checkbox.checked) {
//             const topicDiv = item.querySelector("div[data-topic-id]");
//             if (topicDiv) {
//               topic_id_selected.push(
//                 parseInt(topicDiv.getAttribute("data-topic-id"))
//               );
//             }
//           }
//         }
//       });
//       await get_filter();
//     }

//     async function get_topics_selected_home() {
//       const tbody = document.querySelector('tbody.topic-list-body');
//       let rows = tbody.querySelectorAll("tr")
//       rows.forEach((item) => {
//         const bulkSelectSpan = item.querySelector("td.bulk-select");
//         const checkbox = bulkSelectSpan.querySelector(
//           'input[type="checkbox"]'
//         );
//         if (checkbox && checkbox.checked) {
//           topic_id_selected.push(
//               parseInt(item.getAttribute("data-topic-id"))
//             );
//         }
//       })
//       await get_filter();
//     }

//     function get_filter() {
//       topics_id_ajax.filter((element) => {
//         if (topic_id_selected.includes(element)) {
//           topic_id_final.push(element);
//         }
//       });
//       export_csv();
//     }

//     function export_csv() {
//       $.ajax({
//         type: "POST",
//         url: "/download_csv_topics",
//         data: { topics_id: topic_id_final },
//         xhrFields: {
//           responseType: "blob",
//         },
//         success: function (blob, status, xhr) {
//           const disposition = xhr.getResponseHeader("Content-Disposition");
//           const filename = disposition
//             ? disposition.match(/filename="(.+)"/)[1]
//             : "download.csv";
//           const url = window.URL.createObjectURL(blob);
//           const a = document.createElement("a");
//           a.href = url;
//           a.download = filename;
//           document.body.appendChild(a);
//           a.click();
//           window.URL.revokeObjectURL(url);
//           document.body.removeChild(a);
//           location.reload();
//         },
//         error: function (xhr) {
//           console.error("Errore durante il download del CSV", xhr);
//         },
//       });
//     }
//   },
// });

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
    console.log("ENRICO ZAMBELLI");
    

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
      console.log("ELENCO TOPICS");
      
      console.log(topic_id_selected);
      
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